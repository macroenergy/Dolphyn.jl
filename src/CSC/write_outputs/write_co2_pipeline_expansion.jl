

@doc raw"""
	write_co2_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the expansion of CO2 pipelines.    
"""
function write_co2_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	L = inputs["CO2_P"]     # Number of CO2 pipelines
    
	Existing_Trans_Cap = zeros(L) # Transmission network reinforcements in tonne/hour
	transcap = zeros(L) # Transmission network reinforcements in tonne/hour
	Pipes = zeros(L) # Transmission network reinforcements in tonne/hour
	Fixed_Cost = zeros(L)
	#Comp_Cost = zeros(L)



	for i in 1:L
		Existing_Trans_Cap = inputs["pCO2_Pipe_Max_Flow"].*inputs["pCO2_Pipe_No_Curr"]
		transcap[i] = (value.(EP[:vCO2NPipe][i]) -inputs["pCO2_Pipe_No_Curr"][i]).*inputs["pCO2_Pipe_Max_Flow"][i]
		Pipes[i] = value.(EP[:vCO2NPipe][i])
		Fixed_Cost[i] = value.(EP[:eCO2NPipeNew][i]) * inputs["pCAPEX_CO2_Pipe"][i] + value.(EP[:vCO2NPipe][i]) * inputs["pFixed_OM_CO2_Pipe"][i]
		#Comp_Cost[i] = value.(EP[:eCO2NPipeNew][i]) * inputs["pCAPEX_Comp_CO2_Pipe"][i]
	end

	dfTransCap = DataFrame(
	Line = 1:L,
	Existing_Trans_Capacity = convert(Array{Union{Missing,Float32}}, Existing_Trans_Cap),
    New_Trans_Capacity = convert(Array{Union{Missing,Float32}}, transcap),
	Total_Pipes = convert(Array{Union{Missing,Float32}}, Pipes),
	Fixed_Cost_Pipes = convert(Array{Union{Missing,Float32}}, Fixed_Cost),
	#Comp_Cost_pipes = convert(Array{Union{Missing,Float32}}, Comp_Cost),
	)

	CSV.write(string(path,sep,"CSC_pipeline_expansion.csv"), dfTransCap)
end
