

@doc raw"""
	green_h2_share_requirement(EP::Model, inputs::Dict, setup::Dict)

This function establishes constraints that can be flexibily applied to define alternative forms of policies that require generation of a quantity of tonne-h2 from green h2 in the entire system across the entire year

	"""
function green_h2_share_requirement(EP::Model, inputs::Dict, setup::Dict)

	print_and_log("Green H2 Share Requirement Policies Module")

	T = inputs["T"]::Int     # Number of time steps (hours)
	Z = inputs["Z"]::Int     # Number of zones

	H2_ELECTROLYZER = inputs["H2_ELECTROLYZER"]::Vector{<:Int}
	GreenH2Share = setup["GreenH2Share"]

	if setup["GreenH2ShareRequirement"] == 1
		if setup["ModelH2G2P"] == 1
			## Green H2 Share Requirements (minimum H2 share from electrolyzer) constraint
			@expression(EP, eGlobalGreenH2Balance[t=1:T], sum(EP[:vH2Gen][y,t] for y in H2_ELECTROLYZER) )
			@expression(EP, eGlobalGreenH2Demand[t=1:T], sum(inputs["H2_D"][t,z] for z = 1:Z) )
			@expression(EP, eH2DemandG2P[t=1:T], sum(EP[:eH2DemandByZoneG2P][z,t] for z = 1:Z))	

			@expression(EP, eAnnualGlobalGreenH2Balance, sum(inputs["omega"][t] * EP[:eGlobalGreenH2Balance][t] for t = 1:T) )
			@expression(EP, eAnnualGlobalGreenH2Demand, sum(inputs["omega"][t] * EP[:eGlobalGreenH2Demand][t] for t = 1:T) )
			@expression(EP, eAnnualGlobalGreenH2DemandG2P, sum(inputs["omega"][t] * EP[:eH2DemandG2P][t] for t = 1:T) )

			@constraint(EP, cGreenH2ShareRequirement, eAnnualGlobalGreenH2Balance == GreenH2Share * (eAnnualGlobalGreenH2Demand + eAnnualGlobalGreenH2DemandG2P))
			
		else
			## Green H2 Share Requirements (minimum H2 share from electrolyzer) constraint
			@expression(EP, eGlobalGreenH2Balance[t=1:T], sum(EP[:vH2Gen][y,t] for y in H2_ELECTROLYZER) )
			@expression(EP, eGlobalGreenH2Demand[t=1:T], sum(inputs["H2_D"][t,z] for z = 1:Z) )

			@expression(EP, eAnnualGlobalGreenH2Balance, sum(inputs["omega"][t] * EP[:eGlobalGreenH2Balance][t] for t = 1:T) )
			@expression(EP, eAnnualGlobalGreenH2Demand, sum(inputs["omega"][t] * EP[:eGlobalGreenH2Demand][t] for t = 1:T) )

			@constraint(EP, cGreenH2ShareRequirement, eAnnualGlobalGreenH2Balance == GreenH2Share * eAnnualGlobalGreenH2Demand)
		end

	end



	return EP
end
