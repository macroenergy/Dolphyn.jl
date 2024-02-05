"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""
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
    
