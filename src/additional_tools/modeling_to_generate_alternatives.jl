"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
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
	mga(EP::Model, path::AbstractString, setup::Dict, inputs::Dict, outpath::AbstractString)

We have implemented an updated Modeling to Generate Alternatives (MGA) Algorithm proposed by [Evelina et al., (2017)](https://www.sciencedirect.com/science/article/pii/S0360544217304097) to generate a set of feasible, near cost-optimal technology portfolios. This algorithm was developed by [Brill Jr, E. D., 1979](https://pubsonline.informs.org/doi/abs/10.1287/mnsc.25.5.413) and introduced to energy system planning by [DeCarolia, J. F., 2011](https://www.sciencedirect.com/science/article/pii/S0140988310000721).

To create the MGA formulation, we replace the cost-minimizing objective function of GenX with a new objective function that creates multiple generation portfolios by zone. We further add a new budget constraint based on the optimal objective function value $f^*$ of the least-cost model and the user-specified value of slack $\delta$. After adding the slack constraint, the resulting MGA formulation is given as:

```math
\begin{aligned}
	\text{max/min} \quad
	&\sum_{z \in \mathcal{Z}}\sum_{r \in \mathcal{R}} \beta_{z,r}^{k}P_{z,r}\\
	\text{s.t.} \quad
	&P_{zr} = \sum_{y \in \mathcal{G}}\sum_{t \in \mathcal{T}} \omega_{t} \Theta_{y,t,z,r}  \\
	& f \leq f^* + \delta \\
	&Ax = b
\end{aligned}
```

where, $\beta_{zr}$ is a random objective fucntion coefficient betwen $[0,100]$ for MGA iteration $k$. $\Theta_{y,t,z,r}$ is a generation of technology $y$ in zone $z$ in time period $t$ that belongs to a resource type $r$. We aggregate $\Theta_{y,t,z,r}$ into a new variable $P_{z,r}$ that represents total generation from technology type $r$ in a zone $z$. In the second constraint above, $\delta$ denote the increase in budget from the least-cost solution and $f$ represents the expression for the total system cost. The constraint $Ax = b$ represents all other constraints in the power system model. We then solve the formulation with minimization and maximization objective function to explore near optimal solution space.
"""
function mga(EP::Model, path::AbstractString, setup::Dict, inputs::Dict, outpath::AbstractString)

    if setup["ModelingToGenerateAlternatives"]==1
        # Start MGA Algorithm
	    println("MGA Module")

	    # Objective function value of the least cost problem
	    Least_System_Cost = objective_value(EP)

	    # Read sets
	    dfGen = inputs["dfGen"]
		if setup["ModelH2"] == 1
			dfH2Gen = inputs["dfH2Gen"]
			if setup["ModelH2G2P"] == 1
				dfH2G2P = inputs["dfH2G2P"]
			end
		end
		if setup["ModelCO2"] == 1
			dfCO2Capture = inputs["dfCO2Capture"]
		end
		if setup["ModelBIO"] == 1
			dfbiorefinery = inputs["dfbiorefinery"]
		end
		
	    T = inputs["T"]     # Number of time steps (hours)
	    Z = inputs["Z"]     # Number of zones
	    G = inputs["G"]

	    # Create a set of unique technology types
	    TechTypes = unique(dfGen[dfGen[!, :MGA] .== 1, :Resource_Type])
		if setup["ModelH2"] == 1
			H2_TechTypes = unique(dfH2Gen[dfH2Gen[!, :MGA] .== 1, :Resource_Type])
			if setup["ModelH2G2P"] == 1
				H2G2P_TechTypes = unique(dfH2G2P[dfH2G2P[!, :MGA] .== 1, :Resource_Type])
			end
		end
		if setup["ModelCO2"] == 1
			CO2Capture_TechTypes = unique(dfCO2Capture[dfCO2Capture[!, :MGA] .== 1, :Resource_Type])
		end
		if setup["ModelBIO"] == 1
			Bio_TechTypes = unique(dfbiorefinery[dfbiorefinery[!, :MGA] .== 1, :Resource_Type])
		end

	    # Read slack parameter representing desired increase in budget from the least cost solution
	    slack = setup["ModelingtoGenerateAlternativeSlack"]

	    ### Variables ###

	    @variable(EP, vSumvP[TechTypes = 1:length(TechTypes), z = 1:Z] >= 0) # Variable denoting total generation from eligible technology of a given type
		if setup["ModelH2"] == 1
			@variable(EP, vSumvH2[H2_TechTypes = 1:length(H2_TechTypes), z = 1:Z] >= 0) 
			if setup["ModelH2G2P"] == 1
				@variable(EP, vSumvH2G2P[H2G2P_TechTypes = 1:length(H2G2P_TechTypes), z = 1:Z] >= 0) 
			end
		end
		if setup["ModelCO2"] == 1
			@variable(EP, vSumvCO2Capture[CO2Capture_TechTypes = 1:length(CO2Capture_TechTypes), z = 1:Z] >= 0) 
		end
		if setup["ModelBIO"] == 1
			@variable(EP, vSumvBio[Bio_TechTypes = 1:length(Bio_TechTypes), z = 1:Z] >= 0)
			
			if setup["BIO_Electricity_On"] == 1
				@variable(EP, vSumvBioE[Bio_TechTypes = 1:length(Bio_TechTypes), z = 1:Z] >= 0) 
			end
			if setup["BIO_H2_On"] == 1
				@variable(EP, vSumvBioH2[Bio_TechTypes = 1:length(Bio_TechTypes), z = 1:Z] >= 0) 
			end
		end

	    ### End Variables ###

	    ### Constraints ###

	    # Constraint to set budget for MGA iterations
	    @constraint(EP, budget, EP[:eObj] <= Least_System_Cost * (1 + slack) )

        # Constraint to compute total generation in each zone from a given Technology Type
		@constraint(EP,cGeneration[tt = 1:length(TechTypes), z = 1:Z], vSumvP[tt,z] == sum(EP[:vP][y,t] * inputs["omega"][t]
	    for y in dfGen[(dfGen[!,:Resource_Type] .== TechTypes[tt]) .& (dfGen[!,:Zone] .== z), :R_ID], t in 1:T))

		if setup["ModelH2"] == 1
			@constraint(EP,cGenerationH2[tt = 1:length(H2_TechTypes), z = 1:Z], vSumvH2[tt,z] == sum(EP[:vH2Gen][y,t] * inputs["omega"][t]
	    	for y in dfH2Gen[(dfH2Gen[!,:Resource_Type] .== H2_TechTypes[tt]) .& (dfH2Gen[!,:Zone] .== z), :R_ID], t in 1:T))
			if setup["ModelH2G2P"] == 1
				@constraint(EP,cGenerationH2G2P[tt = 1:length(H2G2P_TechTypes), z = 1:Z], vSumvH2G2P[tt,z] == sum(EP[:vPG2P][y,t] * inputs["omega"][t]
	    		for y in dfH2G2P[(dfH2G2P[!,:Resource_Type] .== H2G2P_TechTypes[tt]) .& (dfH2G2P[!,:Zone] .== z), :R_ID], t in 1:T))
			end
		end
		
		if setup["ModelCO2"] == 1
			@constraint(EP,cGenerationCO2Capture[tt = 1:length(CO2Capture_TechTypes), z = 1:Z], vSumvCO2Capture[tt,z] == sum(EP[:vDAC_CO2_Captured][y,t] * inputs["omega"][t]
	    	for y in dfCO2Capture[(dfCO2Capture[!,:Resource_Type] .== CO2Capture_TechTypes[tt]) .& (dfCO2Capture[!,:Zone] .== z), :R_ID], t in 1:T))
		end
		if setup["ModelBIO"] == 1
			@constraint(EP,cGenerationBio[tt = 1:length(Bio_TechTypes), z = 1:Z], vSumvBio[tt,z] == sum(EP[:eBIO_CO2_captured_per_plant_per_time][y,t] * inputs["omega"][t]
	    	for y in dfbiorefinery[(dfbiorefinery[!,:Resource_Type] .== Bio_TechTypes[tt]) .& (dfbiorefinery[!,:Zone] .== z), :R_ID], t in 1:T))

			if setup["BIO_Electricity_On"] == 1
				@constraint(EP,cGenerationBioE[tt = 1:length(Bio_TechTypes), z = 1:Z], vSumvBioE[tt,z] == sum(EP[:eBioelectricity_produced_per_plant_per_time][y,t] * inputs["omega"][t]
				for y in dfbiorefinery[(dfbiorefinery[!,:Resource_Type] .== Bio_TechTypes[tt]) .& (dfbiorefinery[!,:Zone] .== z), :R_ID], t in 1:T))
			end

			if setup["BIO_H2_On"] == 1
				@constraint(EP,cGenerationBioH2[tt = 1:length(Bio_TechTypes), z = 1:Z], vSumvBioH2[tt,z] == sum(EP[:eBiohydrogen_produced_per_plant_per_time][y,t] * inputs["omega"][t]
				for y in dfbiorefinery[(dfbiorefinery[!,:Resource_Type] .== Bio_TechTypes[tt]) .& (dfbiorefinery[!,:Zone] .== z), :R_ID], t in 1:T))
			end

		end
	    ### End Constraints ###

	    ### Create Results Directory for MGA iterations
        outpath_max = joinpath(path, "MGAResults_max")
	    if !(isdir(outpath_max))
	    	mkdir(outpath_max)
	    end
        outpath_min = joinpath(path, "MGAResults_min")
	    if !(isdir(outpath_min))
	    	mkdir(outpath_min)
	    end

	    ### Begin MGA iterations for maximization and minimization objective ###
	    mga_start_time = time()

	    print("Starting the first MGA iteration")

		pRand = rand(length(unique(dfGen[dfGen[!, :MGA] .== 1, :Resource_Type])),length(unique(dfGen[!,:Zone]))) 
		if setup["ModelH2"] == 1
			pRandH2 = rand(length(unique(dfH2Gen[dfH2Gen[!, :MGA] .== 1, :Resource_Type])),length(unique(dfH2Gen[!,:Zone])))
			if setup["ModelH2G2P"] == 1
				pRandH2G2P = rand(length(unique(dfH2G2P[dfH2G2P[!, :MGA] .== 1, :Resource_Type])),length(unique(dfH2G2P[!,:Zone])))
			end
		end
		
		if setup["ModelCO2"] == 1
			pRandCO2Capture = rand(length(unique(dfCO2Capture[dfCO2Capture[!, :MGA] .== 1, :Resource_Type])),length(unique(dfCO2Capture[!,:Zone])))
		end
		if setup["ModelBIO"] == 1
			pRandBio= rand(length(unique(dfbiorefinery[dfbiorefinery[!, :MGA] .== 1, :Resource_Type])),length(unique(dfbiorefinery[!,:Zone])))
			if setup["BIO_Electricity_On"] == 1
				pRandBioE= rand(length(unique(dfbiorefinery[dfbiorefinery[!, :MGA] .== 1, :Resource_Type])),length(unique(dfbiorefinery[!,:Zone])))
			end
			if setup["BIO_H2_On"] == 1
				pRandBioH2= rand(length(unique(dfbiorefinery[dfbiorefinery[!, :MGA] .== 1, :Resource_Type])),length(unique(dfbiorefinery[!,:Zone])))
			end

		end

		# Define technology expressions
		@expression(EP, ePe1[z=1:Z], sum(pRand[tt,z] * vSumvP[tt,z] for tt in 1:length(TechTypes)))
		@expression(EP, ePe, sum(ePe1[z] for z in 1:Z))
		if setup["ModelH2"] == 1
			@expression(EP, eH2e1[z=1:Z], sum(pRandH2[tt,z] * vSumvH2[tt,z] for tt in 1:length(H2_TechTypes)))
			@expression(EP, eH2e, sum(eH2e1[z] for z in 1:Z))
			if setup["ModelH2G2P"] == 1
				@expression(EP, eH2G2Pe1[z=1:Z], sum(pRandH2G2P[tt,z] * vSumvH2G2P[tt,z] for tt in 1:length(H2G2P_TechTypes)))
				@expression(EP, eH2G2Pe, sum(eH2G2Pe1[z] for z in 1:Z))
			end
		end

		if setup["ModelCO2"] == 1
			@expression(EP, eCO2Capturee1[z=1:Z], sum(pRandCO2Capture[tt,z] * vSumvCO2Capture[tt,z] for tt in 1:length(CO2Capture_TechTypes)))
			@expression(EP, eCO2Capturee, sum(eCO2Capturee1[z] for z in 1:Z))
		end
		if setup["ModelBIO"] == 1
			@expression(EP, eBioe1[z=1:Z], sum(pRandBio[tt,z] * vSumvBio[tt,z] for tt in 1:length(Bio_TechTypes)))
			@expression(EP, eBioe, sum(eBioe1[z] for z in 1:Z))

			if setup["BIO_Electricity_On"] == 1
				@expression(EP, eBioEe1[z=1:Z], sum(pRandBioE[tt,z] * vSumvBioE[tt,z] for tt in 1:length(Bio_TechTypes)))
				@expression(EP, eBioEe, sum(eBioEe1[z] for z in 1:Z))
			end

			if setup["BIO_H2_On"] == 1
				@expression(EP, eBioH2e1[z=1:Z], sum(pRandBioH2[tt,z] * vSumvBioH2[tt,z] for tt in 1:length(Bio_TechTypes)))
				@expression(EP, eBioH2e, sum(eBioH2e1[z] for z in 1:Z))
			end
		end

	    for i in 1:setup["ModelingToGenerateAlternativeIterations"]

	    	# Create random coefficients between 0 and 1 for the generators that we want to include in the MGA run for the given budget
			
			# Add summation to objective
			add_to_expression!(EP[:eObj], ePe)
			pRand = rand(length(unique(dfGen[dfGen[!, :MGA] .== 1, :Resource_Type])),length(unique(dfGen[!,:Zone]))) 

			if setup["ModelH2"] == 1
				add_to_expression!(EP[:eObj], eH2e)
				pRandH2 = rand(length(unique(dfH2Gen[dfH2Gen[!, :MGA] .== 1, :Resource_Type])),length(unique(dfH2Gen[!,:Zone])))
				if setup["ModelH2G2P"] == 1
					add_to_expression!(EP[:eObj], eH2G2Pe)
					pRandH2G2P = rand(length(unique(dfH2G2P[dfH2G2P[!, :MGA] .== 1, :Resource_Type])),length(unique(dfH2G2P[!,:Zone])))
				end
			end

			if setup["ModelCO2"] == 1
				add_to_expression!(EP[:eObj], eCO2Capturee)
				pRandCO2Capture = rand(length(unique(dfCO2Capture[dfCO2Capture[!, :MGA] .== 1, :Resource_Type])),length(unique(dfCO2Capture[!,:Zone])))
			end
			if setup["ModelBIO"] == 1
				add_to_expression!(EP[:eObj], eBioe)
				pRandBio = rand(length(unique(dfbiorefinery[dfbiorefinery[!, :MGA] .== 1, :Resource_Type])),length(unique(dfbiorefinery[!,:Zone])))
				if setup["BIO_Electricity_On"] == 1
					add_to_expression!(EP[:eObj], eBioEe)
					pRandBioE= rand(length(unique(dfbiorefinery[dfbiorefinery[!, :MGA] .== 1, :Resource_Type])),length(unique(dfbiorefinery[!,:Zone])))
				end
				if setup["BIO_H2_On"] == 1
					add_to_expression!(EP[:eObj], eBioH2e)
					pRandBioH2= rand(length(unique(dfbiorefinery[dfbiorefinery[!, :MGA] .== 1, :Resource_Type])),length(unique(dfbiorefinery[!,:Zone])))				end
			end
			
			### Maximization objective
			@objective(EP,Max,EP[:eObj])
		
	    	# Solve Model Iteration
	    	status = optimize!(EP)

            # Create path for saving MGA iterations
	    	mgaoutpath_max = joinpath(outpath_max, string("MGA", "_", slack,"_", i))
			if setup["ModelH2"] == 1
				hscoutpath_max = joinpath(outpath_max, string("MGA", "_", slack,"_", i'),"Results_HSC")
			end
			if setup["ModelCO2"] == 1
				cscoutpath_max = joinpath(outpath_max, string("MGA", "_", slack,"_", i'),"Results_CSC")
			end
			if setup["ModelBIO"] == 1
				biooutpath_max = joinpath(outpath_max, string("MGA", "_", slack,"_", i'),"Results_BESC")
			end

	    	# Write results
	    	write_outputs(EP, mgaoutpath_max, setup, inputs)
			if setup["ModelH2"] == 1
				write_HSC_outputs(EP, hscoutpath_max, setup, inputs)
			end
			if setup["ModelCO2"] == 1
				write_CSC_outputs(EP, cscoutpath_max, setup, inputs)
			end
			if setup["ModelBIO"] == 1
				write_BESC_outputs(EP, biooutpath_max, setup, inputs)
			end

	    	### Minimization objective
			@objective(EP,Min,EP[:eObj])

	    	# Solve Model Iteration
	    	status = optimize!(EP)

            # Create path for saving MGA iterations
	    	mgaoutpath_min = joinpath(outpath_min, string("MGA", "_", slack,"_", i))
			if setup["ModelH2"] == 1
				hscoutpath_min = joinpath(outpath_min, string("MGA", "_", slack,"_", i),"Results_HSC")
			end
			if setup["ModelCO2"] == 1
				cscoutpath_min = joinpath(outpath_min, string("MGA", "_", slack,"_", i),"Results_CSC")
			end
			if setup["ModelBIO"] == 1
				biooutpath_min = joinpath(outpath_min, string("MGA", "_", slack,"_", i),"Results_BESC")
			end

	    	# Write results
	    	write_outputs(EP, mgaoutpath_min, setup, inputs)
			if setup["ModelH2"] == 1
				write_HSC_outputs(EP, hscoutpath_min, setup, inputs)
			end
			if setup["ModelCO2"] == 1
				write_CSC_outputs(EP, cscoutpath_min, setup, inputs)
			end
			if setup["ModelBIO"] == 1
				write_BESC_outputs(EP, biooutpath_min, setup, inputs)
			end

	    end

	    total_time = time() - mga_start_time
	    ### End MGA Iterations ###
	end

end