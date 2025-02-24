

@doc raw"""
	load_co2_capture_DAC_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capturevar::Dict)

Function for reading input parameters related to hourly maximum capacity factors for all DAC resources.
"""
function load_co2_capture_DAC_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capturevar::Dict)

	# Hourly capacity factors
	#data_directory = data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
	data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1 && isfile(joinpath(data_directory,"CSC_capture_variability.csv")) # Use Time Domain Reduced data for GenX
		capture_var = DataFrame(CSV.File(string(joinpath(data_directory,"CSC_capture_variability.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		capture_var = DataFrame(CSV.File(string(path,sep,"CSC_capture_variability.csv"), header=true), copycols=true)
	end

	# Reorder DataFrame to R_ID order (order provided in Generators_data.csv)
	select!(capture_var, [:Time_Index; Symbol.(inputs_capturevar["DAC_RESOURCES_NAME"]) ])

	# Maximum capture output and variability of each carbon capture resource
	inputs_capturevar["CO2_Capture_Max_Output"] = transpose(Matrix{Float64}(capture_var[1:inputs_capturevar["T"],2:(inputs_capturevar["DAC_RES_ALL"]+1)]))

	println(" -- CSC_capture_variability.csv Successfully Read!")

	return inputs_capturevar
end
