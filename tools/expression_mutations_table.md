# Expression Mutations
## eObj
|Mutation|File|Explanation| 
|:-|:-|:-
|+= eTotalCVarOut|discharge.jl| |
|+= eCH2GenTotalEmissionsPenalty|emissions_hsc.jl| |
|+= eCH2GenTotalEmissionsPenalty|emissions_hsc.jl| |
|+= eCGenTotalEmissionsPenalty|emissions_power.jl| |
|+= eTotalCVarFlexIn|flexible_demand.jl| |
|+= eTotalH2G2PCStart|h2_g2p_commit.jl| |
|+= eTotalCH2G2PVarOut|h2_g2p_discharge.jl| |
|+= eTotalH2G2PCFix|h2_g2p_investment.jl| |
|+= eTotalH2GenCFix|h2_investment.jl| |
|+= eTotalH2CNSE|h2_non_served.jl| |
|+= eTotalCH2GenVarOut|h2_outputs.jl| |
|+= eCH2Pipe|h2_pipeline.jl| |
|+= eCH2CompPipe|h2_pipeline.jl| |
|+= eTotalH2GenCStart|h2_production_commit.jl| |
|+= eTotalCVarH2StorIn|h2_storage_all.jl| |
|+= eTotalCFixH2Charge|h2_storage_investment.jl| |
|+= eTotalCFixH2Energy|h2_storage_investment.jl| |
|+= eTotalCFixH2Charge|h2_storage_investment_charge.jl| |
|+= eTotalCFixH2Energy|h2_storage_investment_energy.jl| |
|+= OPEX_Truck|h2_truck_all.jl| |
|+= OPEX_Truck_Compression|h2_truck_all.jl| |
|+= eTotalCFixH2TruckCharge|h2_truck_investment.jl| |
|+= eTotalCFixH2TruckEnergy|h2_truck_investment.jl| |
|+= eTotalCFixCharge|investment_charge.jl| |
|+= eTotalCFix|investment_discharge.jl| |
|+= eTotalCFixEnergy|investment_energy.jl| |
|+= eTotalCNSE|non_served_energy.jl| |
|+= eTotalCRsvPen|reserves.jl| |
|+= eTotalCVarIn|storage_all.jl| |
|+= eTotalCNetworkExp|transmission.jl| |
|+= eTotalCStart|ucommit.jl| |
## ePowerBalance
|Mutation|File|Explanation| 
|:-|:-|:-
|+= ePowerBalanceDisp|curtailable_variable_renewable.jl| |
|+= ePowerBalanceDemandFlex|flexible_demand.jl| |
|+= ePowerBalanceH2G2PCommit|h2_g2p_commit.jl| |
|+= ePowerBalanceH2G2PNoCommit|h2_g2p_no_commit.jl| |
|+= -ePowerBalanceH2PipeCompression|h2_pipeline.jl| |
|+= -ePowerBalanceH2GenCommit|h2_production_commit.jl| |
|+= -ePowerBalanceH2GenNoCommit|h2_production_no_commit.jl| |
|+= -ePowerBalanceH2Stor|h2_storage_all.jl| |
|+= -ePowerbalanceH2TruckCompression|h2_truck_all.jl| |
|+= -ePowerbalanceH2TruckTravel|h2_truck_all.jl| |
|+= ePowerBalanceHydroRes|hydro_res.jl| |
|+= ePowerBalanceNdisp|must_run.jl| |
|+= ePowerBalanceNse|non_served_energy.jl| |
|+= ePowerBalanceStor|storage_all.jl| |
|+= ePowerBalanceThermCommit|thermal_commit.jl| |
|+= ePowerBalanceThermNoCommit|thermal_no_commit.jl| |
|+= ePowerBalanceLossesByZone|transmission.jl| |
|+= ePowerBalanceNetExportFlows|transmission.jl| |
## eH2Balance
|Mutation|File|Explanation| 
|:-|:-|:-
|-= eH2G2PCommit|h2_g2p_commit.jl| |
|-= eH2G2PNoCommit|h2_g2p_no_commit.jl| |
|+= eH2BalanceNse|h2_non_served.jl| |
|+= ePipeZoneDemand|h2_pipeline.jl| |
|+= eH2GenCommit|h2_production_commit.jl| |
|+= eH2GenNoCommit|h2_production_no_commit.jl| |
|+= eH2BalanceStor|h2_storage_all.jl| |
|+= eH2TruckFlow|h2_truck_all.jl| |
|+= -eH2TruckTravelConsumption|h2_truck_all.jl| |
