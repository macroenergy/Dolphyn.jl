# HSC Database Documentation

## 1 Model setup parameters

Model settings parameters are specified in a `hsc_Settings.yml` file which should be located in the current working directory (or to specify an alternative location, edit the `settings_path` variable in your `Run.jl` file). Settings include those related to model structure, solution strategy and outputs, policy constraints, and others. Model structure related settings parameter affects the formulation of the model constraint and objective functions. Computational performance related parameters affect the accuracy of the solution. Policy related parameters specify the policy type and policy goal. Network related parameters specify settings related to transmission network expansion and losses. Note that all settings parameters are case sensitive.

###### Table 1a: Summary of the Model settings parameters
---
|**Settings Parameter** | **Description**|
| :------------ | :-----------|
|**Model structure related**||
|ModelH2 | Flag to turn or off Hydrogen Supply Chain modelling capabilities.|
||0 = no hydrogen supply chain modeling.
||1 = modeling hydrogen supply chain.|
|NetworkExpansion | Flag for activating or deactivating inter-regional transmission expansion.|
||1 = active|
||0 = modeling single zone or for multi-zone problems, inter regional transmission expansion is not allowed.|
|ModelH2Pipelines | Whether to model pipeline in hydrogen supply chain. |
||0 = not modeling hydrogen pipelines (no transmission).|
||1 = modeling hydrogen pipelines (with transmission).|
|H2PipeInteger |Whether to model pipeline capacity as discrete or integer. |
||0 = continuous capacity of hydrogen pipeline.|
||1 = discrete capacity of hydrogen pipeline.|
|ModelH2Trucks | Whether to model truck in hydrogen supply chain. |
||0 = not modeling hydrogen trucks. |
||1 = modeling hydrogen trucks. |
|H2GenCommit | Select technical resolution of of modeling thermal generators.|
||0 = no unit commitment.|
||1 = unit commitment with integer clustering.|
||2 = unit commitment with linearized clustering.|
|H2G2PCommit | Select technical resolution of of modeling gas to power generators.|
||0 = no unit commitment.|
||1 = unit commitment with integer clustering.|
||2 = unit commitment with linearized clustering.|

|**Policy related**|
|H2CO2Cap | Flag for specifying the type of CO2 emission limit constraint.|
|| 0 = no CO2 emission limit|
|| 1 = mass-based emission limit constraint|
|| 2 = load + rate-based emission limit constraint|
|| 3 = generation + rate-based emission limit constraint|

## 2 Inputs

All input files are in CSV format. Running the GenX submodule requires a minimum of five input files. Additionally, the user may need to specify five more input files based on model configuration and type of scenarios of interest. Names of the input files and their functionality is given below. Note that names of the input files are case sensitive.


###### Table 2: Summary of the input files
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Files**||
|HSC\_pipelines.csv |Specify network topology, transmission fixed costs, capacity and loss parameters.|
|HSC\_load\_data.csv |Specify time-series of load profiles for each model zone, weights for each time step, hydrogen load shedding costs, and optional time domain reduction parameters.|
|HSC\_generators\_variability.csv |Specify time-series of capacity factor/availability for each resource.|
|HSC\_generation\_data.csv |Specify cost and performance data for generation and storage resources.|
|**Settings-specific Files**||
|HSC\_CO2\_cap.csv |Specify regional CO2 emission limits.|


### 2.1 Mandatory input data
#### 2.1.2 HSC_pipelines.csv

This input file contains input parameters related to: 1) definition of model zones (regions between which transmission flows are explicitly modeled) and 2) definition of transmission network topology, existing capacity, losses and reinforcement costs. The following table describe each of the mandatory parameter inputs need to be specified to run an instance of the model, along with comments for the model configurations when they are needed.

