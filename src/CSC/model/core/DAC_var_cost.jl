

@doc raw"""
	DAC_var_cost(EP::Model, inputs::Dict, setup::Dict)

Sets up variables common to all direct air capture (DAC) resources.

This module defines the DAC decision variable $x_{d,z,t}^{\textrm{C,DAC}} \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing CO2 injected into the grid by DAC resource $d$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vDAC\textunderscore{CO2}\textunderscore{Captured}``` covers all variables $x_{d,z,t}^{\textrm{C,DAC}}$.


**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM plus fuel cost) from all resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{C,DAC,o}} = \sum_{d \in \mathcal{K}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{d}^{\textrm{DAC,VOM}} + \textrm{c}_{d}^{\textrm{DAC,FUEL}}\right) \times x_{d,z,t}^{\textrm{C,DAC}}
\end{equation*}
```
"""
function DAC_var_cost(EP::Model, inputs::Dict, setup::Dict)

	println("DAC variable cost module")

    dfDAC = inputs["dfDAC"]
	DAC_RES_ALL = inputs["DAC_RES_ALL"]

	#Define sets
	T = inputs["T"]::Int     # Number of time steps (hours)

	#####################################################################################################################################
	##Variables
	#CO2 captured from carbon capture resource k (tonnes of CO2/hr) in time t
	@variable(EP, vDAC_CO2_Captured[k=1:DAC_RES_ALL, t = 1:T] >= 0 )

	#Power required by carbon capture resource k (MW)
	@variable(EP, vPower_DAC[k=1:DAC_RES_ALL, t = 1:T] >= 0 )

	#Power produced by carbon capture resource k (MW)
	@variable(EP, vPower_Produced_DAC[k=1:DAC_RES_ALL, t = 1:T] >= 0 )

	#####################################################################################################################################
	##Expressions
	if setup["ParameterScale"] ==1
		# NOTE: When Setup[ParameterScale] =1, fuel costs are scaled in fuels_data.csv, so no if condition needed to scale fuel cost of DAC
		@expression(EP,eVar_OM_DAC_per_type_per_time[k=1:DAC_RES_ALL, t = 1:T], inputs["omega"][t] * (dfDAC[!,:Var_OM_Cost_per_tonne][k]/ModelScalingFactor^2 + dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * inputs["fuel_costs"][dfDAC[!,:Fuel][k]][t]) * EP[:vDAC_CO2_Captured][k,t] )
	else
		@expression(EP,eVar_OM_DAC_per_type_per_time[k=1:DAC_RES_ALL, t = 1:T], inputs["omega"][t] * (dfDAC[!,:Var_OM_Cost_per_tonne][k] + dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * inputs["fuel_costs"][dfDAC[!,:Fuel][k]][t]) * EP[:vDAC_CO2_Captured][k,t] )
	end

	#Total variable cost per resource type
	@expression(EP, eVar_OM_DAC_per_time[t=1:T], sum(EP[:eVar_OM_DAC_per_type_per_time][k,t] for k in 1:DAC_RES_ALL))
	
	@expression(EP, eVar_OM_DAC_per_type[k=1:DAC_RES_ALL], sum(EP[:eVar_OM_DAC_per_type_per_time][k,t] for t in 1:T))

	@expression(EP, eVar_OM_DAC, sum(EP[:eVar_OM_DAC_per_time][t] for t in 1:T))

	# Add total variable cost contribution to the objective function
	add_similar_to_expression!(EP[:eObj], EP[:eVar_OM_DAC])

	return EP

end
