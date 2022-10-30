# Model Variables and Expressions
## Variables
|Variable name|created|accessed|
|:-|:-|:-|
|vCAP|investment_discharge.jl|investment_discharge.jl, investment_energy.jl, ucommit.jl, investment_charge.jl, reserves.jl, write_capacity.jl|
|vCAPCHARGE|investment_charge.jl|investment_charge.jl, write_capacity.jl|
|vCAPENERGY|investment_energy.jl|investment_energy.jl, write_capacity.jl|
|vCHARGE|storage_all.jl|flexible_demand.jl, write_charge.jl, cap_reserve_margin.jl, storage_symmetric.jl, long_duration_storage.jl, write_power_balance.jl, storage_asymmetric.jl, write_net_revenue.jl, storage_all.jl|
|vCHARGE_FLEX|flexible_demand.jl|flexible_demand.jl, write_charge.jl, cap_reserve_margin.jl, write_power_balance.jl|
|vCOMMIT|ucommit.jl|write_commit.jl, ucommit.jl, reserves.jl, thermal_commit.jl|
|vCONTINGENCY_AUX|reserves.jl|reserves.jl|
|vFLOW|transmission.jl|cap_reserve_margin.jl, transmission.jl, write_transmission_flows.jl|
|vH2CAPCHARGE|h2_storage_investment.jl|h2_storage_investment_charge.jl, write_h2_capacity.jl, h2_storage_investment.jl|
|vH2CAPENERGY|h2_storage_investment.jl|write_h2_capacity.jl, h2_storage_investment_energy.jl, h2_storage_investment.jl|
|vH2G2P|h2_g2p_all.jl|h2_g2p.jl, write_g2p_capacity.jl, write_h2_g2p.jl, h2_g2p_all.jl, write_h2_balance.jl, h2_g2p_no_commit.jl, h2_g2p_investment.jl, h2_g2p_commit.jl|
|vH2G2PCOMMIT|h2_g2p_commit.jl|h2_g2p_commit.jl|
|vH2G2PNewCap|h2_g2p_investment.jl|write_g2p_capacity.jl, h2_g2p_investment.jl, h2_g2p_commit.jl|
|vH2G2PRetCap|h2_g2p_investment.jl|write_g2p_capacity.jl, h2_g2p_all.jl, h2_g2p_investment.jl, h2_g2p_commit.jl|
|vH2G2PShut|h2_g2p_commit.jl|h2_g2p_commit.jl|
|vH2G2PStart|h2_g2p_commit.jl|h2_g2p_commit.jl|
|vH2Gen|h2_outputs.jl|h2_production_commit.jl, h2_production_all.jl, emissions_hsc.jl, h2_investment.jl, h2_long_duration_storage.jl, write_h2_capacity.jl, write_h2_balance.jl, test.jl, h2_storage_all.jl, h2_production_no_commit.jl, h2_outputs.jl, write_h2_gen.jl, h2_production.jl, h2_flexible_demand.jl|
|vH2GenCOMMIT|h2_production_commit.jl|h2_production_commit.jl|
|vH2GenNewCap|h2_investment.jl|h2_production_commit.jl, h2_investment.jl, write_h2_capacity.jl, test.jl|
|vH2GenRetCap|h2_investment.jl|h2_production_commit.jl, h2_production_all.jl, h2_investment.jl, write_h2_capacity.jl|
|vH2GenShut|h2_production_commit.jl|h2_production_commit.jl|
|vH2GenStart|h2_production_commit.jl|h2_production_commit.jl|
|vH2NPipe|h2_pipeline.jl|h2_pipeline.jl, write_h2_pipeline_expansion.jl|
|vH2NSE|h2_non_served.jl|co2_cap_hsc.jl, h2_non_served.jl, write_h2_balance.jl, co2_cap_power_hsc.jl, write_h2_nse.jl|
|vH2N_empty|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2N_full|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Narrive_empty|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Narrive_full|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Navail_empty|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Navail_full|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Ncharged|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Ndepart_empty|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Ndepart_full|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Ndischarged|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Ntravel_empty|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2Ntravel_full|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2PipeFlow_neg|h2_pipeline.jl|h2_pipeline.jl|
|vH2PipeFlow_pos|h2_pipeline.jl|h2_pipeline.jl|
|vH2PipeLevel|h2_pipeline.jl|h2_pipeline.jl, write_h2_pipeline_flow.jl, write_h2_pipeline_level.jl|
|vH2RETCAPCHARGE|h2_storage_investment.jl|h2_storage_investment_charge.jl, write_h2_capacity.jl, h2_storage_investment.jl|
|vH2RETCAPENERGY|h2_storage_investment.jl|write_h2_capacity.jl, h2_storage_investment_energy.jl, h2_storage_investment.jl|
|vH2RetTruckEnergy|h2_truck_investment.jl|write_h2_truck_capacity.jl, h2_truck_investment.jl|
|vH2RetTruckNumber|h2_truck_investment.jl|write_h2_truck_capacity.jl, h2_truck_investment.jl|
|vH2S|h2_storage_all.jl|write_h2_storage.jl, h2_long_duration_storage.jl, h2_storage_all.jl|
|vH2SOCw|h2_long_duration_storage.jl|h2_long_duration_storage.jl|
|vH2TruckEnergy|h2_truck_investment.jl|write_h2_truck_capacity.jl, h2_truck_investment.jl|
|vH2TruckFlow|h2_truck_all.jl|write_h2_truck_flow.jl, h2_truck_all.jl|
|vH2TruckNumber|h2_truck_investment.jl|write_h2_truck_capacity.jl, h2_truck_investment.jl|
|vH2TruckSOCw|h2_long_duration_truck.jl|h2_long_duration_truck.jl|
|vH2TruckdSOC|h2_long_duration_truck.jl|h2_long_duration_truck.jl|
|vH2_CHARGE_FLEX|h2_flexible_demand.jl|write_h2_balance.jl, write_h2_charge.jl, h2_flexible_demand.jl|
|vH2_CHARGE_STOR|h2_storage_all.jl|h2_pipeline.jl, emissions_hsc.jl, h2_long_duration_storage.jl, write_h2_balance.jl, h2_storage_all.jl, write_h2_charge.jl, h2_storage_asymmetric.jl|
|vLARGEST_CONTINGENCY|reserves.jl|reserves.jl|
|vNEW_TRANS_CAP|transmission.jl|transmission.jl, write_nw_expansion.jl|
|vNSE|non_served_energy.jl|cap_reserve_margin.jl, co2_cap_power.jl, non_served_energy.jl, write_nse.jl, write_power_balance.jl, co2_cap_power_hsc.jl|
|vP|discharge.jl|h2_production_commit.jl, flexible_demand.jl, emissions_power.jl, write_curtailment.jl, h2_production_all.jl, discharge.jl, write_power.jl, cap_reserve_margin.jl, write_p_g2p.jl, energy_share_requirement.jl, storage_symmetric.jl, long_duration_storage.jl, thermal_no_commit.jl, h2_g2p.jl, transmission.jl, hydro_res.jl, h2_g2p_no_commit.jl, write_power_balance.jl, write_costs.jl, reserves.jl, h2_g2p_commit.jl, h2_g2p_discharge.jl, thermal_commit.jl, write_net_revenue.jl, must_run.jl, curtailable_variable_renewable.jl, h2_production_no_commit.jl, hydro_inter_period_linkage.jl, thermal.jl, storage_all.jl|
|vP2G|h2_production_all.jl|h2_production_commit.jl, h2_production_all.jl, h2_production_no_commit.jl|
|vPG2P|h2_g2p_discharge.jl|write_p_g2p.jl, h2_g2p.jl, h2_g2p_no_commit.jl, write_power_balance.jl, h2_g2p_commit.jl, h2_g2p_discharge.jl|
|vPROD_TRANSCAP_ON|transmission.jl|transmission.jl|
|vREG|reserves.jl|write_reg.jl, storage_symmetric.jl, thermal_no_commit.jl, hydro_res.jl, reserves.jl, storage_asymmetric.jl, thermal_commit.jl, curtailable_variable_renewable.jl, storage_all.jl|
|vREG_charge|reserves.jl|storage_symmetric.jl, reserves.jl, storage_asymmetric.jl, storage_all.jl|
|vREG_discharge|reserves.jl|storage_symmetric.jl, reserves.jl, storage_all.jl|
|vRETCAP|investment_discharge.jl|investment_discharge.jl, investment_energy.jl, ucommit.jl, investment_charge.jl, write_capacity.jl|
|vRETCAPCHARGE|investment_charge.jl|investment_charge.jl, write_capacity.jl|
|vRETCAPENERGY|investment_energy.jl|investment_energy.jl, write_capacity.jl|
|vRSV|reserves.jl|storage_symmetric.jl, thermal_no_commit.jl, write_rsv.jl, hydro_res.jl, reserves.jl, thermal_commit.jl, curtailable_variable_renewable.jl, storage_all.jl|
|vRSV_charge|reserves.jl|reserves.jl, storage_all.jl|
|vRSV_discharge|reserves.jl|storage_symmetric.jl, reserves.jl, storage_all.jl|
|vS|storage_all.jl|flexible_demand.jl, emissions_power.jl, write_shutdown.jl, long_duration_storage.jl, ucommit.jl, write_start.jl, write_storage.jl, write_h2_storage.jl, write_opwrap_lds_stor_init.jl, hydro_res.jl, thermal_commit.jl, hydro_inter_period_linkage.jl, storage_all.jl, h2_flexible_demand.jl|
|vSHUT|ucommit.jl|write_shutdown.jl, ucommit.jl, thermal_commit.jl|
|vSOC_HYDROw|hydro_inter_period_linkage.jl|hydro_inter_period_linkage.jl|
|vSOCw|long_duration_storage.jl|long_duration_storage.jl, write_opwrap_lds_stor_init.jl|
|vSPILL|hydro_res.jl|hydro_res.jl, hydro_inter_period_linkage.jl|
|vSTART|ucommit.jl|emissions_power.jl, ucommit.jl, write_start.jl, thermal_commit.jl|
|vS_FLEX|flexible_demand.jl|flexible_demand.jl, write_storage.jl|
|vS_H2_FLEX|h2_flexible_demand.jl|write_h2_storage.jl, h2_flexible_demand.jl|
|vS_HYDRO|hydro_res.jl|write_storage.jl, hydro_res.jl, hydro_inter_period_linkage.jl|
|vTAUX_NEG|transmission.jl|transmission.jl|
|vTAUX_NEG_ON|transmission.jl|transmission.jl|
|vTAUX_POS|transmission.jl|transmission.jl|
|vTAUX_POS_ON|transmission.jl|transmission.jl|
|vTLOSS|transmission.jl|write_transmission_losses.jl, transmission.jl|
|vUNMET_RSV|reserves.jl|write_rsv.jl, reserves.jl|
|vZERO|generate_model.jl|investment_discharge.jl, investment_energy.jl, transmission.jl, investment_charge.jl, h2_truck_investment.jl, generate_model.jl|
|vdH2SOC|h2_long_duration_storage.jl|h2_long_duration_storage.jl|
|vdSOC|long_duration_storage.jl|long_duration_storage.jl, write_opwrap_lds_dstor.jl, hydro_inter_period_linkage.jl|
|vdSOC_HYDRO|hydro_inter_period_linkage.jl|hydro_inter_period_linkage.jl|
## Expressions
|Expression name|created|accessed|
|:-|:-|:-|
|OPEX_Truck|h2_truck_all.jl|h2_truck_all.jl|
|OPEX_Truck_Compression|h2_truck_all.jl|h2_truck_all.jl|
|Truck_carbon_emission|h2_truck_all.jl|h2_truck_all.jl|
|eAvail_Trans_Cap|transmission.jl|transmission.jl, generate_model.jl|
|eCEmissionsPenaltybyPolicy|emissions_power.jl|emissions_power.jl|
|eCEmissionsPenaltybyZone|emissions_power.jl|emissions_power.jl, write_costs.jl|
|eCFix|investment_discharge.jl|investment_discharge.jl, investment_energy.jl, write_h2_costs.jl, h2_storage_investment_charge.jl, investment_charge.jl, test.jl, write_costs.jl, h2_truck_investment.jl, h2_storage_investment_energy.jl, h2_storage_investment.jl|
|eCFixCharge|investment_charge.jl|investment_charge.jl, write_costs.jl|
|eCFixEnergy|investment_energy.jl|investment_energy.jl, write_costs.jl|
|eCFixH2Charge|h2_storage_investment.jl|write_h2_costs.jl, h2_storage_investment_charge.jl, h2_storage_investment.jl|
|eCFixH2Energy|h2_storage_investment.jl|write_h2_costs.jl, h2_storage_investment_energy.jl, h2_storage_investment.jl|
|eCFixH2TruckCharge|h2_truck_investment.jl|h2_truck_investment.jl|
|eCFixH2TruckEnergy|h2_truck_investment.jl|h2_truck_investment.jl|
|eCGenTotalEmissionsPenalty|emissions_power.jl|emissions_power.jl, write_costs.jl|
|eCH2CompPipe|h2_pipeline.jl|h2_pipeline.jl|
|eCH2EmissionsPenaltybyPolicy|emissions_hsc.jl|emissions_hsc.jl|
|eCH2EmissionsPenaltybyZone|emissions_hsc.jl|emissions_hsc.jl, write_h2_costs.jl|
|eCH2G2PVar_out|h2_g2p_discharge.jl|write_h2_costs.jl, h2_g2p_discharge.jl|
|eCH2GenTotalEmissionsPenalty|emissions_hsc.jl|emissions_hsc.jl, write_h2_costs.jl|
|eCH2GenVar_out|h2_outputs.jl|write_h2_costs.jl, test.jl, h2_outputs.jl|
|eCH2Pipe|h2_pipeline.jl|h2_pipeline.jl, write_h2_costs.jl|
|eCH2VarFlex_in|h2_flexible_demand.jl|write_h2_costs.jl, h2_flexible_demand.jl|
|eCNSE|non_served_energy.jl|non_served_energy.jl, write_costs.jl|
|eCRsvPen|reserves.jl|reserves.jl|
|eCStart|ucommit.jl|ucommit.jl, write_costs.jl, write_net_revenue.jl|
|eCVarFlex_in|flexible_demand.jl|flexible_demand.jl, write_costs.jl|
|eCVarH2Stor_in|h2_storage_all.jl|write_h2_costs.jl, h2_storage_all.jl|
|eCVar_in|storage_all.jl|write_costs.jl, storage_all.jl|
|eCVar_out|discharge.jl|discharge.jl, test.jl, write_costs.jl|
|eContingencyReq|reserves.jl|reserves.jl|
|eEH2LOSS|h2_storage_all.jl|h2_storage_all.jl|
|eELOSS|storage_all.jl|energy_share_requirement.jl, co2_cap_power.jl, co2_cap_power_hsc.jl, storage_all.jl|
|eELOSSByZone|storage_all.jl|co2_cap_power.jl, co2_cap_power_hsc.jl, storage_all.jl|
|eEmissionsByPlant|emissions_power.jl|emissions_power.jl, write_net_revenue.jl|
|eEmissionsByZone|emissions_power.jl|emissions_power.jl, co2_cap_power.jl, write_emissions.jl, co2_cap_power_hsc.jl|
|eGenerationByHydroRes|hydro_res.jl|hydro_res.jl|
|eGenerationByMustRun|must_run.jl|must_run.jl|
|eGenerationByThermAll|thermal.jl|thermal.jl|
|eGenerationByVRE|curtailable_variable_renewable.jl|curtailable_variable_renewable.jl|
|eGenerationByZone|generate_model.jl|h2_g2p.jl, co2_cap_power.jl, hydro_res.jl, co2_cap_power_hsc.jl, must_run.jl, generate_model.jl, curtailable_variable_renewable.jl, thermal.jl|
|eGenerationByZoneG2P|h2_g2p.jl|h2_g2p.jl|
|eH2Balance|generate_model.jl|h2_production_commit.jl, h2_pipeline.jl, h2_truck_all.jl, h2_non_served.jl, h2_g2p_no_commit.jl, h2_g2p_commit.jl, h2_storage_all.jl, generate_model.jl, h2_production_no_commit.jl, h2_flexible_demand.jl|
|eH2BalanceDemandFlex|h2_flexible_demand.jl|h2_flexible_demand.jl|
|eH2BalanceNse|h2_non_served.jl|h2_non_served.jl|
|eH2BalanceStor|h2_storage_all.jl|h2_storage_all.jl|
|eH2CNSE|h2_non_served.jl|write_h2_costs.jl, h2_non_served.jl|
|eH2DemandByZoneG2P|h2_g2p.jl|co2_cap_hsc.jl, h2_g2p.jl, co2_cap_power_hsc.jl|
|eH2EmissionsByPlant|emissions_hsc.jl|emissions_hsc.jl|
|eH2EmissionsByZone|emissions_hsc.jl|write_h2_emissions.jl, emissions_hsc.jl, co2_cap_hsc.jl, co2_cap_power_hsc.jl|
|eH2G2PCFix|h2_g2p_investment.jl|write_h2_costs.jl, h2_g2p_investment.jl|
|eH2G2PCStart|h2_g2p_commit.jl|write_h2_costs.jl, h2_g2p_commit.jl|
|eH2G2PCommit|h2_g2p_commit.jl|h2_g2p_commit.jl|
|eH2G2PNoCommit|h2_g2p_no_commit.jl|h2_g2p_no_commit.jl|
|eH2G2PTotalCap|h2_g2p_investment.jl|write_g2p_capacity.jl, h2_g2p_all.jl, h2_g2p_no_commit.jl, h2_g2p_investment.jl, h2_g2p_commit.jl|
|eH2GenCFix|h2_investment.jl|write_h2_costs.jl, h2_investment.jl, test.jl|
|eH2GenCStart|h2_production_commit.jl|h2_production_commit.jl, write_h2_costs.jl|
|eH2GenCommit|h2_production_commit.jl|h2_production_commit.jl, test.jl|
|eH2GenNoCommit|h2_production_no_commit.jl|test.jl, h2_production_no_commit.jl|
|eH2GenTotalCap|h2_investment.jl|h2_production_commit.jl, h2_production_all.jl, h2_investment.jl, h2_long_duration_storage.jl, write_h2_capacity.jl, test.jl, h2_storage_all.jl, h2_production_no_commit.jl, h2_flexible_demand.jl|
|eH2GenerationByZone|h2_production.jl|co2_cap_hsc.jl, co2_cap_power_hsc.jl, h2_production.jl|
|eH2NPipeNew|h2_pipeline.jl|h2_pipeline.jl|
|eH2NetpowerConsumptionByAll|generate_model.jl|h2_production_commit.jl, h2_pipeline.jl, co2_cap_power.jl, h2_truck_all.jl, test.jl, write_power_balance.jl, h2_storage_all.jl, generate_model.jl, h2_production_no_commit.jl|
|eH2PipeFlow_net|h2_pipeline.jl|h2_pipeline.jl, write_h2_pipeline_flow.jl|
|eH2PowerConsumptionByPipe|h2_pipeline.jl|h2_pipeline.jl|
|eH2TotalCapEnergy|h2_storage_investment_energy.jl|h2_storage_all.jl, h2_storage_investment_energy.jl|
|eH2TruckFlow|h2_truck_all.jl|h2_truck_all.jl, write_h2_balance.jl|
|eH2TruckTravelConsumption|h2_truck_all.jl|h2_truck_all.jl|
|eLosses_By_Zone|transmission.jl|transmission.jl, write_h2_balance.jl, write_power_balance.jl|
|eNet_Export_Flows|transmission.jl|transmission.jl|
|eObj|generate_model.jl|h2_production_commit.jl, flexible_demand.jl, investment_discharge.jl, emissions_power.jl, h2_pipeline.jl, discharge.jl, investment_energy.jl, emissions_hsc.jl, h2_investment.jl, transmission.jl, ucommit.jl, h2_truck_all.jl, non_served_energy.jl, h2_storage_investment_charge.jl, investment_charge.jl, h2_non_served.jl, test.jl, h2_g2p_investment.jl, reserves.jl, h2_truck_investment.jl, h2_g2p_commit.jl, h2_g2p_discharge.jl, h2_storage_all.jl, generate_model.jl, h2_outputs.jl, h2_storage_investment_energy.jl, storage_all.jl, h2_storage_investment.jl, h2_flexible_demand.jl|
|ePipeZoneDemand|h2_pipeline.jl|h2_pipeline.jl, write_h2_balance.jl|
|ePowerBalance|generate_model.jl|h2_production_commit.jl, flexible_demand.jl, h2_pipeline.jl, thermal_no_commit.jl, transmission.jl, h2_truck_all.jl, non_served_energy.jl, write_h2_balance.jl, test.jl, hydro_res.jl, h2_g2p_no_commit.jl, write_power_balance.jl, h2_g2p_commit.jl, h2_storage_all.jl, thermal_commit.jl, must_run.jl, generate_model.jl, curtailable_variable_renewable.jl, h2_production_no_commit.jl, storage_all.jl|
|ePowerBalanceDemandFlex|flexible_demand.jl|flexible_demand.jl|
|ePowerBalanceDisp|curtailable_variable_renewable.jl|curtailable_variable_renewable.jl|
|ePowerBalanceH2G2PCommit|h2_g2p_commit.jl|h2_g2p_commit.jl|
|ePowerBalanceH2G2PNoCommit|h2_g2p_no_commit.jl|h2_g2p_no_commit.jl|
|ePowerBalanceH2GenCommit|h2_production_commit.jl|h2_production_commit.jl, test.jl|
|ePowerBalanceH2GenNoCommit|h2_production_no_commit.jl|test.jl, h2_production_no_commit.jl|
|ePowerBalanceH2PipeCompression|h2_pipeline.jl|h2_pipeline.jl, test.jl|
|ePowerBalanceH2Stor|h2_storage_all.jl|h2_storage_all.jl|
|ePowerBalanceHydroRes|hydro_res.jl|hydro_res.jl|
|ePowerBalanceLossesByZone|transmission.jl|transmission.jl|
|ePowerBalanceNdisp|must_run.jl|must_run.jl|
|ePowerBalanceNetExportFlows|transmission.jl|transmission.jl, write_h2_balance.jl, write_power_balance.jl|
|ePowerBalanceNse|non_served_energy.jl|non_served_energy.jl|
|ePowerBalanceStor|storage_all.jl|storage_all.jl|
|ePowerBalanceThermCommit|thermal_commit.jl|thermal_commit.jl|
|ePowerBalanceThermNoCommit|thermal_no_commit.jl|thermal_no_commit.jl|
|ePowerbalanceH2TruckCompression|h2_truck_all.jl|h2_truck_all.jl|
|ePowerbalanceH2TruckTravel|h2_truck_all.jl|h2_truck_all.jl|
|eRegReq|reserves.jl|reserves.jl|
|eRsvReq|reserves.jl|reserves.jl|
|eTotalCFix|investment_discharge.jl|investment_discharge.jl, investment_energy.jl, write_h2_costs.jl, h2_storage_investment_charge.jl, investment_charge.jl, write_costs.jl, h2_truck_investment.jl, h2_storage_investment_energy.jl, h2_storage_investment.jl|
|eTotalCFixCharge|investment_charge.jl|investment_charge.jl, write_costs.jl|
|eTotalCFixEnergy|investment_energy.jl|investment_energy.jl, write_costs.jl|
|eTotalCFixH2Charge|h2_storage_investment.jl|write_h2_costs.jl, h2_storage_investment_charge.jl, h2_storage_investment.jl|
|eTotalCFixH2Energy|h2_storage_investment.jl|write_h2_costs.jl, h2_storage_investment_energy.jl, h2_storage_investment.jl|
|eTotalCFixH2TruckCharge|h2_truck_investment.jl|h2_truck_investment.jl|
|eTotalCFixH2TruckEnergy|h2_truck_investment.jl|h2_truck_investment.jl|
|eTotalCH2G2PVarOut|h2_g2p_discharge.jl|write_h2_costs.jl, h2_g2p_discharge.jl|
|eTotalCH2G2PVarOutT|h2_g2p_discharge.jl|h2_g2p_discharge.jl|
|eTotalCH2GenVarOut|h2_outputs.jl|write_h2_costs.jl, h2_outputs.jl|
|eTotalCH2GenVarOutT|h2_outputs.jl|h2_outputs.jl|
|eTotalCH2VarFlexIn|h2_flexible_demand.jl|write_h2_costs.jl, h2_flexible_demand.jl|
|eTotalCH2VarFlexInT|h2_flexible_demand.jl|h2_flexible_demand.jl|
|eTotalCNSE|non_served_energy.jl|non_served_energy.jl, write_costs.jl|
|eTotalCNSET|non_served_energy.jl|non_served_energy.jl|
|eTotalCNSETS|non_served_energy.jl|non_served_energy.jl|
|eTotalCNetworkExp|transmission.jl|transmission.jl, write_costs.jl|
|eTotalCRsvPen|reserves.jl|write_costs.jl, reserves.jl|
|eTotalCStart|ucommit.jl|ucommit.jl, write_costs.jl|
|eTotalCStartT|ucommit.jl|ucommit.jl|
|eTotalCVarFlexIn|flexible_demand.jl|flexible_demand.jl, write_costs.jl|
|eTotalCVarFlexInT|flexible_demand.jl|flexible_demand.jl|
|eTotalCVarH2StorIn|h2_storage_all.jl|write_h2_costs.jl, h2_storage_all.jl|
|eTotalCVarH2StorInT|h2_storage_all.jl|h2_storage_all.jl|
|eTotalCVarIn|storage_all.jl|write_costs.jl, storage_all.jl|
|eTotalCVarInT|storage_all.jl|storage_all.jl|
|eTotalCVarOut|discharge.jl|discharge.jl, write_costs.jl|
|eTotalCVarOutT|discharge.jl|discharge.jl|
|eTotalCap|investment_discharge.jl|flexible_demand.jl, investment_discharge.jl, write_curtailment.jl, cap_reserve_margin.jl, minimum_capacity_requirement.jl, storage_symmetric.jl, investment_energy.jl, long_duration_storage.jl, thermal_no_commit.jl, investment_charge.jl, test.jl, hydro_res.jl, reserves.jl, storage_asymmetric.jl, thermal_commit.jl, must_run.jl, generate_model.jl, curtailable_variable_renewable.jl, write_subsidy_revenue.jl, hydro_inter_period_linkage.jl, storage_all.jl, write_capacity.jl|
|eTotalCapCharge|investment_charge.jl|investment_charge.jl, storage_asymmetric.jl, generate_model.jl|
|eTotalCapEnergy|investment_energy.jl|investment_energy.jl, long_duration_storage.jl, generate_model.jl, storage_all.jl|
|eTotalH2CNSE|h2_non_served.jl|write_h2_costs.jl, h2_non_served.jl|
|eTotalH2CNSET|h2_non_served.jl|h2_non_served.jl|
|eTotalH2CNSETS|h2_non_served.jl|h2_non_served.jl|
|eTotalH2CapCharge|h2_storage_investment.jl|h2_storage_investment_charge.jl, h2_storage_all.jl, h2_storage_asymmetric.jl, h2_storage_investment.jl|
|eTotalH2CapEnergy|h2_storage_investment.jl|h2_storage_investment.jl|
|eTotalH2G2PCFix|h2_g2p_investment.jl|write_h2_costs.jl, h2_g2p_investment.jl|
|eTotalH2G2PCStart|h2_g2p_commit.jl|write_h2_costs.jl, h2_g2p_commit.jl|
|eTotalH2G2PCStartT|h2_g2p_commit.jl|h2_g2p_commit.jl|
|eTotalH2GenCFix|h2_investment.jl|write_h2_costs.jl, h2_investment.jl|
|eTotalH2GenCStart|h2_production_commit.jl|h2_production_commit.jl, write_h2_costs.jl|
|eTotalH2GenCStartT|h2_production_commit.jl|h2_production_commit.jl|
|eTotalH2TruckEnergy|h2_truck_investment.jl|write_h2_truck_capacity.jl, h2_truck_all.jl, h2_truck_investment.jl|
|eTotalH2TruckNumber|h2_truck_investment.jl|write_h2_truck_capacity.jl, h2_truck_all.jl, h2_truck_investment.jl|