###### Table 3: Structure of the HSC_pipelines.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Settings-specific Columns**|
|**Multiple zone model**||
|H2_Pipelines | Index numebr of existing and candidate hydrogen pipelines.|
|Max_No_Pipe | Maximum capacity of hydrogen pipelines.|
|Existing_No_Pipe | Existing capacity of hydrogen pipelines.|
|Max_Flow_Tonne_p_Hr_Per_Pipe | Maximum flow rate per hydrogen pipeline.|
|H2Pipe_Inv_Cost_per_mile_yr | Annulized investment cost per hydrogen pipeline per mile.|
|Pipe_length_miles | Hydrogen pipeline length in miles.|
|H2PipeCap_tonne_per_mile | Maximum storage capacity per hydrogen pipeline per mile.|
|Min_pipecap_stor_frac | Minimum storage capacity per hydrogen pipeline percentage.|
|len_bw_comp_mile | Length between two compression boosters in miles.|
|BoosterCompCapex_per_tonne_p_hr_yr | Annulized investment cost per compression booster.|
|BoosterCompEnergy_MWh_per_tonne | Electricity consumption per tonne of hydrogen in MWh.|
|H2PipeCompCapex | Annulized investment cost for compression compressor.|
|H2PipeCompEnergy | Energy consumption for compression compressor.|

#### 2.1.3 HSC\_load\_data.csv

This file includes parameters to characterize model temporal resolution to approximate annual grid operations, hydrogen demand for each time step for each zone, and cost of load shedding. Note that DOLPHYN is designed to model hourly time steps. With some care and effort, finer (e.g. 15 minute) or courser (e.g. 2 hour) time steps can be modeled so long as all time-related parameters are scaled appropriately (e.g. time period weights, heat rates, ramp rates and minimum up and down times for generators, variable costs, etc).

###### Table 4: Structure of the HSC\_Load\_data.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Columns**|
|Voll |Value of lost hydrogen load in $/tonne-H2.|
|Demand\_Segment |Number of demand curtailment/lost load segments with different cost and capacity of curtailable demand for each segment. User-specified demand segments. Integer values starting with 1 in the first row. Additional segements added in subsequent rows.|
|Cost\_of\_Demand\_Curtailment\_per\_Tonne |Cost of non-served energy/demand curtailment (for each segment), reported as a fraction of value of lost load. If *Demand\_Segment = 1*, then this parameter is a scalar and equal to one. In general this parameter is a vector of length equal to the length of Demand\_Segment.|
|Max\_Demand\_Curtailment| Maximum time-dependent demand curtailable in each segment, reported as % of the demand in each zone and each period. *If Demand\_Segment = 1*, then this parameter is a scalar and equal to one. In general this parameter is a vector of length given by length of Demand\_segment.|
|Time\_Index |Index defining time step in the model.|
|Load\_H2\_tonne\_per\_hr\_z* |Load profile of a zone z* in tonne/hr; if multiple zones, this parameter will be a matrix with columns equal to number of zones (each column named appropriate zone number appended to parameter) and rows equal to number of time periods of grid operations being modeled.|

#### 2.1.4 HSC\_generator\_variability.csv

This file contains the time-series of capacity factors / availability of each resource included in the `HSC_generators_data.csv` file for each time step (e.g. hour) modeled.

• first column: The first column contains the time index of each row (starting in the second row) from 1 to N.

• Second column onwards: Resources are listed from the second column onward with headers matching each resource name in the `HSC_generators_data.csv` file in any order. The availability for each resource at each time step is defined as a fraction of installed capacity and should be between 0 and 1. 

#### 2.1.5 HSC\_generators\_data.csv

This file contains cost and performance parameters for various generators and other resources like hydrogen storage included in the model formulation.

