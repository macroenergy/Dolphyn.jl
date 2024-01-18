# CSC Database Documentation

## 1 Model setup parameters

Model settings parameters are specified in a `csc_Settings.yml` file which should be located in the current working directory (or to specify an alternative location, edit the `settings_path` variable in your `Run.jl` file). Settings include those related to model structure, solution strategy and outputs, policy constraints, and others. Model structure related settings parameter affects the formulation of the model constraint and objective functions. Computational performance related parameters affect the accuracy of the solution. Policy related parameters specify the policy type and policy goal. Network related parameters specify settings related to transmission network expansion and losses. Note that all settings parameters are case sensitive.

###### Table 1a: Summary of the Model settings parameters
---
|**Settings Parameter** | **Description**|
| :------------ | :-----------|
|**Model structure related**||
|ModelCSC | Flag to turn or off CO2 Supply Chain modelling capabilities.|
||0 = no CO2 supply chain modeling.
||1 = modeling CO2 supply chain.|
|CO2NetworkExpansion | Flag for activating or deactivating inter-regional transmission expansion.|
||0 = modeling single zone or for multi-zone problems, inter regional 
transmission expansion is not allowed.|
||1 = active|
|ModelCO2Pipelines | Whether to model pipeline in CO2 supply chain. |
||0 = not modeling CO2 pipelines (no transmission).|
||1 = modeling CO2 pipelines (with transmission).|
|CO2PipeInteger |Whether to model pipeline capacity as discrete or integer. |
||0 = continuous capacity of CO2 pipeline.|
||1 = discrete capacity of CO2 pipeline.|
|CO2Pipeline_Loss |Whether to model pipeline CO2 loss. |
||0 = not modeling pipeline CO2 loss.|
||1 = modeling pipeline CO2 loss.|


## 2 Inputs

All input files are in CSV format. Running the GenX submodule requires a minimum of five input files. Additionally, the user may need to specify five more input files based on model configuration and type of scenarios of interest. Names of the input files and their functionality is given below. Note that names of the input files are case sensitive.


###### Table 2: Summary of the input files
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Files**||
|CSC\_pipelines.csv |Specify network topology, transmission fixed costs, capacity and loss parameters.|
|CSC\_capture.csv |Specify cost and performance data for DAC resources.|
|CSC\_capture\_variability.csv |Specify time-series of capacity factor/availability for each resource.|
|CSC\_capture\_compression.csv |Specify cost and performance data for CO2 compression resources for CO2 captured by DAC if modeling separately.|
|CSC\_storage_.csv |Specify cost and performance data for DAC resources.|

### 2.1 Mandatory input data
#### 2.1.1 CSC_pipelines.csv

This input file contains input parameters related to: 1) definition of pipeline network (regions between which pipelines are explicitly modeled and can be constructed) and 2) definition of pipeline construction costs, booster compressors (for pressure losses along the pipe), and main compressors (compression from CO2 production pressure to desired pipeline pressure). The following table describes each of the mandatory parameter inputs that need to be specified to run an instance of the model, along with comments for the model configurations when they are needed.

###### Table 3: Structure of the CSC_pipelines.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Settings-specific Columns**|
|**Multiple zone model**||
|CO2\_Pipelines | Index number of existing and candidate CO2 pipelines.|
|Max\_No\_Pipe | Maximum number of CO2 pipelines.|
|Existing\_No\_Pipe | Existing number of CO2 pipelines.|
|Max\_Flow\_Tonne\_p\_hr\_Per\_Pipe | Maximum capacity (flow rate) per CO2 pipeline.|
|CO2Pipe\_Inv\_Cost\_per\_mile\_yr | Annulized capital investment cost per pipeline-mile.|
|Pipe\_length\_miles | CO2 pipeline length in miles.|
|CO2PipeLoss\_tonne\_per\_mile\_per\_tonne | Amount of CO2 loss per mile.|
|CO2PipeCap\_tonne\_per\_mile | Maximum storage capacity per CO2 pipeline per mile.|
|Min\_pipecap\_stor\_frac | Minimum storage capacity per CO2 pipeline in percentage of maximum.|
|len\_bw\_comp\_mile | Length between two booster compressors in miles.|
|BoosterCompCapex\_per\_tonne\_p\_hr\_yr | Annulized investment cost of booster compressors per tonne/hr.|
|BoosterCompEnergy\_MWh\_per\_tonne | Electricity consumption of booster compressor per tonne of CO2 in MWh.|
|CO2Pipe\_Fixed\_OM\_Cost\_per\_mile\_yr | Annulized fixed O&M cost per pipeline-mile.|
|CO2Pipe\_Energy\_MWh\_per\_mile\_per\_tonne | Energy consumption per tonne of CO2 of per mile.|

