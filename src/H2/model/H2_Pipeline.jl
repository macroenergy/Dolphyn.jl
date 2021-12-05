@doc raw"""
		H2_Gen(HY::Model, dModuleArgs::Dict)

	This function defines the costs and operating constraints for hydrogen generation units.

	**H2 Generation CAPEX expression**

	These functions define the capital costs of hydrogen generation units:
	```math
	\begin{align}
	C_{\text{GEN}}^{\text{c}} = \delta^{\text{GEN}}_{k}  \sum\limits_{z \in \mathbb{Z}}\sum\limits_{k \in \mathbb{K} }  \text{c}^{\text{GEN}}_{k}  \text{M}^{\text{GEN}}_{k,z}  N^{\text{new}}_{k,z}
	\end{align}
	```
	(See Expressions #1-3 in the code below)

	**H2 Generation OPEX-Gas expression**

	This function defines the gas cost of hydrogen generation units:
	```math
	\begin{align}
	C_{\text{GAS}}^{\text{o}} = \sum\limits_{z \in \mathbb{Z}}\sum\limits_{k \in \mathbb{K} } \sum\limits_{t \in \mathbb{T}}  \Omega_{t} \lambda^{\text{GAS}}_{z,t} h^{\text{GEN}}_{k,z,t}  \eta^{\text{GAS}}_{k,z}
	\end{align}
	```
	(See Expression #4 in the code below)

	**H2 generation start-up OPEX expression**

	This function defines the start-up cost of hydrogen generation units:
	```math
	\begin{align}
	C_{\text{START}}^{\text{o}} = \sum\limits_{z \in \mathbb{Z}}\sum\limits_{k \in \mathbb{K} } \sum\limits_{t \in \mathbb{T}}  \Omega_{t} \lambda^{\text{START}}_{z,t} n^{\text{UP}}_{k,z,t}
	\end{align}
	```
	(See Expression #4 in the code below)

	**H2 balance expression**

	This function adds the sum of H2 generation ($h^{\text{GEN}}_{k\in \mathbb{K},z \in \mathbb{Z},t \mathbb{T}}$) from H2 generation units to the H2 balance expression.


	**H2 power consumption balance expression**

	This function adds the sum of power  consumption ($p^{\text{GEN}}_{k\in \mathbb{K},z \in \mathbb{Z},t \mathbb{T}}$) from H2 generation units (electrolysis) to the power balance expression.

	**Carbon emission balance expression**

	This function adds the sum of carbon emissions ($\sum\limits_{k \in \mathbb{K}} \sum\limits_{z \in \mathbb{Z}} \sum\limits_{t \in \mathbb{T}} \Omega_{t} \text{c}^{\text{EMI}}
    \text{e}^{\text{GEN}}_{k} h^{\text{GEN}}_{k,z,t}$) from H2 generation units to the carbon emission balance expression.

	**Relations between power consumption, gas consumption, and H2 generation variables**

	```math
	\begin{align}
	p^{\text{GEN}}_{k,z,t} =
	\eta^{\text{ELE}}_{k,z}  h^{\text{GEN}}_{k,z,t}
		\hspace{4cm} \forall k\in \mathbb{K}, z \in \mathbb{Z},t \mathbb{T}
	\end{align}
	\begin{align}
	v^{\text{GAS}}_{k,z,t} =
	\eta^{\text{GAS}}_{k,z}  h^{\text{GEN}}_{k,z,t}
		\hspace{4cm} \forall k\in \mathbb{K}, z \in \mathbb{Z},t \mathbb{T}
	\end{align}

	```
	(See Constraints #1-2 in the code below)

	**Capacity limits on H2 generation unit decision variables**

	The outputs of each type of H$_2$ generation facilities have to be kept within their lower and upper bounds ($ \underline{\text{R}}^{GEN}_{k,z} $ and $ \overline{\text{R}}^{GEN}_{k,z} $).\text{M}^{\text{GEN}}_{k,z} $ is the rated size of a H$_2$ generation unit. $ n_{k,z,t} $ denotes the number of online units. The number of online units has to be less than the available number of generation units.

	```math
	\begin{align}
	\overline{\text{R}}^{\text{GEN}}_{k,z}  \text{M}^{\text{GEN}}_{k,z}  n_{k,z,t} \geq h^{\text{GEN}}_{k,z,t} \geq \underline{\text{R}}^{\text{GEN}}_{k,z}  \text{M}^{\text{GEN}}_{k,z}  n_{k,z,t}
    \\\qquad \forall  k \in \mathbb{K},z \in \mathbb{Z}, t \in \mathbb{T}
	\end{align}
	\begin{align}
	n_{k,z,t} \leq N_{k,z}
    \qquad \forall  k \in \mathbb{K},z \in \mathbb{Z}, t \in \mathbb{T}
	\end{align}
	```
	(See Constraints #3-5 in the code below)

	Thermal resources (natural gas based hydrogen production) subject to unit commitment adhere to the following constraints on commitment states, startup events, and shutdown events, which limit each decision to be no greater than the maximum number of discrete units installed:

	```math
	\begin{align}
	n_{k,z,t} - n_{k,z,t-1} = n^{\text{UP}}_{k,z,t} - n^{\text{DOWN}}_{k,z,t}
   	\qquad \forall  k \in \mathbb{K},z \in \mathbb{Z}, t \in \mathbb{T}
	\end{align}
	\begin{align}
	n_{k,z,t} \geq
   	\sum\limits_{\tau = t-		\tau^\text{UP}_{k,z}}^{t} n^{\text{UP}}_{k,z,t}
   	\qquad \forall  k \in \mathbb{K},z \in \mathbb{Z}, t \in \mathbb{T}
	\end{align}
	\begin{align}
	N_{k,z} - n_{k,z,t} \geq \sum\limits_{\tau = t-\tau^\text{DOWN}_{k,z}}^{t} n^{\text{DOWN}}_{k,z,t}
    \qquad \forall  k \in \mathbb{K},z \in \mathbb{Z}, t \in \mathbb{T}
	\end{align}
	```
	(See Constraints #6-8 in the code below)

	The numbers of units starting up and shutting down are represented by $n^{\text{UP}}_{k,z,t}$ and $n^{\text{DOWN}}_{k,z,t}$. There are limits on the period of time between when a unit starts up and when it can be shut-down again, and vice versa. The minimum up and down time are denoted by $ \tau^\text{UP}_{k,z} $ and $ \tau^\text{DOWN}_{k,z} $, respectively.

	**Constraints for integer generation modeling**
	The integer variables in the constraints above are relaxed. Constraints #9-16 are the same constraints but not relaxed.

"""
## Q. for Guannan - 
# 1. Please add brief comments on variables and constraints - they are not clear - use letter "p" to initiate parameters and "v" for initiating variable names
# 2. Issue with H2PipeCap usage and units is it on a per mile basis or cumulative basis?

