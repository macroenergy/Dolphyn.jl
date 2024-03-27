
#=
This file creates the macro benchmarked for benchmarking function generate_model and get the return value to be used by the codes that follows.
=#

using BenchmarkTools
using DataFrames

macro benchmarked(args...)
    _, params = BenchmarkTools.prunekwargs(args...)
    bench, trial, result = gensym(), gensym(), gensym()
    trialmin, trialallocs = gensym(), gensym()
    tune_phase = BenchmarkTools.hasevals(params) ? :() : :($BenchmarkTools.tune!($bench))
    return esc(
        quote
            local $bench = $BenchmarkTools.@benchmarkable $(args...)
            $BenchmarkTools.warmup($bench)
            $tune_phase
            local $trial, $result = $BenchmarkTools.run_result($bench)
            local $trialmin = $BenchmarkTools.minimum($trial)
            
            display($trial)

            $result, $trial
        end,
    )
end

function generate_benchmark_csv(path::String, bm_results::BenchmarkTools.Trial)
    bm_df = DataFrame(
	time_ms = bm_results.times ./ 1e6,
	gctime_ms = bm_results.gctimes ./ 1e6,
	bm_nt_ms = (bm_results.times - bm_results.gctimes) ./ 1e6,
	memory_mb = bm_results.memory ./ 1e6,
	allocs = bm_results.allocs
    )
    CSV.write(joinpath(path, "generate_model_benchmark_results.csv"), bm_df)
end

function get_bm_string(bm::BenchmarkTools.Trial)
    io = IOBuffer()
    show(io, "text/plain", bm)
    s = String(take!(io))
    
    return s
end
    
