@doc raw"""
    cluster_autoencoder(ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from k means on autoencoder latent space
"""
function cluster_autoencoder(inpath::String, myTDRsetup::Dict, ClusteringInputDF::DataFrame, NClusters::Int, nIters::Int, v::Bool=false)

    #Compress multi-resource weekly time series with a 1D-convolutional autoencoder (AE), 
    #then cluster the latent representations with k-means to pick representative weeks.

    #Check if autoencoder latent space is already present as dataframe as folder
    latent_file = joinpath(inpath, "TDR_Autoencoder_Latent_Space.csv")

    if isfile(latent_file)
        # Load latent space if available and skip training step
        println("Found latent space, skipping autoencoder training.")
        z_df = CSV.read(latent_file, DataFrame)
        z = Matrix(z_df) |> x -> Float32.(x)

        println("Size of z: ", size(z))
        autoencoder_training_time = "Using Existing Autoencoder Latent Space"

    else
        # Train autoencoder if latent space is unavailable
        # Load autoencoder hyperparameters from settings
        scaling_method = myTDRsetup["ScalingMethod"]
        AE_params = myTDRsetup["AutoEncoder"]

        n_filters = AE_params["n_filters"]
        kernel_size = AE_params["kernel_size"]
        stride = AE_params["stride"]
        latent_dim = AE_params["latent_dim"]
        epochs = AE_params["epochs"]
        min_err_diff = AE_params["min_err_diff"] 
        patience = AE_params["patience"]
        warmup = AE_params["warmup"]

        #Set decoder activation function based on how input dataframe is scaled
        decoder_activation = if scaling_method == "N"
            sigmoid
        elseif scaling_method == "S"
            identity
        else
            error("Unsupported ScalingMethod. Use 'N' for normalization or 'S' for standardization.")
        end

        ################## Part 1 -- Prepare input dataframe for encoder input ##################
        # Load input DF of shape: (T * n resources, NWeeks)
        InputDF = Float32.(Matrix(ClusteringInputDF))                 # (T * n, NWeeks)

        #Define values used for reshaping into 3D tensor
        timesteps = Int(myTDRsetup["TimestepsPerRepPeriod"])    # T
        Nweeks = size(InputDF, 2)                                     # NWeeks
        n = size(InputDF,1) ÷ timesteps                               # n resources, which corresponds to the channels C in AE
        input_dim = n

        # Reshape rows into tensor (T, C, NWeeks)
        #T = TimestepsPerRepPeriod, C = Channels (same as number of resources n), NWeeks = Weeks

        #Did not include this step in encoder because (not yet implemented) users can choose to use 
        #one single channel for entire df instead of having each resource to one channel

        encoder_input = reshape(InputDF, timesteps, n, Nweeks)       # (T, C, NWeeks)
        println("Autoencoder Input (T, C, NWeeks) = ", size(encoder_input))


        ################## Part 2 -- Define Autoencoder ##################
        # Define seed
        Random.seed!(42)

        enc_head = Chain(
        Conv((kernel_size,), input_dim => n_filters; 
            stride=stride, pad=SamePad()),                     # (T_out, n_filters, NWeeks)
        x -> permutedims(x, (3,2,1)),                          # (NWeeks, n_filters, T_out)
        leakyrelu
        )

        # Discover T_out and flattened size by a real forward pass
        tmp = enc_head(encoder_input)                                          # (NWeeks, n_filters, T_out)
        @assert size(tmp,3) > 0 "Conv T_out ≤ 0; adjust kernel/stride/pad."
        T_out = size(tmp, 3)
        flattened_dim  = size(tmp, 2) * T_out
        println("T_out = ", T_out)
        println("Flattened dimension = ", flattened_dim) 

        # Define encoder and decoder as separate chains
        encoder_net = Chain(
            enc_head,                                                       # (NWeeks, n_filters, T_out)
            x -> reshape(x, size(x, 1), :),                                 # (NWeeks, flattened_dim)
            x -> x',                                                        # (flattened_dim, NWeeks)
            Dense(flattened_dim, latent_dim)                                # (latent, NWeeks)
        )
        
        decoder_net = Chain(
            Dense(latent_dim, input_dim * timesteps),                       # (C*T, NWeeks)
            decoder_activation
        )

        # Combine encoder and decoder into a single autoencoder model
        autoencoder = Chain(encoder_net, decoder_net)

        println("Autoencoder parameters:")
        println("input_dim:", input_dim, ", n_filters:", n_filters, ", kernel_size:", kernel_size, ", stride:", stride, ", latent_dim:", latent_dim, ", epochs:", epochs)


        ################## Part 3 -- Autoencoder Training ##################
        # Set up the optimizer for the unified model
        opt = ADAM()
        opt_state = Flux.setup(opt, autoencoder)

        losses = Float32[]
        best_loss   = Inf32
        best_epoch  = 0
        wait        = 0

        # keep best weights
        best_encoder = deepcopy(encoder_net)
        best_decoder = deepcopy(decoder_net)

        println("\nStarting Autoencoder Training...")

        autoencoder_training_time = @elapsed begin

            for epoch in 1:epochs
                # forward + grads
                loss, grads = Flux.withgradient(autoencoder) do m
                    decoder_output = m(encoder_input)
                    mean((decoder_output .- InputDF).^2)
                end
                Flux.update!(opt_state, autoencoder, grads[1])
                push!(losses, loss)

                #Output for debugging purposes
                #if epoch % 20 == 0
                #    decoded_epoch = autoencoder(encoder_input)                 # (C*T, Nweeks)
                #    decoded_df    = DataFrame(decoded_epoch, :auto)
                #    outpath = "DecodedOutput_Epoch_$(lpad(epoch, 4, '0')).csv"
                #    CSV.write(outpath, decoded_df)
                #    if v
                #        println("Saved reconstruction snapshot: ", outpath)
                #    end
                #end

                # logging
                if v || epoch % 20 == 0
                    println("Epoch $epoch/$epochs, Loss: $loss")
                end

                # improvement check vs best_loss (relative)
                # epsilon keeps criterion sensible when best_loss is tiny
                eps = 1f-12
                required = max(min_err_diff * (best_loss < Inf32 ? best_loss : loss), eps)

                if loss < best_loss - required
                    best_loss  = loss
                    best_epoch = epoch
                    wait = 0
                    # snapshot best weights
                    best_encoder = deepcopy(encoder_net)
                    best_decoder = deepcopy(decoder_net)
                elseif epoch > warmup
                    wait += 1
                    if wait >= patience
                        println("Early stopping at epoch $epoch. Best epoch=$best_epoch, best loss=$best_loss.")
                        # restore best weights
                        encoder_net = best_encoder
                        decoder_net = best_decoder
                        autoencoder = Chain(encoder_net, decoder_net)
                        break
                    end
                end
            end
        end

        println("Autoencoder Training Completed.")


        ################## Part 4 -- Obtain autoencoder latent space ##################
        # To perform K Means clustering on encoded data
        encoded_data_all = encoder_net(encoder_input)                   # (latent, N)
        z = (encoded_data_all .- mean(encoded_data_all; dims=2)) ./ (std(encoded_data_all; dims=2) .+ 1f-8)

        println("Size of z: ", size(z))

        # Save latent space to input path
        z_df = DataFrame(z, :auto)
        CSV.write(latent_file, z_df)
        println("Saved latent space to $latent_file")

        ################## Part 5 -- Output autoencoder results to desktop for debugging ##################
        # Encode and decode the entire dataset
        decoded_all = decoder_net(encoded_data_all)
        println("Autoencoder Output (T x C, Nweeks) = ", size(decoded_all)) 
        
        loss_mean = mean((decoded_all .- InputDF).^2)
        println("Mean loss: ", loss_mean)
        

        ################## Export stats ##################
        stats_file = joinpath(inpath, "TDR_Autoencoder_Training_Stats.csv")
        df_stats = DataFrame(
            Autoencoder_Training_Time = [autoencoder_training_time],
            Best_Epoch = [best_epoch],
            Best_Loss = [best_loss],
        )

        if isfile(stats_file)
            old = CSV.read(stats_file, DataFrame)
            df_stats = vcat(old, df_stats; cols=:union)
        end
        CSV.write(stats_file, df_stats)
        println("Autoencoder stats written to: $stats_file")


        ################## Export autoencoder results (For debugging) ##################
        # Encode and decode the entire dataset
        #decoded_all = decoder_net(encoded_data_all)  # (C*T, Nweeks)
        #println("Autoencoder Output (T*C, Nweeks) = ", size(decoded_all)) 

        # Export input dataframe
        #input_df = DataFrame(InputDF, :auto)
        #input_file = joinpath(inpath, "TDR_Autoencoder_Input.csv")
        #CSV.write(input_file, input_df)
        #println("Autoencoder input dataframe written to: ", input_file)

        # Export decoded output
        #decoded_df = DataFrame(decoded_all, :auto)
        #decoded_file = joinpath(inpath, "TDR_Autoencoder_Decoded_Output.csv")
        #CSV.write(decoded_file, decoded_df)
        #println("Autoencoder decoded output dataframe written to: ", decoded_file)

    end

    ################## Part 6 -- Kmeans clustering on latent space ##################
    println("Performing kmeans clustering on latent space")

    DistMatrix = pairwise(Euclidean(), Matrix(z), dims=2)

    clustering_time = @elapsed begin

        # Define seed
        Random.seed!(42)
        R = kmeans(Matrix(z), NClusters, init=:kmpp, maxiter=300)

        # Multi-start strategy: repeat clustering nIters times and keep best
        for i in 1:nIters
            R_i = kmeans(Matrix(z), NClusters; init=:kmpp, maxiter=300)

            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if (i % max(1, nIters ÷ 10) == 0)
                println(string(i) * " : " * string(round(R_i.totalcost, digits=3)) * " " * string(round(R.totalcost, digits=3)) )
            end
        end

        A = R.assignments # get points to clusters mapping - A for Assignments
        W = R.counts # get the cluster sizes - W for Weights
        Centers = R.centers # get the cluster centers - M for Medoids

        M = []
        for i in 1:NClusters
            dists = [euclidean(Centers[:, i], z[:, j]) for j in 1:size(z, 2)]
            push!(M, argmin(dists))
        end
    end

    println("Autoencoder approach completed successfully.")
    println("A:", A)
    println("W:", W)
    println("M:", M)

    return R, A, W, M, DistMatrix, autoencoder_training_time, clustering_time
end
