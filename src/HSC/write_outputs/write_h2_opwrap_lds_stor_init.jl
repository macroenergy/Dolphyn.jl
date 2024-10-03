function write_h2_opwrap_lds_stor_init(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Extract data frames from input dictionary
	dfH2Gen = inputs["dfH2Gen"]
	H = inputs["H2_RES_ALL"]

	# Initial level of storage in each modeled period
	NPeriods = size(inputs["Period_Map"])[1]
	dfStorageInit = DataFrame(Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone])
	socw = zeros(H,NPeriods)
	for i in 1:H
		if i in inputs["H2_STOR_LONG_DURATION"]
			socw[i,:] = value.(EP[:vH2SOCw])[i,:]
		end
	end
	dfStorageInit = hcat(dfStorageInit, DataFrame(socw, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");[Symbol("n$t") for t in 1:NPeriods]]
	rename!(dfStorageInit,auxNew_Names)
	CSV.write(string(path,sep,"HSC_StorageInit.csv"), dftranspose(dfStorageInit, false), writeheader=false)


	hours_per_subperiod = inputs["hours_per_subperiod"];
	t_interior = 2:hours_per_subperiod
	T = hours_per_subperiod*NPeriods
	SOC_t = zeros(H, T)	
	h2_stor_long_duration = inputs["H2_STOR_LONG_DURATION"]
	period_map = inputs["Period_Map"].Rep_Period_Index
	self_discharge_rate = dfH2Gen[:, :H2Stor_self_discharge_rate_p_hour]
	eff_charge = dfH2Gen[:, :H2Stor_eff_charge]
	eff_discharge = dfH2Gen[:, :H2Stor_eff_discharge]
	vH2_charge_stor = value.(EP[:vH2_CHARGE_STOR])
	vH2Gen = value.(EP[:vH2Gen])	
	for r in 1:NPeriods
		w = period_map[r]
		t_r = hours_per_subperiod * (r - 1) + 1
		t_start_w = hours_per_subperiod * (w - 1) + 1
		t_interior = 2:hours_per_subperiod
		if !isempty(h2_stor_long_duration)
			SOC_t[h2_stor_long_duration, t_r] = socw[h2_stor_long_duration, r] .* (1 .- self_discharge_rate[h2_stor_long_duration]) .+ eff_charge[h2_stor_long_duration] .* vH2_charge_stor[h2_stor_long_duration, t_start_w] .- 1 ./ eff_discharge[h2_stor_long_duration] .* vH2Gen[h2_stor_long_duration, t_start_w]	
			for t_int in t_interior
				t = hours_per_subperiod * (w - 1) + t_int
				SOC_t[h2_stor_long_duration, t_r + t_int - 1] = SOC_t[h2_stor_long_duration, t_r + t_int - 2] .* (1 .- self_discharge_rate[h2_stor_long_duration]) .+ eff_charge[h2_stor_long_duration] .* vH2_charge_stor[h2_stor_long_duration, t] .- 1 ./ eff_discharge[h2_stor_long_duration] .* vH2Gen[h2_stor_long_duration, t]
			end
		end
	end
	df_SOC_t = DataFrame(Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone])
	df_SOC_t = hcat(df_SOC_t, DataFrame(SOC_t, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");[Symbol("t$t") for t in 1:T]]
	rename!(df_SOC_t,auxNew_Names)
	CSV.write(string(path,sep,"HSC_StorageEvol.csv"), dftranspose(df_SOC_t, false), writeheader=false)

end
