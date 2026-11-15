function ethylene_plants_decommissioning(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Ethylene Plants Decommissioning modeule")


    ## step 1: load the saved information
	# Greenfield projects:

    dfEthylene_plants = inputs["dfEthylene_plants"]
	Ethylene_Plants_ALL = inputs["Ethylene_Plants_ALL"]

	Decomm_Cost_MM = dfEthylene_plants[!,:Decomm_Cost_MM] # $MM
    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	

    MinimumFossil = setup["MinimumFossil"]
    # Add binary decision variables for the plants
    #@variable(EP, vEthylene_PlantStatus[k = 1:Ethylene_Plants_ALL], Bin)  # Binary variables (1 or 0)

    @variable(EP, MinimumFossil <= vEthylene_PlantStatus[k = 1:Ethylene_Plants_ALL] <= 1)  # Continous variables (1 or 0)
    EP[:vEthylene_PlantStatus] = vEthylene_PlantStatus


    # Add constraints to enforce production and input variables to zero if a plant is decommissioned
#    @constraints(EP, begin
#    [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] <= EP[:vEthylene_PlantStatus][k]*123 end)  # 123 is plant production capacity
	@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] <= EP[:vEthylene_PlantStatus][k] * dfEthylene_plants[!,:Ethylene_Capacity_t_p_hr][k] end)
#
	@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] >= EP[:vEthylene_PlantStatus][k] * dfEthylene_plants[!,:MinEthylene_Production_t_p_hr][k] end)
	
    #=
    [k in 1:Ethylene_Plants_ALL, t = 1:T], vEthylene_ethanein_EP[k, t] <= vEthylene_PlantStatus[k] * 1e6
    [k in 1:Ethylene_Plants_ALL, t = 1:T], vEthylene_ethanolin_EP[k, t] <= vEthylene_PlantStatus[k] * 1e6
    [k in 1:Ethylene_Plants_ALL, t = 1:T], vEthylene_CO2in_EP[k, t] <= vEthylene_PlantStatus[k] * 1e6
    [k in 1:Ethylene_Plants_ALL, t = 1:T], vEthylene_Powerin_EP[k, t] <= vEthylene_PlantStatus[k] * 1e6
    [k in 1:Ethylene_Plants_ALL, t = 1:T], vEthylene_NGin_EP[k, t] <= vEthylene_PlantStatus[k] * 1e6
 
    @variable(EP,vDecommCost_per_type_EP[i in 1:Ethylene_Plants_ALL]>=0) #Capacity of units in ethylene tonnes/hr
    @expression(EP,eDecommCost_per_type_EP[i in 1:Ethylene_Plants_ALL], (1 - EP[:vEthylene_PlantStatus][i]) * Decomm_Cost_MM[i]*1e6)
    @expression(EP,eDecommCost_total_EP, sum(EP[:eDecommCost_per_type_EP][i] for i in 1:Ethylene_Plants_ALL))
    EP[:eObj] += EP[:eDecommCost_total_EP]

    =#


    


    return EP

end

