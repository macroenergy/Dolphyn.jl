# BESC Database Documentation

## 1 Model setup parameters

Model settings parameters are specified in a `besc_Settings.yml` file which should be located in the current working directory (or to specify an alternative location, edit the `settings_path` variable in your `Run.jl` file). Settings include those related to model structure, solution strategy and outputs, policy constraints, and others. Model structure related settings parameter affects the formulation of the model constraint and objective functions. Computational performance related parameters affect the accuracy of the solution. Policy related parameters specify the policy type and policy goal. Note that all settings parameters are case sensitive.

###### Table 1a: Summary of the Model settings parameters
---
|**Settings Parameter** | **Description**|
| :------------ | :-----------|
|**Model structure related**||
|ModelBESC | Flag to turn or off Bioenergy Supply Chain modelling capabilities.|
||0 = no bioenergy supply chain modeling.
||1 = modeling bioenergy supply chain.|
|Bio\_H2\_On | Flag for activating or deactivating modeling of bio hydrogen.|
||0 = not modeling bio hydrogen.|
||1 = modeling bio hydrogen.|
|Bio\_Electricity\_On | Flag for activating or deactivating modeling of bio electricity.|
||0 = not modeling bio electricity.|
||1 = modeling bio electricity.|
|Bio\_Diesel\_On | Flag for activating or deactivating modeling of bio diesel.|
||0 = not modeling bio diesel.|
||1 = modeling bio diesel.|
|Bio\_Jetfuel\_On | Flag for activating or deactivating modeling of bio jetfuel.|
||0 = not modeling bio jetfuel.|
||1 = modeling bio jetfuel.|
|Bio\_Gasoline\_On | Flag for activating or deactivating modeling of bio gasoline.|
||0 = not modeling bio gasoline.|
||1 = modeling bio gasoline.|


## 2 Inputs

All input files are in CSV format. Running the GenX submodule requires a minimum of five input files. Additionally, the user may need to specify five more input files based on model configuration and type of scenarios of interest. Names of the input files and their functionality is given below. Note that names of the input files are case sensitive.


###### Table 2: Summary of the input files
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Files**||
|BESC\_Biorefinery.csv |Specify cost and performance data for biorefinery resources.|
|BESC\_Herb\_Supply.csv |Specify quantity, cost and emissions of herbaceous biomass supply.|
|BESC\_Wood\_Supply.csv |Specify quantity, cost and emissions of woody biomass supply.|

### 2.1 Mandatory input data
#### 2.1.1 BESC\_Biorefinery.csv

This file contains cost and performance parameters for various biorefinery resources included in the model formulation.

###### Table 3: Mandatory columns in the BESC\_Biorefinery.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|Biorefinery | This column contains **unique** names of resources available to the model. Resources can include different types of biorefinery.|
|Zone | Integer representing zone number where the resource is located. |
|Biomass_type | 1 = herbaceous biomass inputs, 2 = woody biomass inputs. |
|BioH2\_Production | 0 = not a bio hydrogen resource, 1 = bio hydrogen resource. |
|BioElectricity\_Production | 0 = not a bio electricity resource, 1 = bio electricity resource. |
|BioGasoline\_Production | 0 = not a bio gasoline resource, 1 = bio gasoline resource. |
|BioJetfuel\_Production | 0 = not a bio jetfuel resource, 1 = bio jetfuel resource. |
|BioDiesel\_Production | 0 = not a bio diesel resource, 1 = bio diesel resource. |
|**Capacity requirements**|
|Max\_capacity\_tonne\_per\_hr |-1 (default) – no limit on maximum operating capacity of the biorefinery resource. If non-negative, represents maximum allowed biomass consumption capacity (in tonne/hr) of the resource.|
|Min\_capacity\_tonne\_per\_hr| -1 (default) – no limit on minimum operating capacity of the biorefinery resource. If non-negative, represents minimum allowed biomass consumption capacity (in tonne/hr) of the resource.|
|**Cost parameters**|
|Inv\_Cost\_per\_tonne\_per\_hr\_yr | Annualized capacity investment cost of a technology (\$/tonne/hr/year). |
|Fixed\_OM\_Cost\_per\_tonne\_per\_hr\_yr | Fixed operations and maintenance cost of a technology (\$/tonne/hr/year). |
|Var\_OM\_Cost\_per\_tonne | Variable operations and maintenance cost of a technology (\$/tonne). |
|**Technical performance parameters**|
|Biomass\_tonne\_CO2\_per\_tonne | CO2 content in biomass input of the biorefinery resource (\tonne CO2/tonne biomass). |
|BioH2\_yield\_tonne\_per\_tonne | Tonne of H2 produced per tonne of biomass input by biorefinery resource.|
|BioElectricity\_yield\_MWh\_per\_tonne | MWh of electricity produced per tonne of biomass input by biorefinery resource.|
|BioGasoline\_yield\_MMBtu\_per\_tonne  |MMBtu of gasoline output per tonne of biomass input by biorefinery resource. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|BioJetfuel\_yield\_MMBtu\_per\_tonne  |MMBtu of jetfuel output per tonne of biomass input by biorefinery resource. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|BioDiesel\_yield\_MMBtu\_per\_tonne  |MMBtu of diesel output per tonne of biomass input by biorefinery resource. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|Power\_consumption\_MWh\_per\_tonne | MWh of electricity required per tonne of biomass input by biorefinery resource.|
|H2\_consumption\_tonne\_per\_tonne | Tonne of H2 required per tonne of biomass input by biorefinery resource.|
|etaFuel\_MMBtu\_per\_tonne | MMBtu of fuel required per tonne of biomass input by biorefinery resource.|
|CO2\_emissions\_tonne\_per\_tonne | Tonne CO2 released per tonne of biomass input by biorefinery resource.|
|CO2\_capture\_tonne\_per\_tonne | Tonne CO2 captured per tonne of biomass input by biorefinery resource and added to captured CO2 inventory.|