###### Table 5: Mandatory columns in the HSC\_generators\_data.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|H2_Resource | This column contains **unique** names of resources available to the model. Resources can include generators, storage.|
|Zone | Integer representing zone number where the resource is located. |
|**Technology type flags**|
|New\_Build | {-1, 0, 1}, Flag for resource (storage, generation) eligibility for capacity expansion.|
||New\_Build = 1: eligible for capacity expansion and retirement. |
||New\_Build = 0: not eligible for capacity expansion, eligible for retirement.|
||New\_Build = -1: not eligible for capacity expansion or retirement.|
|H2_GEN_TYPE | {0, 1, 2}, Flag to indicate membership in set of thermal resources (e.g. nuclear, combined heat and power, natural gas combined cycle, coal power plant)|
||H2\_GEN\_TYPE = 0: Not part of set (default) |
||H2\_GEN\_TYPE = 1: If the power plant relies on thermal energy input and subject unit commitment constraints/decisions if `UCommit >= 1` (e.g. cycling decisions/costs/constraints). |
||H2\_GEN\_TYPE = 2: If the power plant relies on thermal energy input and is subject to simplified economic dispatch constraints (ramping limits and minimum output level but no cycling decisions/costs/constraints). |
|Cap\_Size\_tonne\_p\_hr | Size (tonne/hr) of a single generating unit. This is used only for resources with integer unit commitment (`THERM = 1`) - not relevant for other resources.|
|H2\_STOR | {0, 1, 2}, Flag to indicate membership in set of storage resources and designate which type of storage resource formulation to employ.|
||H2\_STOR = 0: Not part of set (default) |
||H2\_STOR = 1: Discharging power capacity and energy capacity are the investment decision variables; symmetric charge/discharge power capacity with charging capacity equal to discharging capacity (e.g. lithium-ion battery storage).|
||H2\_STOR = 2: Discharging, charging power capacity and energy capacity are investment variables; asymmetric charge and discharge capacities using distinct processes (e.g. hydrogen electrolysis, storage, and conversion to power using fuel cell or combustion turbine).|
|H2\_FLEX | {0, 1}, Flag to indicate membership in set of flexible demand-side resources (e.g. scheduleable or time shiftable loads such as automated EV charging, smart thermostat systems, irrigating pumping loads etc).|
||H2\_FLEX = 0: Not part of set (default) |
||H2\_FLEX = 1: Flexible demand resource.|
|**Existing technology capacity**|
|Existing\_Cap\_tonne\_p\_hr |The existing capacity of a power plant in tonne/hr.|
|Existing\_Energy\_Cap\_tonne |The existing capacity of storage in tonne where `H2_STOR = 1` or `H2_STOR = 2`.|
|Existing\_Charge\_Cap\_p\_hr |The existing charging capacity for resources where `H2_STOR = 2`.|
|**Capacity/Energy requirements**|
|Max\_Cap\_tonne\_p\_hr |-1 (default) – no limit on maximum discharge capacity of the resource. If non-negative, represents maximum allowed discharge capacity (in tonne/hr) of the resource.|
|Max\_Energy\_Cap\_tonne |-1 (default) – no limit on maximum energy capacity of the resource. If non-negative, represents maximum allowed energy capacity (in tonne) of the resource with `H2_STOR = 1` or `H2_STOR = 2`.|
|Max\_Charge\_Cap\_tonne\_p\_hr |-1 (default) – no limit on maximum charge capacity of the resource. If non-negative, represents maximum allowed charge capacity (in tonne/hr) of the resource with `H2_STOR = 2`.|
|Min\_Energy\_Cap\_tonne |-1 (default) – no limit on minimum discharge capacity of the resource. If non-negative, represents minimum allowed discharge capacity (in tonne/hr) of the resource.|
|Min\_Cap\_tonne\_p\_hr| -1 (default) – no limit on minimum energy capacity of the resource. If non-negative, represents minimum allowed energy capacity (in tonne) of the resource with `H2_STOR = 1` or `H2_STOR = 2`.|
|Min\_Charge\_Cap\_tonne\_p\_hr |-1 (default) – no limit on minimum charge capacity of the resource. If non-negative, represents minimum allowed charge capacity (in tonne/hr) of the resource with `H2_STOR = 2`.|
|**Cost parameters**|
|Inv\_Cost\_p\_tonne\_p\_hr\_yr | Annualized capacity investment cost of a technology ($/tonne/hr/year). |
|Inv\_Cost\_Energy\_p\_tonne\_yr | Annualized investment cost of the energy capacity for a storage technology ($/tonne/hr/year), applicable to either `H2_STOR = 1` or `H2_STOR = 2`. |
|Inv\_Cost\_Charge\_p\_tonne\_p\_hr\_yr | Annualized capacity investment cost for the charging portion of a storage technology with `H2_STOR = 2` ($/tonne/hr/year). |
|Fixed\_OM\_Cost\_p\_tonne\_p\_hr\_yr | Fixed operations and maintenance cost of a technology ($/tonne/hr/year). |
|Fixed\_OM\_Cost\_Energy\_p\_tonne\_yr | Fixed operations and maintenance cost of the energy component of a storage technology ($/tonne/year). |
|Fixed\_OM\_Cost\_Charge\_p\_tonne\_p\_hr\_yr | Fixed operations and maintenance cost of the charging component of a storage technology of type `H2_STOR = 2`. |
|Var\_OM\_Cost\_p\_tonne | Variable operations and maintenance cost of a technology ($/tonne). |
|Var\_OM\_Cost\_Charge\_p\_tonne | Variable operations and maintenance cost of the charging aspect of a storage technology with `H2_STOR = 2`. |
|**Technical performance parameters**|
|etaFuel\_MMBtu\_p\_tonne  |Heat rate of a generator or MMBtu of fuel consumed per tonne of electricity generated for export (net of on-site house loads). The heat rate is the inverse of the efficiency: a lower heat rate is better. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|Fuel  |Fuel needed for a generator. The names should match with the ones in the `Fuels_data.csv`. |
|etaP2G\_MWh\_p\_tonne | Power generation per tonne of hydrogen consumption.|
|H2Stor\_self\_discharge\_rate\_p\_hour |[0,1], The power loss of storage technologies per hour (fraction loss per hour)- only applies to storage techs.|
|H2Gen\_min\_output |[0,1], The minimum generation level for a unit as a fraction of total capacity. |
|H2Stor\_min\_level |[0,1], The minimum storage level for a unit as a fraction of total capacity. |
|H2Stor\_max\_level |[0,1], The maximum storage level for a unit as a fraction of total capacity. |
|H2Stor\_Charge\_MWh\_p\_tonne | Energy consumption for charging hydrogen into storage devices for all storage types. |
|H2Stor\_Charge\_MMBtu\_p\_tonne | Fuel consumption for charging hydrogen into storage devices for all storage types. |
|Ramp\_Up\_Percentage |[0,1], Maximum increase in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|Ramp\_Dn\_Percentage |[0,1], Maximum decrease in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|H2Stor\_eff\_charge  |[0,1], Efficiency of charging storage – applies to storage technologies (all storage types). |
|H2Stor\_eff\_discharge  |[0,1], Efficiency of discharging storage – applies to storage technologies (all storage types). |
|**Required for writing outputs**|
|region | Name of the model region|
|cluster | Number of the cluster when representing multiple clusters of a given technology in a given region.  |

