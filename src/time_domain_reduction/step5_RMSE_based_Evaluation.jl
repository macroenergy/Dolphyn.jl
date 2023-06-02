#include("helper_files.jl")
function step5_RMSE_based_Evaluation(InputData, NumDataPoints, A, rpDFs, OldColNames)
    InputDataTest = InputData[(InputData.Group .<= NumDataPoints*1.0), :]
    ClusterDataTest = vcat([rpDFs[a] for a in A]...) # To compare fairly, load is not scaled here
    RMSE = Dict( c => rmse_score(InputDataTest[:, c], ClusterDataTest[:, c])  for c in OldColNames)
    return RMSE
end
