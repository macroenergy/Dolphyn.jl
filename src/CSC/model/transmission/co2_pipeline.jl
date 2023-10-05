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


function co2_pipeline(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Pipeline Module")

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity but not CO2

    ##### New - Code Added Here ####
    S = inputs["S"] # Number of CO2 Storage Sites



    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    # Number of Trunk and Spur Pipelines
    Trunk_CO2_P = inputs["Trunk_CO2_P"]
    Spur_CO2_P = inputs["Spur_CO2_P"]
    
    # Specifying Trunk and Spur CO2 Pipe Map
    CO2_Trunk_Pipe_Map = inputs["CO2_Trunk_Pipe_Map"]
    CO2_Spur_Pipe_Map = inputs["CO2_Spur_Pipe_Map"]

    #### NEW Code: From the CO2_Pipe_Map infering Source_CO2_Pipe_Map and Sink_CO2_Pipe_Map based on the directionality element ########
    Source_CO2_Spur_Pipe_Map = CO2_Spur_Pipe_Map[CO2_Spur_Pipe_Map.d .== 1, :]
    Sink_CO2_Spur_Pipe_Map = CO2_Spur_Pipe_Map[CO2_Spur_Pipe_Map.d .== -1, :]
    
    # Variable for Number of Pipelines for Trunk and Spur
    @variable(EP, vCO2NPipe_Trunk[p=1:Trunk_CO2_P] >= 0)
    @variable(EP, vCO2NPipe_Spur[p=1:Spur_CO2_P] >= 0)

    # Variable for PipeLevel Trunk and Spur (For Storage in Pipe)
    @variable(EP, vCO2PipeLevel_Trunk[p=1:Trunk_CO2_P, t = 1:T] >= 0)
    @variable(EP, vCO2PipeLevel_Spur[p=1:Spur_CO2_P, t = 1:T] >= 0)

    # Variable for Pipe Flow Positive Direction (Specifying Inflow into a zone)
    # Trunk Pipeline
    @variable(EP, vCO2PipeFlow_trunk_pos[p=1:Trunk_CO2_P, t = 1:T, d = [1,-1]] >= 0)

    # Spur Pipeline
    @variable(EP, vCO2PipeFlow_spur_uni_pos[p=1:Spur_CO2_P, t = 1:T] >=0 )

    # Variable for Outflow from Zones through Pipes
    # Trunk Pipeline
    @variable(EP, vCO2PipeFlow_trunk_neg[p=1:Trunk_CO2_P, t = 1:T, d = [1,-1]] >= 0) #negative pipeflow

    # Spur Pipeline
    @variable(EP, vCO2PipeFlow_spur_uni_neg[p=1:Spur_CO2_P, t = 1:T] >= 0) # New Uni-directional variable

    # Variable for CO2 Loss Across time period and zones for Trunk and Spur Pipelines
    # Trunk Pipeline
    @variable(EP, vCO2Loss_trunk[t=1:T,z=1:Z] >= 0 )

    # Spur Pipeline
    @variable(EP, vCO2Loss_spur[t=1:T,z=1:Z] >= 0 )

	### Expressions ###
    #Calculate the number of new trunk and spur pipelines
    # Trunk Pipeline
    @expression(EP, eCO2NPipeNew_trunk[p = 1:Trunk_CO2_P], vCO2NPipe_Trunk[p] - inputs["Trunk_pCO2_Pipe_No_Curr"][p])

    # Spur Pipeline
    @expression(EP, eCO2NPipeNew_spur[p = 1:Spur_CO2_P], vCO2NPipe_Spur[p] - inputs["Spur_pCO2_Pipe_No_Curr"][p])

	## Objective Function Expressions ##
	# Capital cost of pipelines 
    #  ParameterScale = 1 --> objective function is in million $
	#  ParameterScale = 0 --> objective function is in $

    if setup["ParameterScale"] ==1 
        @expression(EP, eCCO2Pipe_Trunk,  sum(eCO2NPipeNew_trunk[p] * inputs["Trunk_pCAPEX_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:Trunk_CO2_P) + sum(vCO2NPipe_Trunk[p] * inputs["Trunk_pFixed_OM_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:Trunk_CO2_P))
        @expression(EP, eCCO2Pipe_Spur,  sum(eCO2NPipeNew_spur[p] * inputs["Spur_pCAPEX_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:Spur_CO2_P) + sum(vCO2NPipe_Spur[p] * inputs["Spur_pFixed_OM_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:Spur_CO2_P))
    else
        @expression(EP, eCCO2Pipe_Trunk,  sum(eCO2NPipeNew_trunk[p] * inputs["Trunk_pCAPEX_CO2_Pipe"][p] for p = 1:Trunk_CO2_P) + sum(vCO2NPipe_Trunk[p] * inputs["Trunk_pFixed_OM_CO2_Pipe"][p] for p = 1:Trunk_CO2_P))
        @expression(EP, eCCO2Pipe_Spur,  sum(eCO2NPipeNew_spur[p] * inputs["Spur_pCAPEX_CO2_Pipe"][p] for p = 1:Spur_CO2_P) + sum(vCO2NPipe_Spur[p] * inputs["Spur_pFixed_OM_CO2_Pipe"][p] for p = 1:Spur_CO2_P))
    end

    EP[:eObj] += eCCO2Pipe_Trunk
    EP[:eObj] += eCCO2Pipe_Spur

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    #  ParameterScale = 1 --> objective function is in million $
	#  ParameterScale = 0 --> objective function is in $
	
    if setup["ParameterScale"] ==1 
        @expression(EP, eCCO2CompPipe_trunk, sum(eCO2NPipeNew_trunk[p] * inputs["Trunk_pCAPEX_Comp_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:Trunk_CO2_P))
        @expression(EP, eCCO2CompPipe_spur, sum(eCO2NPipeNew_spur[p] * inputs["Spur_pCAPEX_Comp_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:Spur_CO2_P))
    else
        @expression(EP, eCCO2CompPipe_trunk, sum(eCO2NPipeNew_trunk[p] * inputs["Trunk_pCAPEX_Comp_CO2_Pipe"][p] for p = 1:Trunk_CO2_P))
        @expression(EP, eCCO2CompPipe_spur, sum(eCO2NPipeNew_spur[p] * inputs["Spur_pCAPEX_Comp_CO2_Pipe"][p] for p = 1:Spur_CO2_P))
    end

    EP[:eObj] += eCCO2CompPipe_trunk
    EP[:eObj] += eCCO2CompPipe_spur

	## End Objective Function Expressions ##

	## Balance Expressions ##
	# Electrical energy requirement for pipeline operation
    # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, , no need to scale as MW/ton = GW/kton
    # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption

    @expression(EP, ePowerDemandCO2Pipe_Trunk[t=1:T, z=1:Z],
    sum(vCO2PipeFlow_trunk_neg[p,t,CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["Trunk_pMWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no])) 

    @expression(EP, ePowerDemandCO2Pipe_Spur[t=1:T, z=1:Z],
    sum(vCO2PipeFlow_spur_uni_neg[p,t] * inputs["Spur_pMWh_per_tonne_CO2_Pipe"][p] for  p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

    @expression(EP, ePowerDemandCO2Pipe_Trunk_zt[z=1:Z, t=1:T],
    sum(vCO2PipeFlow_trunk_neg[p,t,CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["Trunk_pMWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

    @expression(EP, ePowerDemandCO2Pipe_Spur_zt[z=1:Z, t=1:T],
    sum(vCO2PipeFlow_spur_uni_neg[p,t] * inputs["Spur_pMWh_per_tonne_CO2_Pipe"][p] for  p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    


	# Electrical energy requirement for booster compression
    # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, , no need to scale as MW/ton = GW/kton
    # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption
    
    @expression(EP, ePowerDemandCO2PipeCompression_Trunk[t=1:T, z=1:Z],
    sum(vCO2PipeFlow_trunk_neg[p,t,CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["Trunk_pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    
    
    @expression(EP, ePowerDemandCO2PipeCompression_Spur[t=1:T, z=1:Z],
    sum(vCO2PipeFlow_spur_uni_neg[p,t] * inputs["Spur_pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    
    
    @expression(EP, ePowerDemandCO2PipeCompression_Trunk_zt[z=1:Z,t=1:T],
    sum(vCO2PipeFlow_trunk_neg[p,t,CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["Trunk_pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

    @expression(EP, ePowerDemandCO2PipeCompression_Spur_zt[z=1:Z, t=1:T],
    sum(vCO2PipeFlow_spur_uni_neg[p,t] * inputs["Spur_pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))   
    
    #EP[:ePowerBalance] -= ePowerDemandCO2Pipe
    ### NEW Expression Declared ####
    EP[:ePowerBalance] -= ePowerDemandCO2Pipe_Trunk
    EP[:ePowerBalance] -= ePowerDemandCO2Pipe_Spur
    
    #EP[:ePowerBalance] -= ePowerDemandCO2PipeCompression
    ### NEW Expression Declared ###
    EP[:ePowerBalance] -= ePowerDemandCO2PipeCompression_Trunk
    EP[:ePowerBalance] -= ePowerDemandCO2PipeCompression_Spur

    #EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2Pipe
    ### NEW Expression Declared ###
    EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2Pipe_Trunk
    EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2Pipe_Spur


    #EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2PipeCompression
    ### NEW Expression Declared ###
    EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2PipeCompression_Trunk
    EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2PipeCompression_Spur


	### Constraints ###

    # Constraints
    if setup["CO2PipeInteger"] == 1
        for p=1:Trunk_CO2_P
            set_integer.(vCO2NPipe_Trunk[p])
        end
        for p = 1:Spur_CO2_P
            set_integer.(vCO2NPipe_Spur[p])
        end
    end

    # Modeling expansion of the pipleline network
    if setup["CO2NetworkExpansion"]==1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
        @constraint(EP, cCO2NetworkExpansion_Trunk[p in 1:Trunk_CO2_P], EP[:eCO2NPipeNew_trunk][p] >= 0)
        @constraint(EP, cCO2NetworkExpansion_Spur[p in 1:Spur_CO2_P], EP[:eCO2NPipeNew_spur][p] >= 0 )
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
        @constraint(EP, cCO2NetworkExpansion_Trunk[p in 1:Trunk_CO2_P], EP[:eCO2NPipeNew_trunk][p] == 0)
        @constraint(EP, cCO2NetworkExpansion_Spur[p in 1:Spur_CO2_P], EP[:eCO2NPipeNew_spur][p] == 0 )
    end

    if setup["CO2Pipeline_Loss"] == 1
        # If modeling CO2 Loss from Pipe: For Trunk Pipelines
        @expression(EP, eCO2Loss_Pipes_per_pipe_Trunk[t=1:T,z=1:Z], sum(vCO2PipeFlow_trunk_neg[p,t,CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["Trunk_pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        @expression(EP, eCO2Loss_Pipes_Trunk[t=1:T,z=1:Z], sum(vCO2PipeFlow_trunk_neg[p,t,CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["Trunk_pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        @expression(EP, eCO2Loss_Pipes_Trunk_zt[z=1:Z,t=1:T], sum(vCO2PipeFlow_trunk_neg[p,t,CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["Trunk_pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        
        # If modeling CO2 Loss from Pipe: For Spur Pipelines
        @expression(EP, eCO2Loss_Pipes_per_pipe_Spur[t=1:T,z=1:Z], sum(vCO2PipeFlow_spur_uni_neg[p,t] * inputs["Spur_pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        @expression(EP, eCO2Loss_Pipes_Spur[t=1:T,z=1:Z], sum(vCO2PipeFlow_spur_uni_neg[p,t] * inputs["Spur_pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        @expression(EP, eCO2Loss_Pipes_Spur_zt[z=1:Z,t=1:T], sum(vCO2PipeFlow_spur_uni_neg[p,t] * inputs["Spur_pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
    else
        # If not modeling CO2 Loss from Pipes
        # Trunk Pipelines
        @expression(EP, eCO2Loss_Pipes_Trunk[t=1:T,z=1:Z], 0)
        @expression(EP, eCO2Loss_Pipes_Trunk_zt[z=1:Z,t=1:T], 0)
        # Spur Pipelines
        @expression(EP, eCO2Loss_Pipes_Spur[t=1:T,z=1:Z], 0)
        @expression(EP, eCO2Loss_Pipes_Spur_zt[z=1:Z,t=1:T], 0)
    end

    #Calculate net flow at each pipe-zone interfrace
    @expression(EP, eCO2PipeFlow_Trunk_net[p = 1:Trunk_CO2_P, t = 1:T, d = [-1,1]],  vCO2PipeFlow_trunk_pos[p,t,d] - vCO2PipeFlow_trunk_neg[p,t,d]*(1-inputs["Trunk_pLoss_tonne_per_tonne_CO2_Pipe"][p]))

    @expression(EP, eCO2PipeFlow_Spur_net[p = 1:Spur_CO2_P, t = 1:T],  vCO2PipeFlow_spur_uni_pos[p,t] - vCO2PipeFlow_spur_uni_neg[p,t]*(1-inputs["Spur_pLoss_tonne_per_tonne_CO2_Pipe"][p]))

    # Specifying Expression for CO2 Outflows in Spur Pipelines
    @expression(EP, eCO2PipeOutFlow_Spur[p=1:Spur_CO2_P, t = 1:T], vCO2PipeFlow_spur_uni_neg[p,t])




    # CO2 balance - net flows of CO2 from between z and zz via pipeline p over time period t

    @expression(EP, ePipeZoneCO2Demand_No_Loss_Trunk[t=1:T,z=1:Z],
    sum(eCO2PipeFlow_Trunk_net[p,t, CO2_Trunk_Pipe_Map[(CO2_Trunk_Pipe_Map[!,:Zone] .== z) .& (CO2_Trunk_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] for p in CO2_Trunk_Pipe_Map[CO2_Trunk_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))

    @expression(EP, ePipeZoneCO2Demand_Trunk[t=1:T,z=1:Z],ePipeZoneCO2Demand_No_Loss_Trunk[t,z] - eCO2Loss_Pipes_Trunk[t,z])

    # Specifying CO2 Balance for Spur Pipelines
    @expression(EP, ePipeZoneCO2OutFlowDemand_No_Loss_Spur[t=1:T,z=1:Z],
    sum(eCO2PipeOutFlow_Spur[p,t] for p in Source_CO2_Spur_Pipe_Map[Source_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))

    @expression(EP, ePipeZoneCO2Demand_Outflow_Spur[t=1:T,z=1:Z], ePipeZoneCO2OutFlowDemand_No_Loss_Spur[t,z] - eCO2Loss_Pipes_Spur[t,z])

    ##### NOTE: If we do want to account for losses they can be tracked in a new expression as follows ########
    ### New Expression ###
    @expression(EP, eCO2PipeInFlow_Spur[p=1:Spur_CO2_P, t = 1:T], vCO2PipeFlow_spur_uni_neg[p,t] * (1 - inputs["Spur_pLoss_tonne_per_tonne_CO2_Pipe"][p]))


    # Specifying expression for Pipe Zone CO2 Inflow Demand while ignoring losses
    @expression(EP, ePipeZoneCO2InFlowDemand_No_Loss_Spur[t=1:T,z=1:S],
    sum(eCO2PipeOutFlow_Spur[p,t] for p in Sink_CO2_Spur_Pipe_Map[Sink_CO2_Spur_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))

    @expression(EP, ePipeZoneCO2Demand_Inflow_Spur[t=1:T,z=1:S], ePipeZoneCO2InFlowDemand_No_Loss_Spur[t,z])

    #### Adding a new expression here to be used later in co2_injection script ####
    EP[:ePipeZoneCO2Demand_Inflow_Spur] = ePipeZoneCO2Demand_Inflow_Spur

    # Summing total outflow across all zones for outflow

    @expression(EP, eTotalOutflowAcrossZones_Spur[t=1:T],
    sum(ePipeZoneCO2OutFlowDemand_No_Loss_Spur[t,z] for z in 1:Z))



    #### Declaring New Expression for Summing total outflow across all sites for Inflow ####
    @expression(EP, eTotalInflowAcrossSites_Spur[t=1:T],
    sum(ePipeZoneCO2InFlowDemand_No_Loss_Spur[t,s] for s in 1:S))
    
    # CO2 balance - net flows of CO2 from between z and zz via pipeline p over time period t
    #@expression(EP, ePipeZoneCO2Demand[t=1:T,z=1:Z],ePipeZoneCO2Demand_No_Loss[t,z] - eCO2Loss_Pipes[t,z])

    ##### SPECIFYING ePipeZoneCO2Demand in terms of the outflow ######
    ### New Expression here for Outflow == CO2 Captured ###
    #@expression(EP, ePipeZoneCO2Demand_Outflow[t=1:T,z=1:Z], ePipeZoneCO2OutFlowDemand_No_Loss[t,z] - eCO2Loss_Pipes[t,z])

    

    #### UPDATING THE BALANCING CONSTRAINT ####
    #EP[:eCaptured_CO2_Balance] += ePipeZoneCO2Demand

    ### NEW CONSTRAINT DEFINED AS ###
    #EP[:eCaptured_CO2_Balance] -= ePipeZoneCO2Demand_Outflow

    ### NEW CONSTRAINT DEFINED AS ###
    EP[:eCaptured_CO2_Balance] -= inputs["CO2_D"]
    EP[:eCaptured_CO2_Balance] += ePipeZoneCO2Demand_Trunk
    EP[:eCaptured_CO2_Balance] -= ePipeZoneCO2Demand_Outflow_Spur


    ### Adding Constraints on PipeLevel and PipeFlows ###

    if setup["ParameterScale"] == 1
        # Pipe Flow Constraint: Trunk Pipelines
        @constraint(EP, cMinCO2Pipeflow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], EP[:eCO2PipeFlow_Trunk_net][p,t,d] >= -EP[:vCO2NPipe_Trunk][p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p]/ModelScalingFactor)
        @constraint(EP, cMaxCO2Pipeflow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], EP[:eCO2PipeFlow_Trunk_net][p,t,d] <= EP[:vCO2NPipe_Trunk][p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p]/ModelScalingFactor)
        # Constrain positive and negative pipe flows for Trunk Pipelines
        @constraint(EP, cMaxPositiveCO2Flow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], vCO2NPipe_Trunk[p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_trunk_pos[p,t,d]/ModelScalingFactor)
        @constraint(EP, cMaxNegativeCO2Flow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], vCO2NPipe_Trunk[p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_trunk_neg[p,t,d]/ModelScalingFactor)
        
        # Pipe Level Constraint: Trunk Pipelines
        @constraint(EP, cMinCO2PipeLevel_Trunk[p in 1:Trunk_CO2_P, t=1:T], vCO2PipeLevel_Trunk[p,t] >= inputs["Trunk_pCO2_Pipe_Min_Cap"][p] * vCO2NPipe_Trunk[p]/ModelScalingFactor)
        @constraint(EP, cMaxCO2PipeLevel_Trunk[p in 1:Trunk_CO2_P, t=1:T], vCO2PipeLevel_Trunk[p,t] <= inputs["Trunk_pCO2_Pipe_Max_Cap"][p] * vCO2NPipe_Trunk[p]/ModelScalingFactor)
        
        # Pipe Flow Constraint: Spur Pipeline
        @constraint(EP, cMinCO2Pipeflow_Spur[p in 1:Spur_CO2_P, t=1:T], EP[:eCO2PipeOutFlow_Spur][p,t] >= 0)
        @constraint(EP, cMaxCO2Pipeflow_Spur[p in 1:Spur_CO2_P, t=1:T], EP[:eCO2PipeOutFlow_Spur][p,t] <= EP[:vCO2NPipe_Spur][p] * inputs["Spur_pCO2_Pipe_Max_Flow"][p]/ModelScalingFactor)
        @constraint(EP, cMaxCO2OutFlow_Spur[p in 1:Spur_CO2_P, t=1:T], vCO2NPipe_Spur[p] * inputs["Spur_pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_spur_uni_neg[p,t]/ModelScalingFactor)
        
        # Pipe Level Constraint: Spur Pipeline 
        @constraint(EP, cMinCO2PipeLevel_Spur[p in 1:Spur_CO2_P, t=1:T], vCO2PipeLevel_Spur[p,t] >= inputs["Spur_pCO2_Pipe_Min_Cap"][p] * vCO2NPipe_Spur[p]/ModelScalingFactor)
        @constraint(EP, cMaxCO2PipeLevel_Spur[p in 1:Spur_CO2_P, t=1:T], vCO2PipeLevel_Spur[p,t] <= inputs["Spur_pCO2_Pipe_Max_Cap"][p] * vCO2NPipe_Spur[p]/ModelScalingFactor)
    
    else
        # Pipe Flow Constraint: Trunk Pipelines
        @constraint(EP, cMinCO2Pipeflow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], EP[:eCO2PipeFlow_Trunk_net][p,t,d] >= -EP[:vCO2NPipe_Trunk][p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p])
        @constraint(EP, cMaxCO2Pipeflow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], EP[:eCO2PipeFlow_Trunk_net][p,t,d] <= EP[:vCO2NPipe_Trunk][p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p])
        # Constrain positive and negative pipe flows for Trunk Pipelines
        @constraint(EP, cMaxPositiveCO2Flow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], vCO2NPipe_Trunk[p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_trunk_pos[p,t,d])
        @constraint(EP, cMaxNegativeCO2Flow_Trunk[d in [-1,1], p in 1:Trunk_CO2_P, t=1:T], vCO2NPipe_Trunk[p] * inputs["Trunk_pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_trunk_neg[p,t,d])
        
        # Pipe Level Constraint: Trunk Pipelines
        @constraint(EP, cMinCO2PipeLevel_Trunk[p in 1:Trunk_CO2_P, t=1:T], vCO2PipeLevel_Trunk[p,t] >= inputs["Trunk_pCO2_Pipe_Min_Cap"][p] * vCO2NPipe_Trunk[p])
        @constraint(EP, cMaxCO2PipeLevel_Trunk[p in 1:Trunk_CO2_P, t=1:T], vCO2PipeLevel_Trunk[p,t] <= inputs["Trunk_pCO2_Pipe_Max_Cap"][p] * vCO2NPipe_Trunk[p])
    
        # Pipe Flow Constraint: Spur Pipelines
        @constraint(EP, cMinCO2Pipeflow_Spur[p in 1:Spur_CO2_P, t = 1:T], EP[:eCO2PipeOutFlow_Spur][p,t] >= 0 )
        @constraint(EP, cMaxCO2Pipeflow_Spur[p in 1:Spur_CO2_P, t = 1:T], EP[:eCO2PipeOutFlow_Spur][p,t] <= EP[:vCO2NPipe_Spur][p] * inputs["Spur_pCO2_Pipe_Max_Flow"][p])
        # Constraint Positive Outflow value for Spur Pipeline
        @constraint(EP, cMaxCO2OutFlow_Spur[p in 1:Spur_CO2_P, t=1:T], vCO2NPipe_Spur[p] * inputs["Spur_pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_spur_uni_neg[p,t])
        
        # Pipe Level Constraint for Spur Pipelines
        @constraint(EP, cMinCO2PipeLevel_Spur[p in 1:Spur_CO2_P, t=1:T], vCO2PipeLevel_Spur[p,t] >= inputs["Spur_pCO2_Pipe_Min_Cap"][p] * vCO2NPipe_Spur[p])
        @constraint(EP, cMaxCO2PipeLevel_Spur[p in 1:Spur_CO2_P, t=1:T], vCO2PipeLevel_Spur[p,t] <= inputs["Spur_pCO2_Pipe_Max_Cap"][p] * vCO2NPipe_Spur[p])
    end    


    #CO2 Balance in pipe

    # Trunk Pipelines
    @constraint(EP, cCO2PipeBalanceStart_Trunk[p in 1:Trunk_CO2_P, t in START_SUBPERIODS], vCO2PipeLevel_Trunk[p,t] == vCO2PipeLevel_Trunk[p,t + hours_per_subperiod - 1] - eCO2PipeFlow_Trunk_net[p,t, -1] - eCO2PipeFlow_Trunk_net[p,t,1])

    @constraint(EP, cCO2PipeBalanceInterior_Trunk[p in 1:Trunk_CO2_P, t in INTERIOR_SUBPERIODS], vCO2PipeLevel_Trunk[p,t] == vCO2PipeLevel_Trunk[p,t - 1] - eCO2PipeFlow_Trunk_net[p,t, -1] - eCO2PipeFlow_Trunk_net[p,t,1])

    @constraint(EP, cCO2PipesMaxNumber_Trunk[p in 1:Trunk_CO2_P], vCO2NPipe_Trunk[p] <= inputs["Trunk_pCO2_Pipe_No_Max"][p])

    # Spur Pipelines
    #@constraint(EP, cCO2PipeBalanceStart_Spur[p in 1:Spur_CO2_P, t in START_SUBPERIODS], vCO2PipeLevel_Spur[p,t] == vCO2PipeLevel_Spur[p,t + hours_per_subperiod - 1] - eCO2PipeOutFlow_Spur[p,t])

    #@constraint(EP, cCO2PipeBalanceInterior_Spur[p in 1:Spur_CO2_P, t in INTERIOR_SUBPERIODS], vCO2PipeLevel_Spur[p,t] == vCO2PipeLevel_Spur[p,t - 1] - eCO2PipeOutFlow_Spur[p,t])

    @constraint(EP, cCO2PipesMaxNumber_Spur[p in 1:Spur_CO2_P], vCO2NPipe_Spur[p] <= inputs["Spur_pCO2_Pipe_No_Max"][p])

    #@constraint(EP, cCO2PipeBalanceStart[p in 1:CO2_P, t in START_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t + hours_per_subperiod - 1] - eCO2PipeFlow_net[p,t, -1] - eCO2PipeFlow_net[p,t,1])

    #### Adding New Constraint here #####
    #@constraint(EP, cCO2PipeBalanceStart[p in 1:CO2_P, t in START_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t + hours_per_subperiod - 1] - eCO2PipeOutFlow[p,t])

    #@constraint(EP, cCO2PipeBalanceInterior[p in 1:CO2_P, t in INTERIOR_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t - 1] - eCO2PipeFlow_net[p,t, -1] - eCO2PipeFlow_net[p,t,1])
    ##### Adding New Constraint Here #####
    #@constraint(EP, cCO2PipeBalanceInterior[p in 1:CO2_P, t in INTERIOR_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t - 1] - eCO2PipeOutFlow[p,t])

    ##### WORKS FOR SPUR LINES ##############
    #@constraint(EP, cCO2PipesMaxNumber[p in 1:CO2_P], vCO2NPipe[p] <= inputs["pCO2_Pipe_No_Max"][p])

    ###### Adding a New Constraint on CO2 Inflow == CO2_Stored #####
    #EP[:eCO2Store_Flow_Balance] += ePipeZoneCO2Demand_Inflow
    
    EP[:eCO2Store_Flow_Balance] += ePipeZoneCO2Demand_Inflow_Spur

	return EP
end