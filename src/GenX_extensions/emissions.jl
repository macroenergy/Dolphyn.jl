@doc raw"""
	emissions(EP::Model, inputs::Dict)

This function creates expression to add the CO2 emissions by plants in each zone, which is subsequently added to the total emissions
"""
function emissions!(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Emissions Module for CO2 Policy modularization")

	dfGen = inputs["dfGen"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	# HOTFIX - If CCS_Rate is not in the dfGen, then add it and set it to 0
	if "CCS_Rate" ∉ names(dfGen)
		dfGen[!,:CCS_Rate] .= 0
	end

	@expression(EP, eEmissionsByPlant[y=1:G,t=1:T],

		if y in inputs["COMMIT"]
			(dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]+dfGen[y,:CO2_per_Start]*EP[:vSTART][y,t])*(1-dfGen[!, :CCS_Rate][y])
		else
			dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]*(1-dfGen[!, :CCS_Rate][y])
		end
	)

	@expression(
        EP,
        eCO2CaptureByPlant[y = 1:G, t = 1:T],
        if y in inputs["COMMIT"]
			(dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]+dfGen[y,:CO2_per_Start]*EP[:vSTART][y,t])*(dfGen[!, :CCS_Rate][y])
		else
			dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]*(dfGen[!, :CCS_Rate][y])
		end
    )

	@expression(EP, eEmissionsByZone[z=1:Z, t=1:T], sum(eEmissionsByPlant[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))

	# If CO2 price is implemented in HSC balance or Power Balance and SystemCO2 constraint is active (independent or joint),
 	# then need to add cost penalty due to CO2 prices
	if (setup["CO2Cap"] ==4) 
		# Use CO2 price for power system as the global CO2 price
		# Emissions penalty by zone - needed to report zonal cost breakdown
		@expression(EP,eCEmissionsPenaltybyZone[z = 1:Z],
			sum(inputs["omega"][t]*sum(eEmissionsByZone[z,t]*inputs["dfCO2Price"][z,cap] for cap = findall(x->x==1, inputs["dfCO2CapZones"][z,:])) for t = 1:T)
		)

		# Sum over each policy type, each zone and each time step
		@expression(EP,eCEmissionsPenaltybyPolicy[cap = 1:inputs["NCO2Cap"]],
			sum(inputs["omega"][t]*sum(eEmissionsByZone[z,t]*inputs["dfCO2Price"][z,cap] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) for t = 1:T)
		)

		@expression(EP,eCGenTotalEmissionsPenalty,
			sum(eCEmissionsPenaltybyPolicy[cap] for cap=1:inputs["NCO2Cap"])
		)

		# Add total emissions penalty associated with direct emissions from power generation technologies
		EP[:eObj] += eCGenTotalEmissionsPenalty

	end

	return EP

end
