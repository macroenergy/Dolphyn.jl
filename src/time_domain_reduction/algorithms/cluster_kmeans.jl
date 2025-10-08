@doc raw"""
    cluster_kmeans(ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from kmeans
"""
    
function cluster_kmeans(ClusteringInputDF::DataFrame, NClusters::Int, nIters::Int, v::Bool=false)

    DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)

    rng = MersenneTwister(42)   # local RNG

    clustering_time = @elapsed begin
        R = kmeans(Matrix(ClusteringInputDF), NClusters; rng=rng, init=:kmpp)

        best = nothing
        best_cost = Inf
        no_improve = 0
        patience = 50   # stop if no improvement for 20 restarts

        for i in 1:nIters
            rng_i = MersenneTwister(42 + i)
            R_i = kmeans(Matrix(ClusteringInputDF), NClusters; rng=rng_i, init=:kmpp)
        
            if R_i.totalcost < best_cost - 1e-6   # small tolerance
                best = R_i
                best_cost = R_i.totalcost
                no_improve = 0   # reset counter
            else
                no_improve += 1
            end
        
            if v && (i % max(1, nIters ÷ 10) == 0)
                println("Iter $i : cost=$(round(R_i.totalcost, digits=3))  best=$(round(best_cost, digits=3))")
            end
        
            if v && no_improve ≥ patience
                println("Stopping early at iteration $i (no improvement for $patience restarts), best=$(round(best_cost, digits=3))")
                break
            end
        end
        
        R = best
        A = R.assignments
        W = R.counts
        Centers = R.centers

        M = Int[]
        chosen = Set{Int}()
        
        for i in 1:NClusters
            # sort candidates by distance to centroid i
            dists = [euclidean(Centers[:, i], ClusteringInputDF[!, j]) for j in 1:size(ClusteringInputDF, 2)]
            candidates = sortperm(dists)  # indices ordered from closest to farthest
        
            # pick first candidate not already chosen
            rep = findfirst(idx -> !(idx in chosen), candidates)
            if rep === nothing
                error("Could not find a unique representative for cluster $i")
            end
        
            push!(M, candidates[rep])
            push!(chosen, candidates[rep])
        end
    end

    if v
        println("Kmeans approach completed successfully.")
        println("A:", A)
        println("W:", W)
        println("M:", M)
    end

    return R, A, W, M, DistMatrix, clustering_time
end