#### 2.1.2 BESC\_Herb\_Supply.csv

This file contains the quantity, cost and emissions parameters for herbaceous biomass included in the model formulation.

###### Table 4: Mandatory columns in the CSC\_capture\_compression.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|Zone | Integer representing zone number where the resource is located. |
|Emissions\_tonne\_per\_tonne | Tonne CO2 released per tonne of biomass supply. |
|Cost\_per\_tonne\_per\_hr | Cost of utilizing biomass supply per tonne per hour (\$/tonne/hr). |
|Max\_tonne\_per\_hr | Maximum biomass supply per tonne per hour (\tonne/hr). |

#### 2.1.3 BESC\_Wood\_Supply.csv

This file contains the quantity, cost and emissions parameters for woody biomass included in the model formulation.

###### Table 5: Mandatory columns in the CSC\_capture\_compression.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|Zone | Integer representing zone number where the resource is located. |
|Emissions\_tonne\_per\_tonne | Tonne CO2 released per tonne of biomass supply. |
|Cost\_per\_tonne\_per\_hr | Cost of utilizing biomass supply per tonne per hour (\$/tonne/hr). |
|Max\_tonne\_per\_hr | Maximum biomass supply per tonne per hour (\tonne/hr). |

## 3 Outputs

The table below summarizes the output variables reported as part of the various CSV files produced after each model run. The reported units are also provided. When the model is run with time domain reduction, if a result file includes time-dependent values (e.g. for each model time step), the value will not include the hour weight in it. An annual sum ("AnnualSum") column/row will be provided whenever it is possible (e.g., `BESC_zone_biohydrogen_produced.csv`), and this value takes the time-weights into account. 

### 3.1 Default output files

#### 3.1.1 BESC\_biorefinery\_capacity.csv

Reports optimal values of investment variables for biorefinery resource.

###### Table 6: Structure of the SynFuel_capacity.csv file
---
|**Output** |**Description** |**Units** |
| :------------ | :-----------|:-----------|
| Capacity\_tonne\_biomass\_per\_h |Input biomass capacity of each biorefinery resource type in each zone |Tonnes Biomass / Hr |
| Capacity\_Bioelectricity\_MWh\_per\_h |Maximum hourly bio electricity production based on built capacity of biorefinery resource |MWh / Hr |
| Capacity\_BioH2\_tonne\_per\_h |Maximum hourly bio hydrogen production based on built capacity of biorefinery resource |Tonnes H2 / Hr |
| Capacity\_Biodiesel\_MMBtu\_per\_h |Maximum hourly bio diesel production based on built capacity of biorefinery resource |MMBtu / Hr |
| Capacity\_Biojetfuel\_MMBtu\_per\_h |Maximum hourly bio jetfuel production based on built capacity of biorefinery resource |MMBtu / Hr |
| Capacity\_Biogasoline\_MMBtu\_per\_h |Maximum hourly bio gasoline production based on built capacity of biorefinery resource |MMBtu / Hr |
| Annual\_Electricity\_Production |Actual annual bio electricity production |MWh |
| Annual\_H2\_Production |Actual annual bio hydrogen jetfuel production |Tonnes H2 |
| Annual\_Biodiesel\_Production |Actual annual bio diesel production |MMBtu |
| Annual\_Biojetfuel\_Production |Actual annual bio jetfuel production |MMBtu |
| Annual\_Biogasoline\_Production |Actual annual bio gasoline production |MMBtu |
| Max\_Annual\_Biomass\_Consumption |Maximum annual biomass input based on built capacity |Tonnes Biomass |
| Annual\_Biomass\_Consumption |Actual biomass CO2 input |Tonnes Biomass |
| Capacity\_Factor |Capacity factor by dividing actual annual biomass input by maximum annual possible biomass input based on built capacity | |
| Annual\_CO2\_Emission |Actual annual CO2 emissions = Biorefinery emissions - Biomass CO2 content |Tonnes CO2 |

#### 3.1.2 BESC\_costs.csv

Reports BESC costs for each zone, including sum of fixed and variable costs for biorefinery resources, biomass supply costs and total costs. 

#### 3.1.3 BESC\_zone\_bioelectricity\_produced.csv

Reports production of bio electricity for each zone and time step.

#### 3.1.4 BESC\_zone\_biohydrogen\_produced.csv

Reports production of bio hydrogen for each zone and time step.

#### 3.1.5 BESC\_zone\_biodiesel\_produced.csv

Reports production of bio diesel for each zone and time step.

#### 3.1.6 BESC\_zone\_biojetfuel\_produced.csv

Reports production of bio jetfuel for each zone and time step.

#### 3.1.7 BESC\_zone\_biogasoline\_produced.csv

Reports production of bio gasoline for each zone and time step.

#### 3.1.8 BESC\_zone\_supply\_herb\_consumed.csv

Reports consumption of herbaceous biomass for each zone and time step.

#### 3.1.9 BESC\_zone\_supply\_wood\_consumed.csv

Reports consumption of woody biomass for each zone and time step.