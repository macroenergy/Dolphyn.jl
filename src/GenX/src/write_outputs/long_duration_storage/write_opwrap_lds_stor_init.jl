function write_opwrap_lds_stor_init(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Extract data frames from input dictionary
	dfGen = inputs["dfGen"]
	G = inputs["G"]

	# Initial level of storage in each modeled period
	NPeriods = size(inputs["Period_Map"])[1]
	dfStorageInit = DataFrame(Resource = inputs["RESOURCES"], Zone = dfGen[!,:Zone])
	socw = zeros(G,NPeriods)
	for i in 1:G
		if i in inputs["STOR_LONG_DURATION"]
			socw[i,:] = value.(EP[:vSOCw])[i,:]
		end
		if i in inputs["STOR_HYDRO_LONG_DURATION"]
			socw[i,:] = value.(EP[:vSOC_HYDROw])[i,:]
		end
	end
	dfStorageInit = hcat(dfStorageInit, DataFrame(socw, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");[Symbol("n$t") for t in 1:NPeriods]]
	rename!(dfStorageInit,auxNew_Names)
	CSV.write(joinpath(path, "StorageInit.csv"), dftranspose(dfStorageInit, false), writeheader=false)


	hours_per_subperiod = inputs["hours_per_subperiod"];
	t_interior = 2:hours_per_subperiod
	T = hours_per_subperiod*NPeriods
	SOC_t = zeros(G, T)
	stor_long_duration = inputs["STOR_LONG_DURATION"]
	stor_hydro_long_duration = inputs["STOR_HYDRO_LONG_DURATION"]
	period_map = inputs["Period_Map"].Rep_Period_Index
	eff_up = dfGen[:, :Eff_Up]
	eff_down = dfGen[:, :Eff_Down]
	self_disch = dfGen[:, :Self_Disch]
	pP_max = inputs["pP_Max"]
	e_total_cap = value.(EP[:eTotalCap])
	v_charge = value.(EP[:vCHARGE])
	v_P = value.(EP[:vP])
	if !isempty(stor_hydro_long_duration)
		v_spill = value.(EP[:vSPILL])
	end
	for r in 1:NPeriods
		w = period_map[r]
		t_r = hours_per_subperiod * (r - 1) + 1
		t_start_w = hours_per_subperiod * (w - 1) + 1
		t_interior = 2:hours_per_subperiod

		if !isempty(stor_long_duration)
			SOC_t[stor_long_duration, t_r] = socw[stor_long_duration, r] .* (1 .- self_disch[stor_long_duration]) .+ eff_up[stor_long_duration] .* v_charge[stor_long_duration, t_start_w] .- 1 ./ eff_down[stor_long_duration] .* v_P[stor_long_duration, t_start_w]

			for t_int in t_interior
				t = hours_per_subperiod * (w - 1) + t_int
				SOC_t[stor_long_duration, t_r + t_int - 1] = SOC_t[stor_long_duration, t_r + t_int - 2] .* (1 .- self_disch[stor_long_duration]) .+ eff_up[stor_long_duration] .* v_charge[stor_long_duration, t] .- 1 ./ eff_down[stor_long_duration] .* v_P[stor_long_duration, t]
			end
		end

		if !isempty(stor_hydro_long_duration)
			SOC_t[stor_hydro_long_duration, t_r] = socw[stor_hydro_long_duration, r] .- 1 ./ eff_down[stor_hydro_long_duration] .* v_P[stor_hydro_long_duration, t_start_w] .- v_spill[stor_hydro_long_duration, t_start_w] .+ pP_max[stor_hydro_long_duration, t_start_w] .* e_total_cap[stor_hydro_long_duration]

			for t_int in t_interior
				t = hours_per_subperiod * (w - 1) + t_int
				SOC_t[stor_hydro_long_duration, t_r + t_int - 1] = SOC_t[stor_hydro_long_duration, t_r + t_int - 2] .- 1 ./ eff_down[stor_hydro_long_duration] .* v_P[stor_hydro_long_duration, t] .- v_spill[stor_hydro_long_duration, t] .+ pP_max[stor_hydro_long_duration, t] .* e_total_cap[stor_hydro_long_duration]
			end
		end
	end
	df_SOC_t = DataFrame(Resource = inputs["RESOURCES"], Zone = dfGen[!,:Zone])
	df_SOC_t = hcat(df_SOC_t, DataFrame(SOC_t, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");[Symbol("t$t") for t in 1:T]]
	rename!(df_SOC_t,auxNew_Names)
	CSV.write(joinpath(path, "StorageEvol.csv"), dftranspose(df_SOC_t, false), writeheader=false)

end
