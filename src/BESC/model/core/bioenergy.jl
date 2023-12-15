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
    bioenergy(EP::Model, inputs::Dict, setup::Dict)

This module defines the bio electricity, hydrogen, gasoline, jetfuel, and diesel production decision variables $x_{r,t}^{\textrm{E,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{H,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Gasoline,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Jetfuel,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Diesel,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$ representing bio electricity, hydrogen, gasoline, jetfuel, and diesel produced by resource $r$ at time period $t$.

This module also constraints the amount of each type of non conventional fuels deployment based on user specifications (if any).

This function creates expression to add the CO2 emissions of biofuel utilization in each zone, which is subsequently added to the total emissions. 

**Minimum and Maximum biomass input to biorefinery resource**

```math
\begin{equation*}
	x_{r,t}^{\textrm{B,Bio}} \geq \underline{R_{r}^{\textrm{B,Bio}}} \times y_{r}^{\textrm{B,Bio}} \quad \forall r \in \mathcal{R}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
	x_{r,t}^{\textrm{B,Bio}} \leq \overline{R_{r,t}^{\textrm{B,Bio}}} \times y_{r}^{\textrm{B,Bio}} \quad \forall r \in \mathcal{R}, t \in \mathcal{T}
\end{equation*}
```

**Maximum herb biomass utilization**

The total amount of biomass consumed by biorefinery with herbaceous biomass input cannot be greater than available herbaceous biomass in zone $z$ at time $t$.

```math
\begin{equation*}
	\sum_{r \in z \in herb} x_{r,t}^{\textrm{B,Bio}} \leq  \overline{x}_{z}^{\textrm{\textrm{B,Herb}}} \quad \forall r \in \mathcal{R}, \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Maximum wood biomass utilization**

The total amount of biomass consumed by biorefinery with woody biomass input cannot be greater than available woody biomass in zone $z$ at time $t$.

```math
\begin{equation*}
	\sum_{r \in z \in wood} x_{r,t}^{\textrm{B,Bio}} \leq  \overline{x}_{z}^{\textrm{\textrm{B,Wood}}} \quad \forall r \in \mathcal{R}, \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
"""
function bioenergy(EP::Model, inputs::Dict, setup::Dict)
	
	println("Biorefinery module")

	dfbioenergy = inputs["dfbioenergy"]
	BIO_RES_ALL = inputs["BIO_RES_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	BIO_RES_ALL = inputs["BIO_RES_ALL"]
	BIO_HERB = inputs["BIO_HERB"]
	BIO_WOOD = inputs["BIO_WOOD"]
	
	BIO_H2 = inputs["BIO_H2"]
	BIO_E = inputs["BIO_E"]
	BIO_DIESEL = inputs["BIO_DIESEL"]
	BIO_GASOLINE = inputs["BIO_GASOLINE"]
	BIO_ETHANOL = inputs["BIO_ETHANOL"]

	#####################################################################################################################################
	################################################ Power/H2 and Plant Operational Constraints #########################################
	#####################################################################################################################################
	
	#Power constraint
	@constraint(EP, cBioPower_Consumption[i in 1:BIO_RES_ALL, t in 1:T], EP[:vPower_BIO][i,t] == EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Power_consumption_MWh_per_tonne][i])

	#H2 constraint
	@constraint(EP, cBioH2_Consumption[i in 1:BIO_RES_ALL, t in 1:T], EP[:vH2_BIO][i,t] == EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:H2_consumption_tonne_per_tonne][i])

	#Include constraint of min bioenergy operation
	@constraint(EP,cMin_biomass_consumed_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] >= EP[:vCapacity_BIO_per_type][i] * dfbioenergy[!,:Biomass_min_consumption][i])

	#Include constraint of max bioenergy operation
	@constraint(EP,cMax_biomass_consumed_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] <= EP[:vCapacity_BIO_per_type][i] * dfbioenergy[!,:Biomass_max_consumption][i])

	#####################################################################################################################################
	#################################################### Biomass Consumed in Biorefinery ################################################
	#####################################################################################################################################

	#Herbaceous biomass consumed per zone
	@expression(EP, eTotal_herb_biomass_consumed_per_zone_per_time[z in 1:Z, t in 1:T],
	sum(EP[:vBiomass_consumed_per_plant_per_time][i,t] for i in intersect(BIO_HERB, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))

	#Herbaceous biomass consumed equals to biomass utilized from supply curve
	@constraint(EP, cHerb_biomass_consumed_per_zone[z in 1:Z, t in 1:T], EP[:eTotal_herb_biomass_consumed_per_zone_per_time][z,t] == EP[:vHerb_biomass_utilized_per_zone_per_time][z,t])

	#####################################################################################################################################
	#Woody biomass consumed per zone
	@expression(EP, eTotal_wood_biomass_consumed_per_zone_per_time[z in 1:Z, t in 1:T],
	sum(EP[:vBiomass_consumed_per_plant_per_time][i,t] for i in intersect(BIO_WOOD, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))

	#Woody biomass consumed equals to biomass utilized from supply curve
	@constraint(EP, cWood_biomass_consumed_per_zone[z in 1:Z, t in 1:T], EP[:eTotal_wood_biomass_consumed_per_zone_per_time][z,t] == EP[:vWood_biomass_utilized_per_zone_per_time][z,t])

	#####################################################################################################################################
	########################################################### Power Consumption #######################################################
	#####################################################################################################################################

	#Format for power balance
	@expression(EP, eBioPower_consumption_per_time_per_zone[t=1:T, z=1:Z], sum(EP[:vPower_BIO][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))

	#Format for output
	@expression(EP, eBioPower_consumption_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:vPower_BIO][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -EP[:eBioPower_consumption_per_time_per_zone]

	##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
	EP[:eBioNetpowerConsumptionByAll] += EP[:eBioPower_consumption_per_time_per_zone]

	#####################################################################################################################################
	########################################################### H2 Consumption ##########################################################
	#####################################################################################################################################

	#Format for H2 balance
	@expression(EP, eBioH2_consumption_per_time_per_zone[t=1:T, z=1:Z], sum(EP[:vH2_BIO][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))

	#Format for output
	@expression(EP, eBioH2_consumption_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:vH2_BIO][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))

	if setup["ParameterScale"] ==1
		@expression(EP,eScaled_BioH2_consumption_per_time_per_zone[t in 1:T,z in 1:Z], eBioH2_consumption_per_time_per_zone[t,z]*ModelScalingFactor) #HSC modules are not scaled, so we need convert to tonnes
	else
		@expression(EP,eScaled_BioH2_consumption_per_time_per_zone[t in 1:T,z in 1:Z], eBioH2_consumption_per_time_per_zone[t,z])
	end

	#Add to power balance to take power away from generated
	EP[:eH2Balance] += -EP[:eScaled_BioH2_consumption_per_time_per_zone]

	#####################################################################################################################################
	############################################### Electricity and H2 Conversion #######################################################
	#####################################################################################################################################
	
	#Power Balance
	# If ParameterScale = 1, power system operation/capacity modeled in GW, no need to scale as MW/ton = GW/kton 
	# If ParameterScale = 0, power system operation/capacity modeled in MW

	if setup["Bio_Electricity_On"] == 1
		#Bioelectricity demand
		@expression(EP,eBioelectricity_produced_MWh_per_plant_per_time[i in BIO_E, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioElectricity_yield_MWh_per_tonne][i])
		@expression(EP,eBioelectricity_produced_MWh_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBioelectricity_produced_MWh_per_plant_per_time][i,t] for i in intersect(BIO_E, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))

		EP[:ePowerBalance] += EP[:eBioelectricity_produced_MWh_per_time_per_zone]
		EP[:eBioNetpowerConsumptionByAll] -= EP[:eBioelectricity_produced_MWh_per_time_per_zone]
	end

	#####################################################################################################################################

	#HSC modules are not scaled, so we need convert to tonnes for ParameterScale = 1

	if setup["Bio_H2_On"] == 1
		#Biohydrogen demand
		@expression(EP,eBioH2_produced_tonne_per_plant_per_time[i in BIO_H2, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioH2_yield_tonne_per_tonne][i])
		@expression(EP,eBioH2_produced_tonne_per_time_per_zone[t in 1:T,z in 1:Z], sum(EP[:eBioH2_produced_tonne_per_plant_per_time][i,t] for i in intersect(BIO_H2, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
		
		if setup["ParameterScale"] ==1
			@expression(EP,eScaled_BioH2_produced_tonne_per_time_per_zone[t in 1:T,z in 1:Z], eBioH2_produced_tonne_per_time_per_zone[t,z]*ModelScalingFactor)
		else
			@expression(EP,eScaled_BioH2_produced_tonne_per_time_per_zone[t in 1:T,z in 1:Z], eBioH2_produced_tonne_per_time_per_zone[t,z])
		end

		EP[:eH2Balance] += EP[:eScaled_BioH2_produced_tonne_per_time_per_zone]
	end

	#####################################################################################################################################

	if setup["Bio_Gasoline_On"] == 1
		#Biogasoline demand
		@expression(EP,eBiogasoline_produced_MMBtu_per_plant_per_time[i in BIO_GASOLINE, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioGasoline_yield_MMBtu_per_tonne][i])
		@expression(EP,eBiogasoline_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiogasoline_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_GASOLINE, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eLFGasolineBalance] += EP[:eBiogasoline_produced_MMBtu_per_time_per_zone]
	
		####Constraining amount of syn fuel
		if setup["SpecifySynBioGasolinePercentFlag"] == 1
	
			percent_sbf_gasoline = setup["percent_sbf_gasoline"]
	
			#Sum up conventional gasoline production
			@expression(EP, eConvLFGasolineDemandT[t=1:T], sum(inputs["omega"][t]*EP[:vConvLFGasolineDemand][t, z] for z in 1:Z))
			@expression(EP, eConvLFGasolineDemandTZ, sum(eConvLFGasolineDemandT[t] for t in 1:T))
	
			#Sum up syngasoline production
			@expression(EP, eSynFuelProd_GasolineT[t=1:T], sum(inputs["omega"][t]*EP[:eSynFuelProd_Gasoline][t, z] for z in 1:Z))
			@expression(EP, eSynFuelProd_GasolineTZ, sum(eSynFuelProd_GasolineT[t] for t in 1:T))
	
			#Sum up biogasoline production
			@expression(EP, eBioFuelProd_GasolineT[t=1:T], sum(inputs["omega"][t]*EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t, z] for z in 1:Z))
			@expression(EP, eBioFuelProd_GasolineTZ, sum(eBioFuelProd_GasolineT[t] for t in 1:T))
		
			@constraint(EP, cBioFuelGasolineShare, (percent_sbf_gasoline - 1) * (eBioFuelProd_GasolineTZ + eSynFuelProd_GasolineTZ) + percent_sbf_gasoline *  eConvLFGasolineDemandTZ == 0)
	
		end 
	
		#Emissions from biogasoline utilization
		Bio_gasoline_co2_per_mmbtu = inputs["Bio_gasoline_co2_per_mmbtu"]
	
		if setup["ParameterScale"] ==1
			#CO2 emitted as a result of bio gasoline consumption
			@expression(EP,eBio_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_gasoline_co2_per_mmbtu * EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z]/ModelScalingFactor)
		else
			#CO2 emitted as a result of bio gasoline consumption
			@expression(EP,eBio_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_gasoline_co2_per_mmbtu * EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z])
		end
	else
		@expression(EP,eBio_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end

	#####################################################################################################################################

	if setup["Bio_Jetfuel_On"] == 1
		#Biojetfuel demand
		@expression(EP,eBiojetfuel_produced_MMBtu_per_plant_per_time[i in BIO_GASOLINE, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioJetfuel_yield_MMBtu_per_tonne][i])
		@expression(EP,eBiojetfuel_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiojetfuel_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_GASOLINE, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eLFJetfuelBalance] += EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone]
	
		####Constraining amount of syn fuel
		if setup["SpecifySynBioJetfuelPercentFlag"] == 1
	
			percent_sbf_jetfuel = setup["percent_sbf_jetfuel"]
	
			#Sum up conventional jetfuel production
			@expression(EP, eConvLFJetfuelDemandT[t=1:T], sum(inputs["omega"][t]*EP[:vConvLFJetfuelDemand][t, z] for z in 1:Z))
			@expression(EP, eConvLFJetfuelDemandTZ, sum(eConvLFJetfuelDemandT[t] for t in 1:T))
	
			#Sum up synjetfuel production
			@expression(EP, eSynFuelProd_JetfuelT[t=1:T], sum(inputs["omega"][t]*EP[:eSynFuelProd_Jetfuel][t, z] for z in 1:Z))
			@expression(EP, eSynFuelProd_JetfuelTZ, sum(eSynFuelProd_JetfuelT[t] for t in 1:T))
	
			#Sum up biojetfuel production
			@expression(EP, eBioFuelProd_JetfuelT[t=1:T], sum(inputs["omega"][t]*EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t, z] for z in 1:Z))
			@expression(EP, eBioFuelProd_JetfuelTZ, sum(eBioFuelProd_JetfuelT[t] for t in 1:T))
		
			@constraint(EP, cBioFuelJetfuelShare, (percent_sbf_jetfuel - 1) * (eBioFuelProd_JetfuelTZ + eSynFuelProd_JetfuelTZ) + percent_sbf_jetfuel *  eConvLFJetfuelDemandTZ == 0)
	
		end 
	
		#Emissions from biojetfuel utilization
		Bio_jetfuel_co2_per_mmbtu = inputs["Bio_jetfuel_co2_per_mmbtu"]
	
		if setup["ParameterScale"] ==1
			#CO2 emitted as a result of bio jetfuel consumption
			@expression(EP,eBio_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_jetfuel_co2_per_mmbtu * EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z]/ModelScalingFactor)
		else
			#CO2 emitted as a result of bio jetfuel consumption
			@expression(EP,eBio_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_jetfuel_co2_per_mmbtu * EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z])
		end
	else
		@expression(EP,eBio_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end

	#####################################################################################################################################

	if setup["Bio_Diesel_On"] == 1
		#Biodiesel demand
		@expression(EP,eBiodiesel_produced_MMBtu_per_plant_per_time[i in BIO_DIESEL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioDiesel_yield_MMBtu_per_tonne][i])
		@expression(EP,eBiodiesel_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiodiesel_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_DIESEL, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eLFDieselBalance] += EP[:eBiodiesel_produced_MMBtu_per_time_per_zone]
	
		####Constraining amount of syn fuel
		if setup["SpecifySynBioDieselPercentFlag"] == 1
	
			percent_sbf_diesel = setup["percent_sbf_diesel"]
	
			#Sum up conventional diesel production
			@expression(EP, eConvLFDieselDemandT[t=1:T], sum(inputs["omega"][t]*EP[:vConvLFDieselDemand][t, z] for z in 1:Z))
			@expression(EP, eConvLFDieselDemandTZ, sum(eConvLFDieselDemandT[t] for t in 1:T))

			#Sum up syndiesel production
			@expression(EP, eSynFuelProd_DieselT[t=1:T], sum(inputs["omega"][t]*EP[:eSynFuelProd_Diesel][t, z] for z in 1:Z))
			@expression(EP, eSynFuelProd_DieselTZ, sum(eSynFuelProd_DieselT[t] for t in 1:T))

			#Sum up biodiesel production
			@expression(EP, eBioFuelProd_DieselT[t=1:T], sum(inputs["omega"][t]*EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t, z] for z in 1:Z))
			@expression(EP, eBioFuelProd_DieselTZ, sum(eBioFuelProd_DieselT[t] for t in 1:T))
		
			@constraint(EP, cBioFuelDieselShare, (percent_sbf_diesel - 1) * (eBioFuelProd_DieselTZ + eSynFuelProd_DieselTZ) + percent_sbf_diesel *  eConvLFDieselDemandTZ == 0)
	
		end 
	
		#Emissions from biodiesel utilization
		Bio_diesel_co2_per_mmbtu = inputs["Bio_diesel_co2_per_mmbtu"]
	
		if setup["ParameterScale"] ==1
			#CO2 emitted as a result of bio diesel consumption
			@expression(EP,eBio_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_diesel_co2_per_mmbtu * EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z]/ModelScalingFactor)
		else
			#CO2 emitted as a result of bio diesel consumption
			@expression(EP,eBio_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_diesel_co2_per_mmbtu * EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z])
		end
	else
		@expression(EP,eBio_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end
	
	#####################################################################################################################################
	
	if setup["Bio_Ethanol_On"] == 1
		#Bioethanol demand
		@expression(EP,eBioethanol_produced_MMBtu_per_plant_per_time[i in BIO_ETHANOL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioEthanol_yield_MMBtu_per_tonne][i])
		@expression(EP,eBioethanol_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBioethanol_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_ETHANOL, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eEthanolBalance] += EP[:eBioethanol_produced_MMBtu_per_time_per_zone]
	
		#Emissions from bioethanol utilization
		Bio_ethanol_co2_per_mmbtu = inputs["Bio_ethanol_co2_per_mmbtu"]
	
		if setup["ParameterScale"] ==1
			#CO2 emitted as a result of bio ethanol consumption
			@expression(EP,eBio_Ethanol_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_ethanol_co2_per_mmbtu * EP[:eBioethanol_produced_MMBtu_per_time_per_zone][t,z]/ModelScalingFactor)
		else
			#CO2 emitted as a result of bio ethanol consumption
			@expression(EP,eBio_Ethanol_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
			Bio_ethanol_co2_per_mmbtu * EP[:eBioethanol_produced_MMBtu_per_time_per_zone][t,z])
		end
	else
		@expression(EP,eBio_Ethanol_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end
	
	#####################################################################################################################################
	
	#For output only, generate the bioelectricity/biohydrogen production of all plants
	@expression(EP,eBioelectricity_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioElectricity_yield_MWh_per_tonne][i])
	@expression(EP,eBiohydrogen_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioH2_yield_tonne_per_tonne][i])
	@expression(EP,eBiodiesel_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioDiesel_yield_MMBtu_per_tonne][i])
	@expression(EP,eBiojetfuel_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioJetfuel_yield_MMBtu_per_tonne][i])
	@expression(EP,eBiogasoline_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioGasoline_yield_MMBtu_per_tonne][i])
	@expression(EP,eBioethanol_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioEthanol_yield_MMBtu_per_tonne][i])
	
    return EP

end
