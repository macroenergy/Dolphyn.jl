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
    write_Power_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
"""
function write_Power_balance_zone(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
# function write_Power_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)


	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
    THERM_NO_COMMIT = inputs["THERM_NO_COMMIT"]
    # H2_G2P_NO_COMMIT = inputs["H2_G2P_NO_COMMIT"]
    H2_G2P_NO_COMMIT = haskey(inputs, "H2_G2P_NO_COMMIT") ? inputs["H2_G2P_NO_COMMIT"] : []

    if setup["ModelH2Liquid"] ==1
        H2_GEN_COMMIT = union(inputs["H2_GEN_COMMIT"], inputs["H2_LIQ_COMMIT"], inputs["H2_EVAP_COMMIT"])
        H2_GEN_NO_COMMIT = union(inputs["H2_GEN_NO_COMMIT"], inputs["H2_LIQ_NO_COMMIT"], inputs["H2_EVAP_NO_COMMIT"])
    else
        H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
        H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
    end
	
	dfCost = DataFrame(Costs = ["Ethylene", "Bio_Electricity","Bio H2 Consumption","Bio H2 Production","Bio LF Consumption","Bio LF Production","Bio NG Consumption","Bio NG Production","CSC DAC Consumption","CSC DAC Production","CSC Injection Consumption","CSC Pipeline Operation","CSC Pipe Booster Comp","Non-served Power","Power losses by zone","Net export flows losses","Controllable variable renewable Power","Flexible Demand Resources","Hydro Reservoir","Must-Run Resources","Storage Core Resources","Thermal (Unit Commitment) Resources","Thermal (No Unit Commitment) Resources",
"H2G2P Commit","H2G2P No Commit","H2 Production (Unit Commitment)","H2 Production (No Unit Commitment)","H2 Storage Core Resources", "H2 Pipeline Compression","H2 Truck Compression","H2 Truck Travel","Synthetic Fuels Resources","Synthetic NG Resources","NG Pipeline","Total","Ethylene Comb.","Ethylene Co-Prod. Comb."])

	#Try this form of summing otherwise just create z dimensions and sum later

    if setup["ModelEthyleneProduction"] == 1 
		Chemical_Ethylene =  - sum(sum(inputs["omega"].* value.(EP[:eEthylene_Power_RES])[:,z] for z in 1:Z))-sum(sum(inputs["omega"].* value.(EP[:eEthylene_Power_Plant])[:,z] for z in 1:Z))
	else
		Chemical_Ethylene = 0 
	end

    if setup["ModelEthyleneEndOfLife"] == 1 
		Ethylene_Combustion =  sum(sum(inputs["omega"].* value.(EP[:eEthylene_PowerRecoveryEthylene_RES])[:,z] for z in 1:Z)) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_RecoveryEthylene_Plant])[:,z] for z in 1:Z))
	    EthyleneCo_Prod_Combustion =  sum(sum(inputs["omega"].* value.(EP[:eEthylene_PowerRecoveryCoProducts_RES])[:,z] for z in 1:Z)) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_RecoveryCoProducts_Plant])[:,z] for z in 1:Z))
    else
		Ethylene_Combustion = 0 
        EthyleneCo_Prod_Combustion = 0
	end


    if setup["ModelBESC"] == 1 && setup["Bio_ELEC_On"] == 1
		Bio_Electricity = sum(sum(inputs["omega"].* (value.(EP[:eBioELEC_produced_MWh_per_time_per_zone])[:,z])) for z in 1:Z)
	else
		Bio_Electricity = 0
	end

    if setup["ModelBESC"] == 1 && setup["Bio_H2_On"] == 1
		Bio_Hydrogen_Cons = - sum(sum(inputs["omega"].* (value.(EP[:eBio_H2_Plant_Power_consumption_per_time_per_zone])[:,z])) for z in 1:Z)
        Bio_Hydrogen_Prod = sum(sum(inputs["omega"].* (value.(EP[:eBioH2_Power_credit_produced_MWh_per_time_per_zone])[:,z])) for z in 1:Z)
    else
		Bio_Hydrogen_Cons = 0
        Bio_Hydrogen_Prod = 0
	end

    if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
		Bio_LF_Cons = - sum(sum(inputs["omega"].* (value.(EP[:eBio_LF_Plant_Power_consumption_per_time_per_zone])[:,z])) for z in 1:Z)
        Bio_LF_Prod = sum(sum(inputs["omega"].* (value.(EP[:eBioLF_Power_credit_produced_MWh_per_time_per_zone])[:,z])) for z in 1:Z)
    else
		Bio_LF_Cons = 0
        Bio_LF_Prod = 0
	end

    if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
		Bio_NG_Cons = - sum(sum(inputs["omega"].* (value.(EP[:eBio_NG_Plant_Power_consumption_per_time_per_zone])[:,z])) for z in 1:Z)
        Bio_NG_Prod = sum(sum(inputs["omega"].* (value.(EP[:eBioNG_Power_credit_produced_MWh_per_time_per_zone])[:,z])) for z in 1:Z)
    else
		Bio_NG_Cons = 0
        Bio_NG_Prod = 0
	end

    if setup["ModelBESC"] == 1 && setup["Bio_Ethanol_On"] == 1
		Bio_Ethanol_Cons = - sum(sum(inputs["omega"].* (value.(EP[:eBio_Ethanol_Plant_Power_consumption_per_time_per_zone])[:,z])) for z in 1:Z)
        Bio_Ethanol_Prod = sum(sum(inputs["omega"].* (value.(EP[:eBioEthanol_Power_credit_produced_MWh_per_time_per_zone])[:,z])) for z in 1:Z)
    else
		Bio_Ethanol_Cons = 0
        Bio_Ethanol_Prod = 0
	end

    if setup["ModelCSC"] == 1 
		CSC_DAC_Cons = - sum(sum(inputs["omega"].* (value.(EP[:ePower_Balance_DAC])[:,z])) for z in 1:Z)
        CSC_DAC_Prod = sum(sum(inputs["omega"].* (value.(EP[:ePower_Produced_Balance_DAC])[:,z])) for z in 1:Z)
    else
		CSC_DAC_Cons = 0
        CSC_DAC_Prod = 0
	end

    if setup["ModelCSC"] == 1 && setup["ModelCO2Storage"] == 1
		CSC_Inj_Cons = - sum(sum(inputs["omega"].* (value.(EP[:ePower_Balance_CO2_Storage])[:,z])) for z in 1:Z)
    else
		CSC_Inj_Cons = 0
	end

    if setup["ModelCSC"] == 1 && setup["ModelCO2Pipelines"] == 1
		CSC_Pipe_Operation = - sum(sum(inputs["omega"].* (value.(EP[:ePowerDemandCO2Pipe])[:,z])) for z in 1:Z)
        CSC_Booster_Compression = - sum(sum(inputs["omega"].* (value.(EP[:ePowerDemandCO2PipeCompression])[:,z])) for z in 1:Z)
    else
		CSC_Pipe_Operation = 0
        CSC_Booster_Compression = 0
	end

    Nonserved_Power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceNse])[:,z] for z in 1:Z))
    LossesbyZone_Power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceLossesByZone])[:,z] for z in 1:Z))
    NetExportFlowsLoss_Power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceNetExportFlows])[:,z] for z in 1:Z))
    CVR_power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceDisp])[:,z] for z in 1:Z))
    if !isempty(inputs["FLEX"])
        FDR_power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceDemandFlex])[:,z] for z in 1:Z))
    else
        FDR_power = 0
    end
    
    HydroRes_power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceHydroRes])[:,z] for z in 1:Z))
    MustRun_power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceNdisp])[:,z] for z in 1:Z))
    SCR_power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceStor])[:,z] for z in 1:Z))
    TUCR_power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceThermCommit])[:,z] for z in 1:Z))

    if !isempty(THERM_NO_COMMIT)
		TNUCR_power = sum(sum(inputs["omega"].* value.(EP[:ePowerBalanceThermNoCommit])[:,z] for z in 1:Z))
    else
        TNUCR_power = 0
	end

    

    if setup["ModelH2"] == 1 && setup["ModelH2G2P"] == 1
		H2G2PCommit_Power = sum(sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2G2PCommit])[:,z])) for z in 1:Z)
        if !isempty(H2_G2P_NO_COMMIT)
            H2G2PNoCommit_Power = sum(sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2G2PNoCommit])[:,z])) for z in 1:Z)
        else
            H2G2PNoCommit_Power = 0
        end
        
    else
		H2G2PCommit_Power  = 0
        H2G2PNoCommit_Power  = 0
	end

    if setup["ModelH2"] == 1 && !isempty(H2_GEN_COMMIT)
		H2PUC_Power = - sum(sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2GenCommit])[:,z])) for z in 1:Z)
    else
		H2PUC_Power  = 0
       
	end

    if setup["ModelH2"] == 1 
		H2PNUC_Power = - sum(sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2GenNoCommit])[:,z])) for z in 1:Z)
        H2SCR_Power = - sum(sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2Stor])[:,z])) for z in 1:Z)
        H2PC_Power = - sum(sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2PipeCompression])[:,z])) for z in 1:Z)
    else
		H2PNUC_Power  = 0
        H2SCR_Power = 0
        H2PC_Power = 0       
	end

    if setup["ModelH2"] == 1 && setup["ModelH2Trucks"] == 1
		H2TC_Power = - sum(sum(inputs["omega"].* (value.(EP[:ePowerbalanceH2TruckCompression])[:,z])) for z in 1:Z)
    	H2TT_Power = - sum(sum(inputs["omega"].* (value.(EP[:ePowerbalanceH2TruckTravel])[:,z])) for z in 1:Z)
    else
		H2TC_Power  = 0
        H2TT_Power = 0       
	end

    if setup["ModelLFSC"] == 1 && setup["ModelSyntheticFuels"] == 1
		H2SF_Power = - sum(sum(inputs["omega"].* (value.(EP[:eSyn_Fuel_Power_Cons])[:,z])) for z in 1:Z)
    else
		H2SF_Power = 0
   
	end

    if setup["ModelNGSC"] == 1 && setup["ModelSyntheticNG"] == 1
		H2SNG_Power = - sum(sum(inputs["omega"].* (value.(EP[:eSyn_NG_Power_Cons])[:,z])) for z in 1:Z)
    else
		H2SNG_Power = 0   
	end

    if setup["ModelNGSC"] == 1 && setup["ModelNGPipelines"] == 1
		H2NGP_Power = - sum(sum(inputs["omega"].* (value.(EP[:ePowerBalanceNGPipeCompression])[:,z])) for z in 1:Z)
    else
		H2NGP_Power = 0   
	end


	# Define total costs
	cTotal = Ethylene_Combustion+EthyleneCo_Prod_Combustion+Chemical_Ethylene+Bio_Electricity+Bio_Hydrogen_Cons+Bio_Hydrogen_Prod+Bio_LF_Cons+Bio_LF_Prod+Bio_NG_Cons+Bio_NG_Prod+CSC_DAC_Cons+CSC_DAC_Prod+CSC_Inj_Cons+CSC_Pipe_Operation+CSC_Booster_Compression+Nonserved_Power+LossesbyZone_Power+NetExportFlowsLoss_Power+CVR_power+FDR_power+HydroRes_power+MustRun_power+SCR_power+TUCR_power+TNUCR_power+H2G2PCommit_Power+H2G2PNoCommit_Power+H2PUC_Power+H2PNUC_Power+H2SCR_Power+H2PC_Power+H2TC_Power+H2TT_Power+H2SF_Power+H2SNG_Power+H2NGP_Power+Bio_Ethanol_Cons+Bio_Ethanol_Prod 

	# Define total column, i.e. column 2
	# dfCost[!,Symbol("Total")] = [Green_H2_Generation, Blue_H2_Generation, Grey_H2_Generation, Bio_H2, Storage_Discharging, Storage_Charging, Nonserved_Energy, H2_Pipeline_Import_Export, H2_Truck_Import_Export, Truck_Consumption, H2G2P, Demand, Synfuel_Consumption, SynNG_Consumption, H2_from_Ethylene, cTotal]

    dfCost[!,Symbol("Total")] = [Chemical_Ethylene+Bio_Ethanol_Cons+Bio_Ethanol_Prod,Bio_Electricity,Bio_Hydrogen_Cons,Bio_Hydrogen_Prod,Bio_LF_Cons,Bio_LF_Prod,Bio_NG_Cons,Bio_NG_Prod,CSC_DAC_Cons,CSC_DAC_Prod,CSC_Inj_Cons,CSC_Pipe_Operation,CSC_Booster_Compression,Nonserved_Power,LossesbyZone_Power,NetExportFlowsLoss_Power,CVR_power,FDR_power,HydroRes_power,MustRun_power,SCR_power,TUCR_power,TNUCR_power,H2G2PCommit_Power,H2G2PNoCommit_Power,H2PUC_Power,H2PNUC_Power,H2SCR_Power,H2PC_Power,H2TC_Power,H2TT_Power,H2SF_Power,H2SNG_Power,H2NGP_Power, cTotal,Ethylene_Combustion,EthyleneCo_Prod_Combustion]


	################################################################################################################################
	# Computing zonal cost breakdown by cost category
	for z in 1:Z
        tempChemical_Ethylene = 0   
        tempEthylene_Combustion = 0  
        tempEthyleneCo_Prod_Combustion = 0  
        tempBio_Electricity = 0         
        tempBio_Hydrogen_Cons = 0         
        tempBio_Hydrogen_Prod = 0         
        tempBio_LF_Cons = 0         
        tempBio_LF_Prod = 0         
        tempBio_NG_Cons = 0         
        tempBio_NG_Prod = 0  
        tempBio_Ethanol_Cons = 0         
        tempBio_Ethanol_Prod = 0        
        tempCSC_DAC_Cons = 0         
        tempCSC_DAC_Prod = 0         
        tempCSC_Inj_Cons = 0         
        tempCSC_Pipe_Operation = 0    
        tempCSC_Booster_Compression = 0         
        tempNonserved_Power = 0         
        tempLossesbyZone_Power = 0         
        tempNetExportFlowsLoss_Power = 0         
        tempCVR_power = 0         
        tempFDR_power = 0         
        tempHydroRes_power = 0         
        tempMustRun_power = 0         
        tempSCR_power = 0         
        tempTUCR_power = 0         
        tempTNUCR_power = 0         
        tempH2G2PCommit_Power = 0         
        tempH2G2PNoCommit_Power = 0         
        tempH2PUC_Power = 0         
        tempH2PNUC_Power = 0         
        tempH2SCR_Power = 0         
        tempH2PC_Power = 0         
        tempH2TC_Power = 0         
        tempH2TT_Power = 0         
        tempH2SF_Power = 0         
        tempH2SNG_Power = 0         
        tempH2NGP_Power = 0   
        
        if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthyleneRetrofitting"] == 0
            tempChemical_Ethylene = tempChemical_Ethylene - sum(inputs["omega"].* (value.(EP[:eEthylene_Power_RES])[:,z]))-sum(inputs["omega"].* (value.(EP[:eEthylene_Power_Plant])[:,z]))
        end

        if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
            tempChemical_Ethylene = tempChemical_Ethylene - sum(inputs["omega"].* (value.(EP[:eEthylene_Power_RES])[:,z]))-sum(inputs["omega"].* (value.(EP[:eEthylene_Power_Plant])[:,z]))-sum(inputs["omega"].* (value.(EP[:eEthylene_Power_Retrofit])[:,z]))
        end

        if setup["ModelEthyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 0
            tempEthylene_Combustion = tempEthylene_Combustion + sum(inputs["omega"].* (value.(EP[:eEthylene_PowerRecoveryEthylene_RES])[:,z])) + sum(inputs["omega"].* (value.(EP[:eEthylene_RecoveryEthylene_Plant])[:,z]))
            tempEthyleneCo_Prod_Combustion = tempEthyleneCo_Prod_Combustion + sum(inputs["omega"].* (value.(EP[:eEthylene_PowerRecoveryCoProducts_RES])[:,z])) + sum(inputs["omega"].* (value.(EP[:eEthylene_RecoveryCoProducts_Plant])[:,z]))
        end

        if setup["ModelEthyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
            tempEthylene_Combustion = tempEthylene_Combustion + sum(inputs["omega"].* (value.(EP[:eEthylene_PowerRecoveryEthylene_RES])[:,z])) + sum(inputs["omega"].* (value.(EP[:eEthylene_RecoveryEthylene_Plant])[:,z])) + sum(inputs["omega"].* (value.(EP[:eEthylene_RecoveryEthylene_Retrofit])[:,z]))
            tempEthyleneCo_Prod_Combustion = tempEthyleneCo_Prod_Combustion + sum(inputs["omega"].* (value.(EP[:eEthylene_PowerRecoveryCoProducts_RES])[:,z])) + sum(inputs["omega"].* (value.(EP[:eEthylene_RecoveryCoProducts_Plant])[:,z])) + sum(inputs["omega"].* (value.(EP[:eEthylene_RecoveryCoProducts_Retrofit])[:,z]))
        end
   

        if setup["ModelBESC"] == 1 && setup["Bio_ELEC_On"] == 1
            tempBio_Electricity = tempBio_Electricity + sum(inputs["omega"].* (value.(EP[:eBioELEC_produced_MWh_per_time_per_zone])[:,z]))
        end

        if setup["ModelBESC"] == 1 && setup["Bio_H2_On"] == 1
            tempBio_Hydrogen_Cons = tempBio_Hydrogen_Cons - sum(inputs["omega"].* (value.(EP[:eBio_H2_Plant_Power_consumption_per_time_per_zone])[:,z]))
            tempBio_Hydrogen_Prod = tempBio_Hydrogen_Prod + sum(inputs["omega"].* (value.(EP[:eBioH2_Power_credit_produced_MWh_per_time_per_zone])[:,z]))
        end

        if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
            tempBio_LF_Cons = tempBio_LF_Cons - sum(inputs["omega"].* (value.(EP[:eBio_LF_Plant_Power_consumption_per_time_per_zone])[:,z]))
            tempBio_LF_Prod = tempBio_LF_Prod + sum(inputs["omega"].* (value.(EP[:eBioLF_Power_credit_produced_MWh_per_time_per_zone])[:,z]))
        end

        if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
            tempBio_NG_Cons = tempBio_NG_Cons - sum(inputs["omega"].* (value.(EP[:eBio_NG_Plant_Power_consumption_per_time_per_zone])[:,z]))
            tempBio_NG_Prod = tempBio_NG_Prod + sum(inputs["omega"].* (value.(EP[:eBioNG_Power_credit_produced_MWh_per_time_per_zone])[:,z]))
        end

        if setup["ModelBESC"] == 1 && setup["Bio_Ethanol_On"] == 1
            tempBio_Ethanol_Cons = tempBio_NG_Cons - sum(inputs["omega"].* (value.(EP[:eBio_Ethanol_Plant_Power_consumption_per_time_per_zone])[:,z]))
            tempBio_Ethanol_Prod = tempBio_NG_Prod + sum(inputs["omega"].* (value.(EP[:eBioEthanol_Power_credit_produced_MWh_per_time_per_zone])[:,z]))
        end

        if setup["ModelCSC"] == 1 
            tempCSC_DAC_Cons = tempCSC_DAC_Cons - sum(inputs["omega"].* (value.(EP[:ePower_Balance_DAC])[:,z]))
            tempCSC_DAC_Prod = tempCSC_DAC_Prod + sum(inputs["omega"].* (value.(EP[:ePower_Produced_Balance_DAC])[:,z]))
        end

        if setup["ModelCSC"] == 1 && setup["ModelCO2Storage"] == 1
            tempCSC_Inj_Cons = tempCSC_Inj_Cons - sum(inputs["omega"].* (value.(EP[:ePower_Balance_CO2_Storage])[:,z]))
        end

        if setup["ModelCSC"] == 1 && setup["ModelCO2Pipelines"] == 1
            tempCSC_Pipe_Operation = tempCSC_Pipe_Operation - sum(inputs["omega"].* (value.(EP[:ePowerDemandCO2Pipe])[:,z]))
            tempCSC_Booster_Compression = tempCSC_Booster_Compression - sum(inputs["omega"].* (value.(EP[:ePowerDemandCO2PipeCompression])[:,z]))
        end

        tempNonserved_Power = tempNonserved_Power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceNse])[:,z]))
        tempLossesbyZone_Power = tempLossesbyZone_Power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceLossesByZone])[:,z]))
        tempNetExportFlowsLoss_Power = tempNetExportFlowsLoss_Power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceNetExportFlows])[:,z]))
        tempCVR_power = tempCVR_power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceDisp])[:,z]))
        if !isempty(inputs["FLEX"])
            tempFDR_power = tempFDR_power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceDemandFlex])[:,z]))
        end       
        tempHydroRes_power = tempHydroRes_power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceHydroRes])[:,z]))
        tempMustRun_power = tempMustRun_power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceNdisp])[:,z]))
        tempSCR_power = tempSCR_power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceStor])[:,z]))
        tempTUCR_power = tempTUCR_power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceThermCommit])[:,z]))
           
        
        if !isempty(THERM_NO_COMMIT)
            tempTNUCR_power = tempTNUCR_power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceThermNoCommit])[:,z]))
        end 
        
       


        if setup["ModelH2"] == 1 && setup["ModelH2G2P"] == 1
            tempH2G2PCommit_Power = tempH2G2PCommit_Power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2G2PCommit])[:,z]))
            if !isempty(H2_G2P_NO_COMMIT)
                tempH2G2PNoCommit_Power = tempH2G2PNoCommit_Power + sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2G2PNoCommit])[:,z]))
            end
            
        end

        if setup["ModelH2"] == 1 && !isempty(H2_GEN_COMMIT) 
            tempH2PUC_Power = tempH2PUC_Power - sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2GenCommit])[:,z]))         
        end

        if setup["ModelH2"] == 1 
            tempH2PNUC_Power = tempH2PNUC_Power - sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2GenNoCommit])[:,z]))
            tempH2SCR_Power = tempH2SCR_Power - sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2Stor])[:,z]))
            tempH2PC_Power = tempH2PC_Power - sum(inputs["omega"].* (value.(EP[:ePowerBalanceH2PipeCompression])[:,z]))  
        end

        if setup["ModelH2"] == 1 && setup["ModelH2Trucks"] == 1
            tempH2TC_Power = tempH2TC_Power - sum(inputs["omega"].* (value.(EP[:ePowerbalanceH2TruckCompression])[:,z]))
            tempH2TT_Power = tempH2TT_Power - sum(inputs["omega"].* (value.(EP[:ePowerbalanceH2TruckTravel])[:,z]))    
        end

        if setup["ModelLFSC"] == 1 && setup["ModelSyntheticFuels"] == 1
            tempH2SF_Power = tempH2SF_Power - sum(inputs["omega"].* (value.(EP[:eSyn_Fuel_Power_Cons])[:,z]))      
        end

        if setup["ModelNGSC"] == 1 && setup["ModelSyntheticNG"] == 1
            tempH2SNG_Power = tempH2SNG_Power - sum(inputs["omega"].* (value.(EP[:eSyn_NG_Power_Cons])[:,z])) 
        end

        if setup["ModelNGSC"] == 1 && setup["ModelNGPipelines"] == 1
            tempH2NGP_Power =  tempH2NGP_Power - sum(inputs["omega"].* (value.(EP[:ePowerBalanceNGPipeCompression])[:,z])) 
        end  
    
    
    
		tempCTotal = tempEthylene_Combustion+tempEthyleneCo_Prod_Combustion+tempBio_Ethanol_Cons+tempBio_Ethanol_Prod+tempChemical_Ethylene + tempBio_Electricity + tempBio_Hydrogen_Cons + tempBio_Hydrogen_Prod + tempBio_LF_Cons + tempBio_LF_Prod + tempBio_NG_Cons + tempBio_NG_Prod + tempCSC_DAC_Cons + tempCSC_DAC_Prod + tempCSC_Inj_Cons + tempCSC_Pipe_Operation + tempCSC_Booster_Compression + tempNonserved_Power + tempLossesbyZone_Power + tempNetExportFlowsLoss_Power + tempCVR_power + tempFDR_power + tempHydroRes_power + tempMustRun_power + tempSCR_power + tempTUCR_power + tempTNUCR_power + tempH2G2PCommit_Power + tempH2G2PNoCommit_Power + tempH2PUC_Power + tempH2PNUC_Power + tempH2SCR_Power + tempH2PC_Power + tempH2TC_Power + tempH2TT_Power + tempH2SF_Power + tempH2SNG_Power + tempH2NGP_Power


		dfCost[!,Symbol("Zone$z")] = [tempChemical_Ethylene+tempBio_Ethanol_Cons+tempBio_Ethanol_Prod, tempBio_Electricity , tempBio_Hydrogen_Cons , tempBio_Hydrogen_Prod , tempBio_LF_Cons , tempBio_LF_Prod , tempBio_NG_Cons , tempBio_NG_Prod , tempCSC_DAC_Cons , tempCSC_DAC_Prod , tempCSC_Inj_Cons , tempCSC_Pipe_Operation , tempCSC_Booster_Compression , tempNonserved_Power , tempLossesbyZone_Power , tempNetExportFlowsLoss_Power , tempCVR_power , tempFDR_power , tempHydroRes_power , tempMustRun_power , tempSCR_power , tempTUCR_power , tempTNUCR_power , tempH2G2PCommit_Power , tempH2G2PNoCommit_Power , tempH2PUC_Power , tempH2PNUC_Power , tempH2SCR_Power , tempH2PC_Power , tempH2TC_Power , tempH2TT_Power , tempH2SF_Power , tempH2SNG_Power , tempH2NGP_Power, tempCTotal,tempEthylene_Combustion,tempEthyleneCo_Prod_Combustion]
	end

	#CSV.write(string(path,sep,"Power_balance_zone.csv"), dfCost)
    CSV.write(joinpath(path,"Power_balance_zone.csv"), dfCost)

    #CSV.write(joinpath(path, "prices_hydrogen_pertonne.csv"), dftranspose(dfPrice, false), writeheader=false)
    #CSV.write(joinpath(path, "CO2_prices_and_penalties.csv"), dfCO2Price)

end

