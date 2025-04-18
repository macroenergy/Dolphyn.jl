@doc raw"""
    cluster_kmedoids(ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from kmedoids
"""

function cluster_kmedoids(ClusteringInputDF::DataFrame, NClusters::Int, nIters::Int, v::Bool=false)

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

    return R, A, W, M, DistMatrix

end