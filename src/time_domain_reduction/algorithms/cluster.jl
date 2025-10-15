@doc raw"""
    cluster(ClusterMethod, ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from various algorithms
"""
function cluster(inpath::String, myTDRsetup::Dict, ClusterMethod::String, ClusteringInputDF::DataFrame, NClusters::Int, nIters::Int, v::Bool=false)

    if v
        println("Shape of ClusteringInputDF: ", size(ClusteringInputDF))  #number of rows number of colummn
    end
    
    if ClusterMethod == "kmeans"
        R, A, W, M, DistMatrix, clustering_time = cluster_kmeans(ClusteringInputDF, NClusters, nIters, true)
        autoencoder_training_time = "NA"
    elseif ClusterMethod == "kmedoids"
        R, A, W, M, DistMatrix, clustering_time = cluster_kmedoids(ClusteringInputDF, NClusters, nIters, v)
        autoencoder_training_time = "NA"
    elseif ClusterMethod == "autoencoder_sequential"
        R, A, W, M, DistMatrix, autoencoder_training_time, clustering_time = cluster_autoencoder_sequential(inpath, myTDRsetup, ClusteringInputDF, NClusters, nIters, true)
    elseif ClusterMethod == "autoencoder_simultaneous"
        R, A, W, M, DistMatrix, autoencoder_training_time, clustering_time = cluster_autoencoder_simultaneous(inpath, myTDRsetup, ClusteringInputDF, NClusters, nIters, true)
    else
        error(" -- ERROR: Clustering method $ClusterMethod is not implemented.")
    end

    # Print details about the returned data
    if v println("\n==== CLUSTERING OUTPUT DETAILS ====")

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
    end
    
    return [R, A, W, M, DistMatrix, autoencoder_training_time, clustering_time]
    
end