#### 2.1.2 Generator\_variability.csv

This file contains the time-series of capacity factors / availability of each resource included in the `CSC_capture.csv` file for each time step (e.g. hour) modeled.

• first column: The first column contains the time index of each row (starting in the second row) from 1 to N.

• Second column onwards: Resources are listed from the second column onward with headers matching each resource name in the `CSC_capture.csv` file in any order. The availability for each resource at each time step is defined as a fraction of installed capacity and should be between 0 and 1. Note that for this reason, resource names specified in `CSC_capture.csv` must be unique.

#### 2.1.3 CSC\_capture.csv

This file contains cost and performance parameters for various DAC resources included in the model formulation.

###### Table 4: Mandatory columns in the CSC\_capture.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|CO2\_Resource | This column contains **unique** names of resources available to the model. Resources can include different types of DAC.|
|Zone | Integer representing zone number where the resource is located. |
|**Capacity requirements**|
|Max\_capacity\_tonne\_per\_hr |-1 (default) – no limit on maximum capture capacity of the DAC resource. If non-negative, represents maximum allowed capture capacity (in tonne/hr) of the resource.|
|Min\_capacity\_tonne\_per\_hr| -1 (default) – no limit on minimum capture capacity of the DAC resource. If non-negative, represents minimum allowed capture capacity (in tonne/hr) of the resource.|
|**Cost parameters**|
|Inv\_Cost\_per\_tonne\_per\_hr\_yr | Annualized capacity investment cost of a technology (\$/tonne/hr/year). |
|Fixed\_OM\_Cost\_per\_tonne\_per\_hr\_yr | Fixed operations and maintenance cost of a technology (\$/tonne/hr/year). |
|Var\_OM\_Cost\_per\_tonne | Variable operations and maintenance cost of a technology (\$/tonne). |
|**Technical performance parameters**|
|etaFuel\_MMBtu\_p\_tonne  |MMBtu of fuel consumed per tonne of CO2 captured by DAC. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|Fuel  |Fuel needed for a generator. The names should match with the ones in the `Fuels_data.csv`. |
|etaPCO2\_MWh\_p\_tonne | Energy required per tonne of CO2 capture by DAC.|
|Power\_Production\_MWh\_per\_tonne | Energy produced per tonne of CO2 capture by DAC for resoures with built in power plants.|
|Fuel\_CCS\_Rate  |Capture rate of CO2 released from fuel utilization. |
|CO2\_Capture\_Min\_Output |[0,1], The minimum capture level for a DAC unit as a fraction of total capacity. |
|Ramp\_Up\_Percentage |[0,1], Maximum increase in CO2 capture output from between two periods (typically hours), reported as a fraction of nameplate capacity.|
|Ramp\_Dn\_Percentage |[0,1], Maximum decrease in CO2 capture output from between two periods (typically hours), reported as a fraction of nameplate capacity.|

#### 2.1.4 CSC\_capture\_compression.csv

This file contains cost and performance parameters for various CO2 compression resources included in the model formulation.

###### Table 5: Mandatory columns in the CSC\_capture\_compression.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|CO2\_Capture\_Compression | This column contains **unique** names of CO2 compression resources available to the model. |
|Zone | Integer representing zone number where the resource is located. |
|**Capacity requirements**|
|Max\_capacity\_tonne\_per\_hr |-1 (default) – no limit on maximum CO2 compression capacity. If non-negative, represents maximum allowed capture capacity (in tonne/hr) of the resource.|
|Min\_capacity\_tonne\_per\_hr| -1 (default) – no limit on minimum CO2 compression capacity. If non-negative, represents minimum allowed capture capacity (in tonne/hr) of the resource.|
|**Cost parameters**|
|Inv\_Cost\_per\_tonne\_per\_hr\_yr | Annualized capacity investment cost of a technology (\$/tonne/hr/year). |
|Fixed\_OM\_Cost\_per\_tonne\_per\_hr\_yr | Fixed operations and maintenance cost of a technology (\$/tonne/hr/year). |
|**Technical performance parameters**|
|etaPCO2\_MWh\_p\_tonne | Energy required per tonne of CO2 compression.|
|Power\_Production\_MWh\_per\_tonne | Energy produced per tonne of CO2 capture by DAC for resoures with built in power plants.|
|CO2\_Capture\_Min\_Output |[0,1], The minimum CO2 compression level as a fraction of total capacity. |
|CO2\_Capture\_Max\_Output |[0,1], The maximum CO2 compression level as a fraction of total capacity. |

