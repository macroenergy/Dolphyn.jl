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
	
	println(" -- Bioenergy Production Module")

	dfbioenergy = inputs["dfbioenergy"]
	BIO_RES_ALL = inputs["BIO_RES_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	BIO_RES_ALL = inputs["BIO_RES_ALL"]
	BIO_HERB = inputs["BIO_HERB"]
	BIO_WOOD = inputs["BIO_WOOD"]
	
	BIO_H2 = inputs["BIO_H2"]
	BIO_ELEC = inputs["BIO_ELEC"]
	BIO_DIESEL = inputs["BIO_DIESEL"]
	BIO_GASOLINE = inputs["BIO_GASOLINE"]
	BIO_NG = inputs["BIO_NG"]

	#####################################################################################################################################
	######################################### Power/H2 consumption and Plant Operational Constraints ####################################
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
	@expression(EP, eTotal_herb_biomass_consumed_per_zone_per_time[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time][i,t] for i in intersect(BIO_HERB, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eHerb_Biomass_Supply] -= EP[:eTotal_herb_biomass_consumed_per_zone_per_time]

	#####################################################################################################################################
	#Woody biomass consumed per zone
	@expression(EP, eTotal_wood_biomass_consumed_per_zone_per_time[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time][i,t] for i in intersect(BIO_WOOD, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eWood_Biomass_Supply] -= EP[:eTotal_wood_biomass_consumed_per_zone_per_time]

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

	@expression(EP,eScaled_BioH2_consumption_per_time_per_zone[t in 1:T,z in 1:Z], eBioH2_consumption_per_time_per_zone[t,z])

	#Add to power balance to take power away from generated
	EP[:eH2Balance] += -EP[:eScaled_BioH2_consumption_per_time_per_zone]

	#####################################################################################################################################
	############################################### Electricity and H2 Conversion #######################################################
	#####################################################################################################################################
	
	#Power Balance
	if setup["Bio_Electricity_On"] == 1
		#Bioelectricity demand
		@expression(EP,eBioelectricity_produced_MWh_per_plant_per_time[i in BIO_ELEC, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioElectricity_yield_MWh_per_tonne][i])
		@expression(EP,eBioelectricity_produced_MWh_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBioelectricity_produced_MWh_per_plant_per_time][i,t] for i in intersect(BIO_ELEC, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))

		EP[:ePowerBalance] += EP[:eBioelectricity_produced_MWh_per_time_per_zone]
		EP[:eBioNetpowerConsumptionByAll] -= EP[:eBioelectricity_produced_MWh_per_time_per_zone]
	end

	#####################################################################################################################################

	if setup["Bio_H2_On"] == 1
		#Biohydrogen demand
		@expression(EP,eBioH2_produced_tonne_per_plant_per_time[i in BIO_H2, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioH2_yield_tonne_per_tonne][i])
		@expression(EP,eBioH2_produced_tonne_per_time_per_zone[t in 1:T,z in 1:Z], sum(EP[:eBioH2_produced_tonne_per_plant_per_time][i,t] for i in intersect(BIO_H2, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
		
		@expression(EP,eScaled_BioH2_produced_tonne_per_time_per_zone[t in 1:T,z in 1:Z], eBioH2_produced_tonne_per_time_per_zone[t,z])

		EP[:eH2Balance] += EP[:eScaled_BioH2_produced_tonne_per_time_per_zone]
	end

	#####################################################################################################################################

	if setup["Bio_Gasoline_On"] == 1
		#Biogasoline demand
		@expression(EP,eBiogasoline_produced_MMBtu_per_plant_per_time[i in BIO_GASOLINE, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioGasoline_yield_MMBtu_per_tonne][i])
		@expression(EP,eBiogasoline_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiogasoline_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_GASOLINE, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eSBFGasolineBalance] += EP[:eBiogasoline_produced_MMBtu_per_time_per_zone]
	
		#Emissions from biogasoline utilization
		Bio_gasoline_co2_per_mmbtu = inputs["Bio_gasoline_co2_per_mmbtu"]
	
		#CO2 emitted as a result of bio gasoline consumption
		@expression(EP,eBio_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
		Bio_gasoline_co2_per_mmbtu * EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z])

	else
		@expression(EP,eBio_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end

	#####################################################################################################################################

	if setup["Bio_Jetfuel_On"] == 1
		#Biojetfuel demand
		@expression(EP,eBiojetfuel_produced_MMBtu_per_plant_per_time[i in BIO_GASOLINE, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioJetfuel_yield_MMBtu_per_tonne][i])
		@expression(EP,eBiojetfuel_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiojetfuel_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_GASOLINE, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eSBFJetfuelBalance] += EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone]

		#Emissions from biojetfuel utilization
		Bio_jetfuel_co2_per_mmbtu = inputs["Bio_jetfuel_co2_per_mmbtu"]
	
		#CO2 emitted as a result of bio jetfuel consumption
		@expression(EP,eBio_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
		Bio_jetfuel_co2_per_mmbtu * EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z])

	else
		@expression(EP,eBio_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end

	#####################################################################################################################################

	if setup["Bio_Diesel_On"] == 1
		#Biodiesel demand
		@expression(EP,eBiodiesel_produced_MMBtu_per_plant_per_time[i in BIO_DIESEL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioDiesel_yield_MMBtu_per_tonne][i])
		@expression(EP,eBiodiesel_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiodiesel_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_DIESEL, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eSBFDieselBalance] += EP[:eBiodiesel_produced_MMBtu_per_time_per_zone]
	
		#Emissions from biodiesel utilization
		Bio_diesel_co2_per_mmbtu = inputs["Bio_diesel_co2_per_mmbtu"]
	
		#CO2 emitted as a result of bio diesel consumption
		@expression(EP,eBio_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
		Bio_diesel_co2_per_mmbtu * EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z])

	else
		@expression(EP,eBio_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end
	
	#####################################################################################################################################

	if setup["Bio_NG_On"] == 1
		#Bio NG demand
		@expression(EP,eBio_NG_produced_MMBtu_per_plant_per_time[i in BIO_NG, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Bio_NG_yield_MMBtu_per_tonne][i])
		@expression(EP,eBio_NG_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBio_NG_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(BIO_NG, dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID])))
	
		EP[:eSB_NG_Balance] += EP[:eBio_NG_produced_MMBtu_per_time_per_zone] #Add to syn + bio gas balance: For conv NG share policy
		EP[:eNGBalance] += EP[:eBio_NG_produced_MMBtu_per_time_per_zone]
	
		#Emissions from bio NG utilization
		Bio_ng_co2_per_mmbtu = inputs["ng_co2_per_mmbtu"]
	
		#CO2 emitted as a result of bio NG consumption
		@expression(EP,eBio_NG_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
		Bio_ng_co2_per_mmbtu * EP[:eBio_NG_produced_MMBtu_per_time_per_zone][t,z])
	
	else
		@expression(EP,eBio_NG_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 0)
	end
	
	#####################################################################################################################################
	
	#For output only, generate the bioelectricity/biohydrogen production of all plants
	@expression(EP,eBioelectricity_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioElectricity_yield_MWh_per_tonne][i])
	@expression(EP,eBiohydrogen_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioH2_yield_tonne_per_tonne][i])
	@expression(EP,eBiodiesel_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioDiesel_yield_MMBtu_per_tonne][i])
	@expression(EP,eBiojetfuel_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioJetfuel_yield_MMBtu_per_tonne][i])
	@expression(EP,eBiogasoline_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:BioGasoline_yield_MMBtu_per_tonne][i])
	@expression(EP,eBio_NG_produced_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Bio_NG_yield_MMBtu_per_tonne][i])
	
    return EP

end
