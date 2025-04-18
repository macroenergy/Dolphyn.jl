@doc raw"""
    cluster(ClusterMethod, ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from various algorithms
"""
function cluster(ClusterMethod, ClusteringInputDF, NClusters, nIters, v=false)
    function get_batches(data, batch_size)
        N = size(data, 1)
        idxs = randperm(N)
        batches = []
        for i in 1:batch_size:N
            upper = min(i + batch_size - 1, N)
            push!(batches, data[idxs[i:upper], :, :])
        end
        batches
    end
    if ClusterMethod == "kmeans"
        println("Shape of ClusteringInputDF: ", size(ClusteringInputDF))  #number of rows number of colummn
        DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)
        R = kmeans(Matrix(ClusteringInputDF), NClusters, init=:kmcen)

        for i in 1:nIters
            R_i = kmeans(Matrix(ClusteringInputDF), NClusters)

            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if v && (i % (nIters/10) == 0)
                println(string(i) * " : " * string(round(R_i.totalcost, digits=3)) * " " * string(round(R.totalcost, digits=3)) )
            end
        end

        A = R.assignments # get points to clusters mapping - A for Assignments
        W = R.counts # get the cluster sizes - W for Weights
        Centers = R.centers # get the cluster centers - M for Medoids

        M = []
        for i in 1:NClusters
            dists = [euclidean(Centers[:,i], ClusteringInputDF[!, j]) for j in 1:size(ClusteringInputDF, 2)]
            push!(M,argmin(dists))
        end

    elseif ClusterMethod == "kmedoids"
        DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)
        R = kmedoids(DistMatrix, NClusters, init=:kmcen)

        for i in 1:nIters
            R_i = kmedoids(DistMatrix, NClusters)
            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if v && (i % (nIters/10) == 0)
                println(string(i) * " : " * string(round(R_i.totalcost, digits=3)) * " " * string(round(R.totalcost, digits=3)) )
            end
        end

        A = R.assignments # get points to clusters mapping - A for Assignments
        W = R.counts # get the cluster sizes - W for Weights
        M = R.medoids # get the cluster centers - M for Medoids
    
    #Setting uo for Simultaneous and Sequential Approaches 

    elseif ClusterMethod == "sequential"
        # Transpose input data to align with correct time series clustering
        ClusteringInputDF_T = Matrix(ClusteringInputDF)'  # Now shape is (52, 672)

        println("Shape of ClusteringInputDF (before transpose): ", size(ClusteringInputDF))  
        println("Shape of ClusteringInputDF_T (after transpose): ", size(ClusteringInputDF_T))  # (52, 672)

        # Define model hyperparameters
        input_dim = 1
        timesteps = size(ClusteringInputDF_T, 2)  # 672 (time steps)
        n_series = size(ClusteringInputDF_T, 1)  # 52 (time series)
        n_filters = 30
        kernel_size = 5
        stride = 3
        latent_dim = 40
        lambda_param = 0.3
        padding = 1
        epochs = 10
        batch_size = 100

        # Encoder and Decoder definition
        encoder_net = Chain(
            x -> begin
                x_cwn = permutedims(x, (3, 2, 1))  # (1, T, N) = (1, 672, 52)
                y = Conv((kernel_size,), input_dim=>n_filters; stride=(stride,), pad=(padding,))(x_cwn)
                y_ncw = permutedims(y, (3, 2, 1))  # (N, n_filters, new_timesteps) = (52, 30, ?)
                z = leakyrelu.(y_ncw)
                flatten_y = flatten(permutedims(z, (3, 2, 1)))
                println("Shape of flatten_y: ", size(flatten_y))  # Debugging
                return Dense(size(flatten_y, 1), latent_dim)(flatten_y)
            end
        )

        decoder_net = Chain(
            Dense(latent_dim, timesteps * input_dim),
            relu,
            x -> begin
                total_size = length(x)  # Total number of elements in the array
                new_batch_size = total_size ÷ (input_dim * timesteps)
                reshape(x, (new_batch_size, input_dim, timesteps))  # Ensure correct reshaping
            end
        )

        # Autoencoder function
        function autoencoder_seq(x)
            z = encoder_net(x)
            decoder_net(z)
        end

        # Reshape input for the model
        data_array = Float32.(ClusteringInputDF_T)  # (52, 672)
        data_ncw = reshape(data_array, :, 1, size(data_array, 2))  # (N, 1, T), now (52, 1, 672)
        println("Shape of data_ncw: ", size(data_ncw))

        

        # Autoencoder Training setup
        opt = ADAM()
        training_loss = Float32[]
        opt_state = Flux.setup(ADAM(), (encoder_net, decoder_net))

        # Train Autoencoder
        for epoch in 1:epochs
            epoch_loss_acc = 0.0f0
            batches = get_batches(data_ncw, batch_size)
            nbatches = length(batches)

            for batch_data in batches
                println("Shape of batch_data: ", size(batch_data))
                encoded_data = encoder_net(batch_data)
                decoded_data = decoder_net(encoded_data)
                println("Shape of decoded_data: ", size(decoded_data))

                # Compute autoencoder loss (MSE reconstruction loss)
                function loss_fn_seq()
                    mean((batch_data .- decoded_data).^2)
                end

                # Compute gradients and update parameters
                gs = gradient(() -> loss_fn_seq(), params(encoder_net, decoder_net))
                Flux.update!(opt_state, (encoder_net, decoder_net), gs)
                epoch_loss_acc += loss_fn_seq()
            end

            epoch_loss = epoch_loss_acc / nbatches
            push!(training_loss, epoch_loss)
            println("Epoch $epoch/$epochs, Autoencoder Loss: $epoch_loss")
        end

        println("Autoencoder Training Completed.")

        # Encode entire dataset after training
        encoded_data_all = encoder_net(data_ncw)  # (52, 50)

        # Perform KMeans clustering on encoded data
        R = kmeans(Matrix(encoded_data_all), NClusters, init=:kmcen)
        centroids_final = R.centers
        labels_final = R.assignments


        # Find representative medoids
        #M = []
        #ClusteringInputDF_indices = [parse(Int64, string(names(ClusteringInputDF)[i])) for i in 1:size(ClusteringInputDF, 2)]

        #for i in 1:NClusters
            #dists = [euclidean(centroids_final[:, i], encoded_data_all[:, j]) for j in 1:size(encoded_data_all, 2)]
            #closest_idx = argmin(dists)
            #push!(M, ClusteringInputDF_indices[closest_idx])  
        #end

        M = []
        ClusteringInputDF_indices = collect(1:size(ClusteringInputDF, 2))  # [1, 2, ..., 52]

        for i in 1:NClusters
            cluster_idxs = findall(x -> x == i, labels_final)  # indices of weeks in cluster i
            if !isempty(cluster_idxs)
                cluster_points = encoded_data_all[:, cluster_idxs]  # shape: (latent_dim, num_points)
                centroid = centroids_final[:, i]  # shape: (latent_dim,)
                dists = [euclidean(cluster_points[:, j], centroid) for j in 1:length(cluster_idxs)]
                closest_local_idx = argmin(dists)
                closest_global_idx = cluster_idxs[closest_local_idx]
                push!(M, ClusteringInputDF_indices[closest_global_idx])  # guaranteed: M[i] ∈ cluster i
            else
                push!(M, -1)  # fallback if a cluster is empty (shouldn’t happen)
            end
        end
        

        #M = sort(M)

        # Compute outputs
        A = labels_final
        W = [count(==(i), A) for i in 1:NClusters]

        # Correct distance matrix computation
        DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF_T), dims=2)

        println("\n==== RMSE between Original Series and Their Representative Weeks ====")
        all_rmse = Float64[]
        for (i, assigned_rep_idx) in enumerate(A)  # A: assignments (length 52), values in 1..NClusters
            rep_week_idx = M[assigned_rep_idx]  # Actual representative column index in ClusteringInputDF
            original = Float32.(ClusteringInputDF[:, i])
            representative = Float32.(ClusteringInputDF[:, rep_week_idx])
            rmse = rmse_score(original, representative)
            println("Week $i → Rep Week $rep_week_idx | RMSE: $rmse")
            push!(all_rmse, rmse)
        end
        
        println("\n==== Average RMSE across all weeks: ", mean(all_rmse))

    elseif ClusterMethod == "simultaneous"
        # Transpose input data to align with correct time series clustering
        ClusteringInputDF_T = Matrix(ClusteringInputDF)'  # Now shape is (52, 672)
    
        println("Shape of ClusteringInputDF (before transpose): ", size(ClusteringInputDF))  
        println("Shape of ClusteringInputDF_T (after transpose): ", size(ClusteringInputDF_T))  # (52, 672)
    
        # Define model hyperparameters
        input_dim = 1
        timesteps = size(ClusteringInputDF_T, 2)  # 672 (time steps)
        n_series = size(ClusteringInputDF_T, 1)  # 52 (time series)
        n_filters = 30
        kernel_size = 5
        stride = 3
        latent_dim = 60
        lambda_param = 0.1
        padding = 1
        epochs = 35
        batch_size = 100
    
        # Reshape input for the model
        data_array = Float32.(ClusteringInputDF_T)  # (52, 672)
        data_ncw = reshape(data_array, :, 1, size(data_array, 2))  # (N, 1, T), now (52, 1, 672)

        # Encoder and Decoder definition
        encoder_net = Chain(
            x -> begin
                x_cwn = permutedims(x, (3, 2, 1))  # (1, T, N) = (1, 672, 52)
                y = Conv((kernel_size,), input_dim=>n_filters; stride=(stride,), pad=(padding,))(x_cwn)
                y_ncw = permutedims(y, (3, 2, 1))  # (N, n_filters, new_timesteps) = (52, 30, ?)
                z = leakyrelu.(y_ncw)
                flatten_y = flatten(permutedims(z, (3, 2, 1)))
                println("Shape of flatten_y: ", size(flatten_y))  # Debugging
                return Dense(size(flatten_y, 1), latent_dim)(flatten_y)
            end
        )
    
        decoder_net = Chain(
            Dense(latent_dim, timesteps * input_dim),
            relu,
            x -> begin
                total_size = length(x)  # Total number of elements in the array
                new_batch_size = total_size ÷ (input_dim * timesteps)
                reshape(x, (new_batch_size, input_dim, timesteps))  # Ensure correct reshaping
            end
        )
    
        # Autoencoder function
        function autoencoder_sim(x)
            z = encoder_net(x)
            decoder_net(z)
        end
    
        # Combined Loss Function
        function combined_loss(y_true, y_pred, encoded_data, labels, centroids, λ=0.1)
            reconstruction_loss = mean((y_true .- y_pred).^2)
            clustering_loss = mean(sum((encoded_data .- centroids[labels, :]) .^ 2, dims=2))
            return (1 - λ) * reconstruction_loss + λ * clustering_loss
        end
        
    
        # Function to perform KMeans clustering
        function run_kmeans(encoded_data, k)
            R = kmeans(Matrix(encoded_data), k; maxiter=100, display=:final)
            centroids = R.centers
            labels = R.assignments
            return centroids, labels
        end
    
        # Training setup
        opt = ADAM()
        training_loss = Float32[]
        opt_state = Flux.setup(ADAM(), (encoder_net, decoder_net))
    
        # Training loop
        for epoch in 1:epochs
            epoch_loss_acc = 0.0f0
            batches = get_batches(data_ncw, batch_size)
            nbatches = length(batches)
            for batch_data in batches
                println("Shape of batch_data BEFORE KMeans: ", size(batch_data))
                encoded_data = encoder_net(batch_data)  # (N, 50)
                decoded_data = decoder_net(encoded_data)
                println("Shape of decoded_data BEFORE KMeans: ", size(decoded_data))
                println("Shape of encoded_data BEFORE KMeans: ", size(encoded_data))
                # KMeans clustering on encoded data
                centroids, labels = run_kmeans(encoded_data, NClusters)
                encoded_data = encoded_data'
                centroids = centroids'
                println("Shape of centroids AFTER KMeans: ", size(centroids))
                labels = Int.(labels)
                # Compute combined loss
                function loss_fn_sim()
                    combined_loss(batch_data, decoded_data, encoded_data, labels, centroids, lambda_param)
                end
                # Compute gradients and update parameters
                gs = gradient(() -> loss_fn_sim(), params(encoder_net, decoder_net))
                Flux.update!(opt_state, (encoder_net, decoder_net), gs)
                epoch_loss_acc += loss_fn_sim()
            end

            epoch_loss = epoch_loss_acc / nbatches
            push!(training_loss, epoch_loss)
            println("Epoch $epoch/$epochs, Combined Loss: $epoch_loss")
        end
    
        # Run clustering on full dataset
        encoded_data_all = encoder_net(data_ncw)  # (52, 50)
        centroids_final, labels_final = run_kmeans(encoded_data_all, NClusters)
    
        # Generate reduced dataset
        function get_reduced_df(data, encoder_net, k)
            encoded_data = encoder_net(data)  # (52, 50)
            centroids, labels = run_kmeans(encoded_data, k)
            labels = Int.(round.(labels))
            reduced_vectors = Array{Float32}(undef, k, 1, timesteps)
    
            for c in 1:k
                cluster_idxs = findall(x -> x == c, labels)
                if length(cluster_idxs) > 0
                    cluster_data = data[cluster_idxs, :, :]  # (count, 1, 672)
                    centroid = mean(cluster_data, dims=1)  # (1,1,672)
                    dists = [sum((cluster_data[i, :, :] .- centroid).^2) for i in 1:length(cluster_idxs)]
                    closest_idx = argmin(dists)
                    reduced_vectors[c, :, :] = cluster_data[closest_idx, :, :]
                else
                    reduced_vectors[c, :, :] = zeros(Float32, 1, timesteps)
                end
            end
            reduced_vectors
        end
    
        reduced_df = get_reduced_df(data_ncw, encoder_net, NClusters)
        println("Shape of reduced_df: ", size(reduced_df))
    
        # Find representative medoids
        #M = []
        #ClusteringInputDF_indices = [parse(Int64, string(names(ClusteringInputDF)[i])) for i in 1:size(ClusteringInputDF, 2)]
    
        #for i in 1:NClusters
            #dists = [euclidean(centroids_final[:, i], encoded_data_all[:, j]) for j in 1:size(encoded_data_all, 2)]
            #closest_idx = argmin(dists)
            #push!(M, ClusteringInputDF_indices[closest_idx])  
        #end
        M = []
        ClusteringInputDF_indices = collect(1:size(ClusteringInputDF, 2))  # [1, 2, ..., 52]

        for i in 1:NClusters
            cluster_idxs = findall(x -> x == i, labels_final)  # indices of weeks in cluster i
            if !isempty(cluster_idxs)
                cluster_points = encoded_data_all[:, cluster_idxs]  # shape: (latent_dim, num_points)
                centroid = centroids_final[:, i]  # shape: (latent_dim,)
                dists = [euclidean(cluster_points[:, j], centroid) for j in 1:length(cluster_idxs)]
                closest_local_idx = argmin(dists)
                closest_global_idx = cluster_idxs[closest_local_idx]
                push!(M, ClusteringInputDF_indices[closest_global_idx])  # guaranteed: M[i] ∈ cluster i
            else
                push!(M, -1)  # fallback if a cluster is empty (shouldn’t happen)
            end
        end
    
        # Compute outputs
        R = kmeans(Matrix(encoded_data_all), NClusters, init=:kmcen)
        A = labels_final
        W = [count(==(i), A) for i in 1:NClusters]
    
        # Correct distance matrix computation
        DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF_T), dims=2)
        println("Type of M: ", typeof(M))
        println("Shape of M: ", size(M))

        println("Simultaneous approach completed successfully.")
        println("\n==== RMSE between Original Series and Their Representative Weeks ====")
        all_rmse = Float64[]
        for (i, assigned_rep_idx) in enumerate(A)  # A: assignments (length 52), values in 1..NClusters
            rep_week_idx = M[assigned_rep_idx]  # Actual representative column index in ClusteringInputDF
            original = Float32.(ClusteringInputDF[:, i])
            representative = Float32.(ClusteringInputDF[:, rep_week_idx])
            rmse = rmse_score(original, representative)
            println("Week $i → Rep Week $rep_week_idx | RMSE: $rmse")
            push!(all_rmse, rmse)
        end
        
        println("\n==== Average RMSE across all weeks: ", mean(all_rmse))

    else
        println(" -- INVALID ClusterMethod. Select kmeans or kmedoids. Running kmeans instead.")
        return cluster("kmeans", ClusteringInputDF, NClusters, nIters)
    end
    # Print details about the returned data
    println("\n==== CLUSTERING OUTPUT DETAILS ====")

    println("\n** M (Cluster Centers or Medoids) **")
    println("Shape: (", length(M), ")")
    println("Type: ", typeof(M))
    println("Values: ", M)

    println("\n** R (Clustering Model) **")
    println("Type: ", typeof(R))
    println("R Centers Shape: ", size(R.centers))  # (n_features, NClusters)
    println("R Assignments Shape: ", size(R.assignments))  # (n_samples,)
    println("R Counts Shape: ", size(R.counts))  # (NClusters,)
    println("R Total Cost: ", R.totalcost)  # Scalar value

    println("\n** A (Assignments) **")
    println("Shape: (", length(A), ")")
    println("Type: ", typeof(A))
    println("Values: ", A)

    println("\n** W (Cluster Sizes) **")
    println("Shape: (", length(W), ")")
    println("Type: ", typeof(W))
    println("Values: ", W)


    println("\n** DistMatrix (Distance Matrix) **")
    println("Shape: (", size(DistMatrix), ")")
    println("Type: ", typeof(DistMatrix))
    println("First 5 rows:\n", DistMatrix[1:min(5, size(DistMatrix, 1)), :])
    return [R, A, W, M, DistMatrix]
end