#### 2.1.5 CSC\_storage.csv

This file contains cost and performance parameters for various CO2 storage resources included in the model formulation.

###### Table 4: Mandatory columns in the CSC\_storage_.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|CO2\_Storage | This column contains **unique** names of resources available to the model. Resources can include different types of CO2 storage.|
|Zone | Integer representing zone number where the resource is located. |
|**Capacity requirements**|
|Max\_capacity\_tonne\_per\_yr |-1 (default) – no limit on maximum CO2 storage capacity of the resource. If non-negative, represents maximum allowed CO2 storage capacity (in tonne/year) of the resource.|
|Min\_capacity\_tonne\_per\_yr| -1 (default) – no limit on minimum CO2 storage capacity of the DAC resource. If non-negative, represents minimum allowed CO2 storage capacity (in tonne/year) of the resource.|
|**Cost parameters**|
|Inv\_Cost\_per\_tonne\_per\_yr\_yr | Annualized capacity investment cost of a technology (\$/tonne/year/year). |
|Fixed\_OM\_Cost\_per\_tonne\_per\_yr\_yr | Fixed operations and maintenance cost of a technology (\$/tonne/year/year). |
|Var\_OM\_Cost\_per\_tonne | Variable operations and maintenance cost of a technology (\$/tonne). |
|**Technical performance parameters**|
|etaPCO2\_MWh\_p\_tonne | Energy required per tonne of CO2 stored.|
|Max\_injection\_rate\_tonne\_per\_hr | The maximum CO2 injection rate into CO2 storage resource (\tonne/hr). |
|CO2\_Injection\_Min\_Output |[0,1], The minimum CO2 injection level as a fraction of max injection rate. |
|CO2\_Injection\_Max\_Output |[0,1], The maximum CO2 injection level as a fraction of max injection rate. |

## 3 Outputs

The table below summarizes the output variables reported as part of the various CSV files produced after each model run. The reported units are also provided. When the model is run with time domain reduction, if a result file includes time-dependent values (e.g. for each model time step), the value will not include the hour weight in it. An annual sum ("AnnualSum") column/row will be provided whenever it is possible (e.g., `Zone_CO2_storage_balance.csv`), and this value takes the time-weights into account. 

### 3.1 Default output files


#### 3.1.1 CSC_DAC_capacity.csv

Reports optimal values of investment variables for DAC

###### Table 9: Structure of the CSC_DAC_capacity.csv file
---
|**Output** |**Description** |**Units** |
| :------------ | :-----------|:-----------|
| Capacity |Capture capacity of each DAC resource type in each zone |CO$_2$ Tonnes / Hr |
| Max\_Annual\_Capture |Maximum annual possible CO2 capture based on built capacity |CO$_2$ Tonnes |
| Annual\_Capture |Actual annual CO2 capture |CO$_2$ Tonnes |
| Capacity\_Factor |Capacity factor by dividing actual annual CO2 capture by maximum annual possible CO2 capture based on built capacity | |

#### 3.1.2 CSC_storage_capacity.csv

Reports CO2 storage capacity. 

#### 3.1.3 CSC_injection_per_year.csv

Reports total CO2 injection into CO2 storage. 

#### 3.1.4 Zone_CO2_storage_balance.csv

Reports balance of captured CO2 of each sector and resources for each zone and time step. 

#### 3.1.5 CSC_storage_balance_zone.csv

Reports annual sum balance of captured CO2 of each sector and resources for each zone. 

#### 3.1.6 Zone_CO2_emission_balance.csv

Reports emissions of each sector and re6ources for each zone and time step. 

#### 3.1.7 System_CO2_emission_balance.csv

Reports systemwide emissions of each sector for time step. 

#### 3.1.8 CSC_co2_pipeline_flow.csv

Reports CO$_2$ level (in tonnes/hour) in each pipeline for each time step, as well as the amount of CO2 (in tonnes) sent from the source or arrived at the sink. 