function H2Pipeline(EP::Model, inputs::Dict)

	println("Hydrogen Pipeline Module")

    T = inputs["T"]
    Z = inputs["Z"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]

	H2_P = inputs["H2_P"] # Number of Hydrogen Pipelines
    pH2_Pipe_Map = inputs["pH2_Pipe_Map"] 

	### Variables ###
    @variable(EP, 0 >= vH2NPipe[p=1:H2_P] >= 0 ) #Number of Pipes
    @variable(EP, 0 >= vH2PipeLevel[p=1:H2_P, t = 1:T] >= 0 ) #Storage in the pipe
    @variable(EP, vH2PipeFlow[p=1:H2_P, t = 1:T, z= 1:Z, zz = 1:Z] ) #pipe flow
    @variable(EP, 0 >= vH2PipeFlow_pos[p=1:H2_P, t = 1:T, z = 1:Z, zz = 1:Z] >= 0) #positive pipeflow
    @variable(EP, 0 >= vH2PipeFlow_neg[p=1:H2_P, t = 1:T, z = 1:Z, zz = 1:Z] >= 0) #negative pipeflow

	if inputs_H2["H2_Pipe_Integer"] == 1
		set_integer.(vH2NPipe)
	end

    #variables that need to be added to load_pipeline
    pC_H2_Pipe #$/pipe
    pH2Pipe_Comp_Per_Mile # compressors/mile/pipe
    pCH2Pipe_Comp_Per_Comp #$/compressor
    pH2PipeCompressionEnergy #MWh/tonne / hr
    pdistance_mile #miles
    pH2_Pipe_Flow_Max #tonne/hr/pipe
    rhoH2PipeCap_min
    H2PipeCap #capacity per pipe tonnes

	### Expressions ###
	## Objective Function Expressions ##

	# Capital cost of pipelines 
	@expression(EP, eCH2Pipe,  sum(vH2NPipe[p] * inputs["pC_H2_Pipe"][p] for p = 1:H2_P))

    EP[:eObj] += eCH2Pipe

	# Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    #YS Formula doesn't make sense to me
	@expression(EP, eCH2CompPipe, sum(vH2NPipe[p] * inputs["pdistance_mile"][p] / inputs["pH2Pipe_Comp_Per_Mile"][p] * inputs["pCH2Pipe_Comp_Per_Comp"][p] for p = 1:H2_P))

    EP[:eObj] += eCH2CompPipe

	## End Objective Function Expressions ##

	## Balance Expressions ##
	# H2 Power Consumption balance
	# Electrical energy requirement for booster compression - 
	@expression(EP, ePowerBalanceH2PipeCompression[t=1:T, z=1:Z],
	sum(vH2PipeFlow_neg[p,t, z, zz] * inputs["pdistance_mile"][p] / inputs["pH2Pipe_Comp_Per_Mile"][p] * inputs["pH2PipeCompressionEnergy"][p] for zz = 1:Z,p = 1:PT if zz != z))
	
    EP[:ePowerBalance] += ePowerBalanceH2PipeCompression

	# H2 balance - net flows of H2 from between z and zz via pipeline p over time period t
	@expression(EP, ePipeFlow[t=1:T,z=1:Z], sum(vH2PipeFlow[z,zz,p,t] for zz = 1:Z, p = 1:PT if zz != z))

    EP[:eH2Balance] += ePipeFlow

	## End Balance Expressions ##
	### End Expressions ###

	### Constraints ###

    #ADD 0 CONSTRAINT FOR PIPELINES NOT ORGINATING AND ENDING IN ZONES ASSOCIATED WITH SAID PIPELINE
    # Eliminating variables where source and sink are the same
    @constraints(EP, begin
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t=1:T], EP[:vH2PipeFlow][p,t, z, zz] <= EP[:vH2Npipe][p] * inputs["pH2_Pipe_Flow_Max"][p]
        
    end)

    #Constraint maximum pipe flow
    @constraints(EP, begin
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t=1:T], EP[:vH2PipeFlow][p,t, z, zz] <= EP[:vH2Npipe][p] * inputs["pH2_Pipe_Flow_Max"][p]
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t=1:T], -EP[:vH2PipeFlow][p,t, z, zz] <= EP[:vH2Npipe][p] * inputs["pH2_Pipe_Flow_Max"][p]
    end)

    #Constrain positive and negative pipe flows
    @constraints(EP, begin
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t=1:T], vH2NPipe[p] * inputs["pH2_Pipe_Flow_Max"][p] >= vH2PipeFlow_pos[p,t, z, zz]
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t=1:T], vH2NPipe[p] * inputs["pH2_Pipe_Flow_Max"][p] >= vH2PipeFlow_neg[p,t, z, zz]
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t=1:T], vH2PipeFlow[p,t, z, zz] == vH2PipeFlow_pos[p,t, z, zz] - vH2PipeFlow_neg[p,t, z, zz]
    end)

    @constraints(EP, begin
    [p in H2_PIPELINES, t=1:T], vH2PipeLevel[p,t] >= inputs["rhoH2PipeCap_min"][p] * inputs["H2PipeCap"][p] * vH2NPipe[p]
    [p in H2_PIPELINES, t=1:T], inputs["H2PipeCap"][p] * vH2NPipe[p] >= vH2PipeLevel[p,t]
    end)

    @constraint(EP, begin
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t in START_SUBPERIODS], vH2PipeLevel[p,t] == vH2PipeLevel[p,T] - vH2PipeFlow[p,t, z, zz] - vH2PipeFlow[p,t, z, zz]
    end)

    @constraint(EP, begin
    [z in 1:Z, zz in 1:Z, p in H2_PIPELINES, t in INTERIOR_SUBPERIODS], vH2PipeLevel[p,t] == vH2PipeLevel[p,t - 1] - vH2PipeFlow[p,t, z, zz] - vH2PipeFlow[p,t, z, zz]
    end)

    
	# for w in 1:W
	#     for h in 1:Tw
	#         t = Tw*(w-1)+h
	#         tw_min = Tw*(w-1)+1
	#         tw_max = Tw*(w-1)+Tw

	# 		for z in 1:Z
	# 		    # for t in 1:T
	# 	        for zz in 1:Z
	# 	            for p in 1:H2_P
	# 					# Pipeline capacity constraints - flows in positive and negative direction allowed
	# 	                @constraint(EP, vH2NPipe[zz,z,p] * H2PipeFlowSize[p] >= vH2PipeFlow[zz,z,p,t])
	# 	                @constraint(EP, vH2PipeFlow[zz,z,p,t] >= -vH2NPipe[zz,z,p] * H2PipeFlowSize[p])

	# 					# capacity constraints applied to one-way flow variables
	# 	                @constraint(EP, vH2NPipe[zz,z,p] * H2PipeFlowSize[p] >= vH2PipeFlow_pos[zz,z,p,t])
	# 	                @constraint(EP, vH2NPipe[zz,z,p] * H2PipeFlowSize[p] >= vH2PipeFlow_neg[zz,z,p,t])
	# 	                @constraint(EP, vH2PipeFlow[zz,z,p,t] == vH2PipeFlow_pos[zz,z,p,t] - vH2PipeFlow_neg[zz,z,p,t] )

	# 	                if z==zz # Eliminating variables where source and sink are the same
	# 	                	@constraint(EP, vH2PipeFlow[zz,z,p,t] == 0 )
	# 	                end

	# 					# Modeling line pack storage in pipelines
	# 	                if h > 1
	# 	                @constraint(EP, vH2PipeLevel[zz,z,p,t] == vH2PipeLevel[zz,z,p,t-1] - vH2PipeFlow[zz,z,p,t] - vH2PipeFlow[z,zz,p,t])
	# 	                else
	# 	                    @constraint(EP, vH2PipeLevel[zz,z,p,t] == vH2PipeLevel[zz,z,p,tw_max] - vH2PipeFlow[zz,z,p,t] - vH2PipeFlow[z,zz,p,t])
	# 	                end
	# 					# Line pack storage has to be above some minimum level
	# 	                @constraint(EP, vH2PipeLevel[zz,z,p,t] >= rhoH2PipeCap_min[zz,z,p] * H2PipeCap[p] * vH2NPipe[zz,z,p])
	# 	                @constraint(EP, H2PipeCap[p] * vH2NPipe[zz,z,p] >= vH2PipeLevel[zz,z,p,t])

	# 					# Line pack is symmetric
	# 	                @constraint(EP, vH2NPipe[zz,z,p] == vH2NPipe[z,zz,p])
	# 	                @constraint(EP, vH2PipeLevel[zz,z,p,t] == vH2PipeLevel[z,zz,p,t])
	# 	                # @constraint(EP, vH2PipeFlowSize[zz,z,p] == vH2PipeFlowSize[z,zz,p])
	# 	            end
	# 	        end
	# 	    end
	# 	end
	# end

	return EP
end # end H2Pipeline module