###### Table 6: Settings-specific columns in the HSC\_generators\_data.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**H2GenCommit >= 1** | The following settings apply only to thermal plants with unit commitment constraints (`H2_GEN_TYPE = 1`).|
|Up\_Time| Minimum amount of time a resource has to stay in the committed state.|
|Down\_Time |Minimum amount of time a resource has to remain in the shutdown state.|
|Start\_Cost\_per\_tonne\_p\_hr |Cost per tonne/hr of nameplate capacity to start a generator ($/tonne/hr per start). Multiplied by the number of generation units (each with a pre-specified nameplate capacity) that is turned on.|

### 2.2 Optional input data

#### 2.2.1 HSC\_CO2\_cap.csv

This file contains inputs specifying CO2 emission limits policies (e.g. emissions cap and permit trading programs). This file is needed if `H2CO2Cap` flag is activated in the YAML file `hsc_settings.yml`. `h2CO2Cap` flag set to 1 represents mass-based (tCO2 ) emission target. `CO2Cap` flag set to 2 is specified when emission target is given in terms of rate (tCO2/tonne-H2) and is based on total demand met. `H2CO2Cap` flag set to 3 is specified when emission target is given in terms of rate (tCO2 /tonne-H2) and is based on total generation.

###### Table 6: Structure of the HSC\_CO2\_cap.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|Network\_zones| zone number represented as z*|
|CO\_2\_Cap\_Zone* |If a zone is eligible for the emission limit constraint, then this column is set to 1, else 0.|
|CO\_2\_Max\_tons\_ton* |Emission limit in terms of rate|
|CO\_2\_Max\_Mtons* |Emission limit in absolute values, in Million of tons |
| | where in the above inputs, * represents the number of the emission limit constraints. For example, if the model has 2 emission limit constraints applied separately for 2 zones, the above CSV file will have 2 columns for specifying emission limit in terms on rate: CO\_2\_Max\_tons\_ton\_1 and CO\_2\_Max\_tons\_ton_\_2.|

