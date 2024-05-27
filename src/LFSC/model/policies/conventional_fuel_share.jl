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
	conventional_fuel_share(EP::Model, inputs::Dict, setup::Dict)

This function establishes constraints that can be flexibily applied to define alternative forms of policies that require generation of a quantity of conventional fuel in the entire system across the entire year

	"""
function conventional_fuel_share(EP::Model, inputs::Dict, setup::Dict)
	println(" -- Conventional Fuel Share Requirement Policies Module")
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	Conv_Diesel_Share = setup["Conv_Diesel_Share"]
	Conv_Jetfuel_Share = setup["Conv_Jetfuel_Share"]
	Conv_Gasoline_Share = setup["Conv_Gasoline_Share"]

	### Diesel
	if setup["Conventional_Diesel_Share_Requirement"] == 1

		## Conventional Diesel Share Requirements
		@expression(EP, eAnnualGlobalSBDiesel, sum(sum(inputs["omega"][t] * EP[:eSBFDieselBalance][t,z] for z = 1:Z) for t = 1:T))

		if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1

			@expression(EP, AnnualeGlobalConvDiesel, sum(sum(inputs["omega"][t] * EP[:eCFDieselBalance][t,z] for z = 1:Z) for t = 1:T))
		
		elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0

			@expression(EP, AnnualeGlobalConvDiesel, sum(EP[:eCFDieselBalance][z] for z = 1:Z))

		elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1

			@expression(EP, AnnualeGlobalConvDiesel, sum(inputs["omega"][t] * EP[:eCFDieselBalance][t] for t = 1:T))

		elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0

			@expression(EP, AnnualeGlobalConvDiesel, EP[:eCFDieselBalance])

		end

		@constraint(EP, cConvDieselShare, (1-Conv_Diesel_Share) * EP[:AnnualeGlobalConvDiesel] == Conv_Diesel_Share * EP[:eAnnualGlobalSBDiesel])

	end

	### Jetfuel
	if setup["Conventional_Jetfuel_Share_Requirement"] == 1

		## Conventional Jetfuel Share Requirements
		@expression(EP, eAnnualGlobalSBJetfuel, sum(sum(inputs["omega"][t] * EP[:eSBFJetfuelBalance][t,z] for z = 1:Z) for t = 1:T))
	
		if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1
	
			@expression(EP, AnnualeGlobalConvJetfuel, sum(sum(inputs["omega"][t] * EP[:eCFJetfuelBalance][t,z] for z = 1:Z) for t = 1:T))
		
		elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0
	
			@expression(EP, AnnualeGlobalConvJetfuel, sum(EP[:eCFJetfuelBalance][z] for z = 1:Z))
	
		elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1
	
			@expression(EP, AnnualeGlobalConvJetfuel, sum(inputs["omega"][t] * EP[:eCFJetfuelBalance][t] for t = 1:T))
	
		elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0
	
			@expression(EP, AnnualeGlobalConvJetfuel, EP[:eCFJetfuelBalance])
	
		end
	
		@constraint(EP, cConvJetfuelShare, (1-Conv_Jetfuel_Share) * EP[:AnnualeGlobalConvJetfuel] == Conv_Jetfuel_Share * EP[:eAnnualGlobalSBJetfuel])
	
	end

	### Gasoline
	if setup["Conventional_Gasoline_Share_Requirement"] == 1

		## Conventional Gasoline Share Requirements
		@expression(EP, eAnnualGlobalSBGasoline, sum(sum(inputs["omega"][t] * EP[:eSBFGasolineBalance][t,z] for z = 1:Z) for t = 1:T))
	
		if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1
	
			@expression(EP, AnnualeGlobalConvGasoline, sum(sum(inputs["omega"][t] * EP[:eCFGasolineBalance][t,z] for z = 1:Z) for t = 1:T))
		
		elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0
	
			@expression(EP, AnnualeGlobalConvGasoline, sum(EP[:eCFGasolineBalance][z] for z = 1:Z))
	
		elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1
	
			@expression(EP, AnnualeGlobalConvGasoline, sum(inputs["omega"][t] * EP[:eCFGasolineBalance][t] for t = 1:T))
	
		elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0
	
			@expression(EP, AnnualeGlobalConvGasoline, EP[:eCFGasolineBalance])
	
		end
	
		@constraint(EP, cConvGasolineShare, (1-Conv_Gasoline_Share) * EP[:AnnualeGlobalConvGasoline] == Conv_Gasoline_Share * EP[:eAnnualGlobalSBGasoline])
	
	end

	return EP
end
