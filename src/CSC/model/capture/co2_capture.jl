

@doc raw"""
	co2_capture(EP::Model, inputs::Dict, setup::Dict)

This module models the CO2 captured by flue gas CCS units present in power, H2, and DAC plants and adds them to the total captured CO2 balance 
"""
function co2_capture(EP::Model, inputs::Dict, setup::Dict)

	CO2_CAPTURE_DAC = inputs["CO2_CAPTURE_DAC"]

	dfGen = inputs["dfGen"] #To account for the CO2 captured by power sector

	if setup["ModelH2"] == 1
		dfH2Gen = inputs["dfH2Gen"]::DataFrame
		H = inputs["H2_RES_ALL"]::Int
	end

	dfDAC = inputs["dfDAC"]  # Input CO2 capture data

	D = inputs["DAC_RES_ALL"]
	G = inputs["G"]::Int  # Number of resources (generators, storage, DR, and DERs)
	Z = inputs["Z"]::Int  # Model demand zones - assumed to be same for CO2, H2 and electricity
	T = inputs["T"]::Int	 # Model operating time steps

	if !isempty(CO2_CAPTURE_DAC)
		EP = co2_capture_DAC(EP::Model, inputs::Dict,setup::Dict)
	end

	#CO2 captued by power sector CCS plants
	@expression(EP, ePower_CO2_captured_per_plant_per_time[y=1:G,t=1:T], EP[:eCO2CaptureByPlant][y,t])
	@expression(EP, ePower_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(ePower_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	@expression(EP, ePower_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(ePower_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	
	#ADD TO CO2 BALANCE
	add_similar_to_expression!(EP[:eCaptured_CO2_Balance], EP[:ePower_CO2_captured_per_time_per_zone])

	#################################################################################################################################################################

	if setup["ModelH2"] == 1
		@expression(EP, eHydrogen_CO2_captured_per_plant_per_time[y=1:H,t=1:T], EP[:eCO2CaptureByH2Plant][y,t])
		@expression(EP, eHydrogen_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eHydrogen_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))
		@expression(EP, eHydrogen_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eHydrogen_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))

		#ADD TO CO2 BALANCE
		add_similar_to_expression!(EP[:eCaptured_CO2_Balance], EP[:eHydrogen_CO2_captured_per_time_per_zone])
	end
	#################################################################################################################################################################
	#CO2 captued by DAC CCS plants

    #CCS CO2 captured by fuel usage per type of resource "k"
    if setup["ParameterScale"] ==1
        @expression(EP,eCO2CaptureByDACFuelPlant[k=1:D,t=1:T], 
            inputs["fuel_CO2"][dfDAC[!,:Fuel][k]] * dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (dfDAC[!, :Fuel_CCS_Rate][k]) * ModelScalingFactor) #As fuel CO2 is already scaled to kton/MMBtu we need to scale vDAC_CO2_Captured
    else
        @expression(EP,eCO2CaptureByDACFuelPlant[k=1:D,t=1:T], 
        inputs["fuel_CO2"][dfDAC[!,:Fuel][k]] * dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (dfDAC[!, :Fuel_CCS_Rate][k]))
    end

	@expression(EP, eDAC_Fuel_CO2_captured_per_plant_per_time[y=1:D,t=1:T], EP[:eCO2CaptureByDACFuelPlant][y,t])
	@expression(EP, eDAC_Fuel_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eDAC_Fuel_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))
	@expression(EP, eDAC_Fuel_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eDAC_Fuel_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))
	
	#ADD TO CO2 BALANCE
	add_similar_to_expression!(EP[:eCaptured_CO2_Balance], EP[:eDAC_Fuel_CO2_captured_per_time_per_zone])


	return EP
end
