@doc raw"""
    cluster_kmeans(ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from kmeans
"""
    
function cluster_kmeans(ClusteringInputDF::DataFrame, NClusters::Int, nIters::Int, v::Bool=false)

    DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)

    clustering_time = @elapsed begin

        # Define seed
        Random.seed!(42)
        R = kmeans(Matrix(ClusteringInputDF), NClusters, init=:kmpp, maxiter=300)

        for i in 1:nIters
            R_i = kmeans(Matrix(ClusteringInputDF), NClusters, init=:kmpp, maxiter=300)

            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if (i % (nIters/10) == 0)
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
    end

    println("Kmeans approach completed successfully.")
    println("A:", A)
    println("W:", W)
    println("M:", M)

    return R, A, W, M, DistMatrix, clustering_time
end