#### 2.2.2 HSC\_G2P.csv

This file contains cost and performance parameters for various hydrogen to power resources included in the model formulation.

###### Table 7: Mandatory columns in the HSC\_G2P.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|H2_Resource | This column contains **unique** names of resources available to the model. Resources can include generators, storage.|
|Zone | Integer representing zone number where the resource is located. |
|**Technology type flags**|
|New\_Build | {-1, 0, 1}, Flag for resource (storage, generation) eligibility for capacity expansion.|
||New\_Build = 1: eligible for capacity expansion and retirement. |
||New\_Build = 0: not eligible for capacity expansion, eligible for retirement.|
||New\_Build = -1: not eligible for capacity expansion or retirement.|
||Cap\_size\_MW | Size (MW) of a single generating unit. This is used only for resources with integer unit commitment - not relevant for other resources.|
|**Existing technology capacity**|
|Existing\_Cap\_MW |The existing capacity of a power plant in tonne/hr.|
|**Capacity/Energy requirements**|
|Max\_Cap\_MW |-1 (default) – no limit on maximum discharge capacity of the resource. If non-negative, represents maximum allowed discharge capacity (in tonne/hr) of the resource.|
|Min\_Cap\_MW | -1 (default) – no limit on minimum energy capacity of the resource. If non-negative, represents minimum allowed energy capacity (in tonne) of the resource with `H2_STOR = 1` or `H2_STOR = 2`.|
Cap_Size_MW
|**Cost parameters**|
|Inv\_Cost\_p\_MW\_p\_yr | Annualized capacity investment cost of a technology ($/MW/year). |
|Fixed\_OM\_p\_MW\_yr | Fixed operations and maintenance cost of a technology ($/MW/year). |
`H2_STOR = 2`. |
|Var\_OM\_Cost\_p\_MWh | Variable operations and maintenance cost of a technology ($/tonne). |
|**Technical performance parameters**|
|etaFuel\_MMBtu\_p\_tonne  |Heat rate of a generator or MMBtu of fuel consumed per tonne of electricity generated for export (net of on-site house loads). The heat rate is the inverse of the efficiency: a lower heat rate is better. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|etaG2P\_MWh\_p\_tonne | Power generation per tonne of hydrogen consumption.|
|G2P\_min\_output |[0,1], The minimum generation level for a unit as a fraction of total capacity. |
|Ramp\_Up\_Percentage |[0,1], Maximum increase in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|Ramp\_Dn\_Percentage |[0,1], Maximum decrease in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|**Required for writing outputs**|
|region | Name of the model region|
|cluster | Number of the cluster when representing multiple clusters of a given technology in a given region.  |

###### Table 8: Settings-specific columns in the HSC\_G2P.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**H2G2PCommit >= 1** | The following settings apply only to thermal plants with unit commitment constraints.|
|Up\_Time| Minimum amount of time a resource has to stay in the committed state.|
|Down\_Time |Minimum amount of time a resource has to remain in the shutdown state.|
|Start\_Cost\_per\_MW |Cost per tonne/hr of nameplate capacity to start a generator ($/tonne/hr per start). Multiplied by the number of generation units (each with a pre-specified nameplate capacity) that is turned on.|

#### 2.2.3 HSC\_g2p\_generators\_variability.csv

This file contains the time-series of capacity factors / availability of each resource included in the `HSC_G2P.csv` file for each time step (e.g. hour) modeled.

• first column: The first column contains the time index of each row (starting in the second row) from 1 to N.

• Second column onwards: Resources are listed from the second column onward with headers matching each resource name in the `HSC_generators_data.csv` file in any order. The availability for each resource at each time step is defined as a fraction of installed capacity and should be between 0 and 1.

## 3 Outputs
