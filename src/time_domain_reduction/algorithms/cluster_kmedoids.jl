@doc raw"""
    cluster_kmedoids(ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from kmedoids
"""

function cluster_kmedoids(ClusteringInputDF::DataFrame, NClusters::Int, nIters::Int, v::Bool=false)

    DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)

    rng = MersenneTwister(42)   # local RNG

    clustering_time = @elapsed begin
        R = kmedoids(DistMatrix, NClusters; rng=rng, init=:kmcen)

        best = nothing
        best_cost = Inf
        no_improve = 0
        patience = 20   # stop if no improvement for 20 restarts

        for i in 1:nIters
            rng_i = MersenneTwister(42 + i)
            R_i = kmedoids(DistMatrix, NClusters; rng=rng_i, init=:kmcen)

            if R_i.totalcost < best_cost - 1e-6   # small tolerance
                best = R_i
                best_cost = R_i.totalcost
                no_improve = 0   # reset counter
            else
                no_improve += 1
            end

            if (i % max(1, nIters ÷ 10) == 0)
                println("Iter $i : cost=$(round(R_i.totalcost, digits=3))  best=$(round(best_cost, digits=3))")
            end

            if no_improve ≥ patience
                println("Stopping early at iteration $i (no improvement for $patience restarts), best=$(round(best_cost, digits=3))")
                break
            end
        end

        R = best
        A = R.assignments
        W = R.counts
        M = R.medoids
    end

    println("K-medoids approach completed successfully.")
    println("A:", A)
    println("W:", W)
    println("M:", M)

    return R, A, W, M, DistMatrix, clustering_time

end