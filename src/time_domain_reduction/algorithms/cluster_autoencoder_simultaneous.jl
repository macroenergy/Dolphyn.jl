@doc raw"""
    cluster_autoencoder_simultaneous(ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from k means on autoencoder latent space
"""
function cluster_autoencoder_simultaneous(inpath::String, myTDRsetup::Dict, ClusteringInputDF::DataFrame, NClusters::Int, nIters::Int, v::Bool=false)

    #Train autoencoder to minimize reconstruction error of ClusteringInputDF + clustering error on latent space
    #Perform k-means on latent space of trained autoencoder to obtain representative subperiods indexes

    
    # Load autoencoder hyperparameters from settings
    scaling_method = myTDRsetup["ScalingMethod"]
    AE_params = myTDRsetup["AutoEncoder"]
    kernel_size = AE_params["kernel_size"]
    stride = AE_params["stride"]
    epochs = AE_params["epochs"]
    min_err_diff = AE_params["min_err_diff"] 
    patience = AE_params["patience"]
    warmup = AE_params["warmup"]

    n_filters = AE_params["n_filters"]
    latent_dim = AE_params["latent_dim"]

    lambda = AE_params["lambda"]

    # Load input DF of shape: (T * n resources, NWeeks)
    InputDF = Float32.(Matrix(ClusteringInputDF))                 # (T * n, NWeeks)

    #Check if autoencoder latent space is already present as dataframe as folder
    latent_file = joinpath(inpath, "TDR_Simultaneous_Autoencoder_Latent_Space_Lambda$(lambda)_W$(NClusters)_N$(n_filters)_D$(latent_dim).csv")

    if isfile(latent_file) && get(myTDRsetup, "ForceAutoencoderTraining", 0) != 1
        # Load latent space if available and skip training step
        println("Found latent space for W=$(NClusters), N=$(n_filters), D=$(latent_dim) — skipping autoencoder training.")
        z_df = CSV.read(latent_file, DataFrame)
        z = Matrix(z_df) |> x -> Float32.(x)

        println("Size of z: ", size(z))
        autoencoder_training_time = "Using Existing Autoencoder Latent Space"

    else
        # Train autoencoder if latent space is unavailable
        #Set decoder activation function based on how input dataframe is scaled
        decoder_activation = if scaling_method == "N"
            sigmoid
        elseif scaling_method == "S"
            identity
        else
            error("Unsupported ScalingMethod. Use 'N' for normalization or 'S' for standardization.")
        end

        ################## Part 1 -- Prepare input dataframe for encoder input ##################

        #Define values used for reshaping into 3D tensor
        timesteps = Int(myTDRsetup["TimestepsPerRepPeriod"])          # T
        Nweeks = size(InputDF, 2)                                     # NWeeks
        n = size(InputDF,1) ÷ timesteps                               # n resources, which corresponds to the channels C in AE
        input_dim = n

        

        # Reshape rows into tensor (T, C, NWeeks)
        #T = TimestepsPerRepPeriod, C = Channels (same as number of resources n), NWeeks = Weeks
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
        println("input_dim:", input_dim, ", lambda", lambda, ", n_filters:", n_filters, ", kernel_size:", kernel_size, ", stride:", stride, ", latent_dim:", latent_dim, ", epochs:", epochs)


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

        loss_log_file = joinpath(inpath, "TDR_Autoencoder_Loss_Curves_Lambda$(lambda)_W$(NClusters)_N$(n_filters)_D$(latent_dim).csv")

        # initialize CSV file if not present
        if !isfile(loss_log_file)
            df_init = DataFrame(Epoch=Int[], Recon=Float64[], Cluster=Float64[], Combined=Float64[])
            CSV.write(loss_log_file, df_init)
        end

        autoencoder_training_time = @elapsed begin

            for epoch in 1:epochs
                # --- latent codes (raw and normalized) ---
                z_raw = encoder_net(encoder_input)  # (latent_dim, Nweeks)
                z_epoch = (z_raw .- mean(z_raw; dims=2)) ./ (std(z_raw; dims=2) .+ 1f-8)

                # --- run KMeans on normalized latent space each epoch ---
                R, A, W, M, _, _ = cluster_kmeans(DataFrame(z_epoch, :auto), NClusters, nIters, false)

                # --- rebuild representative series in input space ---
                rep_profiles = InputDF[:, M]  # columns of representative weeks
                reconstructed_series = hcat([rep_profiles[:, A[j]] for j in 1:length(A)]...)
                
                # --- forward + grads with combined loss ---
                recon_loss = 0.0f0
                cluster_loss = 0.0f0
                combined = 0.0f0
                
                # --- forward + grads ---
                loss, grads = Flux.withgradient(autoencoder) do m
                    decoded = m(encoder_input)
                    # AE reconstruction loss
                    recon_loss = mean((decoded .- InputDF).^2)
                    # Rep-week approximation loss (RMSE in input space)
                    cluster_loss = mean((InputDF .- reconstructed_series).^2)
                    # Combined loss
                    combined = recon_loss + lambda * cluster_loss
                    combined
                end
                        
                Flux.update!(opt_state, autoencoder, grads[1])
                push!(losses, loss)

                # logging + CSV output
                if epoch % 200 == 0
                    println("Epoch $epoch/$epochs, Recon: $(round(recon_loss, digits=6)), ","Cluster: $(round(cluster_loss, digits=6)), ","Combined: $(round(loss, digits=6))")

                    df_log = DataFrame(Epoch=[epoch],
                                    Recon=[Float64(recon_loss)],
                                    Cluster=[Float64(cluster_loss)],
                                    Combined=[Float64(loss)])
                    open(loss_log_file, "a") do io
                        CSV.write(io, df_log; append=true, header=false)
                    end
                end

                # improvement check vs best_loss (relative)
                eps = 1f-12
                required = max(min_err_diff * (best_loss < Inf32 ? best_loss : loss), eps)

                if loss < best_loss - required
                    best_loss  = loss
                    best_epoch = epoch
                    wait = 0
                    best_encoder = deepcopy(encoder_net)
                    best_decoder = deepcopy(decoder_net)
                elseif epoch > warmup
                    wait += 1
                    if wait >= patience
                        println("Early stopping at epoch $epoch. Best epoch=$best_epoch, best loss=$best_loss.")
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
        println("Reconstruction RMSE: ", loss_mean)
        

        ################## Export stats ##################
        stats_file = joinpath(inpath, "TDR_Autoencoder_Training_Stats.csv")
        df_stats = DataFrame(
            N_Filters = [n_filters],
            Laten_Dim = [latent_dim],
            Kernel_Size = [kernel_size],
            Stride = [stride],
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

    end

    ################## Part 6 -- Kmeans clustering on latent space ##################
    println("Performing kmeans clustering on latent space")

    R, A, W, M, DistMatrix, clustering_time =
    cluster_kmeans(DataFrame(z, :auto), NClusters, nIters, v)

    rep_profiles = InputDF[:, M]  # columns of representative weeks
    reconstructed_series = hcat([rep_profiles[:, A[j]] for j in 1:length(A)]...)

    println("Simultaneous autoencoder approach completed successfully.")

    return R, A, W, M, DistMatrix, autoencoder_training_time, clustering_time
end
