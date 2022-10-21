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

@doc raw"""
    co2_capture(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module uses the following 'helper' functions in separate files: ```co2_capture_uc()``` for DAC resources subject to unit commitment decisions and constraints (if any) and ```co2_capture_non_uc()``` for DAC resources not subject to unit commitment (if any).
"""
function co2_capture(EP::Model, inputs::Dict, setup::Dict)

    CO2_CAPTURE_UC = inputs["CO2_CAPTURE_UC"]
	CO2_CAPTURE_NON_UC = inputs["CO2_CAPTURE_NON_UC"]

	dfGen = inputs["dfGen"] #To account for the CO2 captured by power sector

	if setup["ModelH2"] == 1
		dfH2Gen = inputs["dfH2Gen"]
		H = inputs["H2_RES_ALL"]
	end

	dfCO2Capture = inputs["dfCO2Capture"]  # Input CO2 capture data
	
	G = inputs["G"]  # Number of resources (generators, storage, DR, and DERs)
	Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2, H2 and electricity
	T = inputs["T"]	 # Model operating time steps

	if !isempty(CO2_CAPTURE_UC)
		EP = co2_capture_uc(EP::Model, inputs::Dict, setup::Dict)
	end
	
	if !isempty(CO2_CAPTURE_NON_UC)
		EP = co2_capture_non_uc(EP::Model, inputs::Dict,setup::Dict)
	end

	#CO2 captued by power sector CCS plants
	@expression(EP, ePower_CO2_captured_per_plant_per_time[y=1:G,t=1:T], dfGen[!,:CO2_captured_per_MWh][y]*EP[:vP][y,t]) #tonne/MWh = kton/GWh so no need scale
	@expression(EP, ePower_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(ePower_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	@expression(EP, ePower_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(ePower_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	
	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] += EP[:ePower_CO2_captured_per_time_per_zone]

	if setup["ModelH2"] == 1
		@expression(EP, eHydrogen_CO2_captured_per_plant_per_time[y=1:H,t=1:T], EP[:eCO2CaptureByH2Plant][y,t])
		@expression(EP, eHydrogen_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eHydrogen_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))
		@expression(EP, eHydrogen_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eHydrogen_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))

		#ADD TO CO2 BALANCE
		EP[:eCaptured_CO2_Balance] += EP[:eHydrogen_CO2_captured_per_time_per_zone]
	end

	return EP
end
