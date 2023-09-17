# General Database Documentation

###### Table 1a: Summary of the Model settings parameters
---
|**Settings Parameter** | **Description**|
| :------------ | :-----------|
|**Model structure related**||
|OperationWrapping | Select temporal resolution for operations constraints.|
||0 = Models intra-annual operations as a single contiguous period. Inter-temporal constraint are defined based on linking first time step with the last time step of the year.|
||1 = Models intra-annual operations using multiple representative periods. Inter-temporal constraints are defined based on linking first time step with the last time step of each representative period.|
|TimeDomainReduction | 1 = Use time domain reduced inputs available in the folder with the name defined by settings parameter TimeDomainReduction Folder. If such a folder does not exist or it is empty, time domain reduction will reduce the input data and save the results in the folder with this name. These reduced inputs are based on full input data provided by user in `Load_data.csv`, `Generators_variability.csv`, and `Fuels_data.csv`.|
|TimeDomainReductionFolder | Name of the folder where time domain reduced input data is accessed and stored.|
|**Solution strategy and outputs**||
|Solver | Solver name is case sensitive (CPLEX, Gurobi, clp). |
|ParameterScale | Flag to turn on parameter scaling wherein load, capacity and power variables defined in GW rather than MW. This flag aides in improving the computational performance of the model. |
||1 = Scaling is activated. |
||0 = Scaling is not activated. |
|ModelingToGenerateAlternatives | Modeling to Generate Alternative Algorithm. |
||1 = Use the algorithm. |
||0 = Do not use the algorithm. |
|ModelingtoGenerateAlternativeSlack | value used to define the maximum deviation from the least-cost solution as a part of Modeling to Generate Alternative Algorithm. Can take any real value between 0 and 1. |
|WriteShadowPrices | Get dual of various model related constraints, including to estimate electricity prices, stored value of energy and the marginal CO$_2$ prices.|
|**Miscellaneous**|
|PrintModel | Flag for printnig the model equations as .lp file.|
||1= including the model equation as an output|
||0= for the model equation not being included as an output|

|VisualizeData | lot basic data visualizations for quick diagnostics (call_dolphyn_viz)|
||1= create basic visualization|
||0= do not create basic visualizations|

Additionally, Solver related settings parameters are specified in the appropriate solver settings .yml file (e.g. `gurobi_settings.yml` or `cplex_settings.yml`), which should be located in the current working directory (or to specify an alternative location, edit the `solver_settings_path` variable in your Run.jl file). Note that GenX supplies default settings for most solver settings in the various solver-specific functions found in the /src/configure_solver/ directory. To overwrite default settings, you can specify the below Solver specific settings. Note that appropriate solver settings are specific to each solver.

###### Table 1b: Summary of the Solver settings parameters
---
|**Settings Parameter** | **Description**|
| :------------ | :-----------|
|**Solver settings**||
|Method | Algorithm used to solve continuous models or the root node of a MIP model. Generally, barrier method provides the fastest run times for real-world problem set.|
|| CPLEX: CPX\_PARAM\_LPMETHOD - Default = 0; See [link](https://www.ibm.com/docs/en/icos/20.1.0?topic=parameters-algorithm-continuous-linear-problems) for more specifications.|
|| Gurobi: Method - Default = -1; See [link](https://www.gurobi.com/documentation/8.1/refman/method.html) for more specifications.|
|| clp: SolveType - Default = 5; See [link](https://www.coin-or.org/Doxygen/Clp/classClpSolve.html) for more specifications.|
|BarConvTol | Convergence tolerance for barrier algorithm.|
|| CPLEX: CPX\_PARAM\_BAREPCOMP - Default = 1e-8; See [link](https://www.ibm.com/docs/en/icos/12.8.0.0?topic=parameters-convergence-tolerance-lp-qp-problems) for more specifications.|
|| Gurobi: BarConvTol - Default = 1e-8; See [link](https://www.gurobi.com/documentation/8.1/refman/barconvtol.html)link for more specifications.|
|Feasib\_Tol | All constraints must be satisfied as per this tolerance. Note that this tolerance is absolute.|
|| CPLEX: CPX\_PARAM\_EPRHS - Default = 1e-6; See [link](https://www.ibm.com/docs/en/icos/20.1.0?topic=parameters-feasibility-tolerance) for more specifications.|
|| Gurobi: FeasibilityTol - Default = 1e-6; See [link](https://www.gurobi.com/documentation/9.1/refman/feasibilitytol.html) for more specifications.|
|| clp: PrimalTolerance - Default = 1e-7; See [link](https://www.coin-or.org/Clp/userguide/clpuserguide.html) for more specifications.|
|| clp: DualTolerance - Default = 1e-7; See [link](https://www.coin-or.org/Clp/userguide/clpuserguide.html) for more specifications.|
|Optimal\_Tol | Reduced costs must all be smaller than Optimal\_Tol in the improving direction in order for a model to be declared optimal.|
|| CPLEX: CPX\_PARAM\_EPOPT - Default = 1e-6; See [link](https://www.ibm.com/docs/en/icos/12.8.0.0?topic=parameters-optimality-tolerance) for more specifications.|
|| Gurobi: OptimalityTol - Default = 1e-6; See [link](https://www.gurobi.com/documentation/8.1/refman/optimalitytol.html) for more specifications.|
|Pre\_Solve | Controls the presolve level.|
|| Gurobi: Presolve - Default = -1; See [link](https://www.gurobi.com/documentation/8.1/refman/presolve.html) for more specifications.|
|| clp: PresolveType - Default = 5; See [link](https://www.coin-or.org/Doxygen/Clp/classClpSolve.html) for more specifications.|
|Crossover | Determines the crossover strategy used to transform the interior solution produced by barrier algorithm into a basic solution.|
|| CPLEX: CPX\_PARAM\_SOLUTIONTYPE - Default = 2; See [link](https://www.ibm.com/docs/en/icos/12.8.0.0?topic=parameters-optimality-tolerance) for more specifications.|
|| Gurobi: Crossover - Default = 0; See [link](https://www.gurobi.com/documentation/9.1/refman/crossover.html#:~:text=Use%20value%200%20to%20disable,interior%20solution%20computed%20by%20barrier.) for more specifications.|
|NumericFocus | Controls the degree to which the code attempts to detect and manage numerical issues.|
|| CPLEX: CPX\_PARAM\_NUMERICALEMPHASIS - Default = 0; See [link](https://www.ibm.com/docs/en/icos/12.8.0.0?topic=parameters-numerical-precision-emphasis) for more specifications.|
|| Gurobi: NumericFocus - Default = 0; See [link](https://www.gurobi.com/documentation/9.1/refman/numericfocus.html) for more specifications.|
|TimeLimit | Time limit to terminate the solution algorithm, model could also terminate if it reaches MIPGap before this time.|
|| CPLEX: CPX\_PARAM\_TILIM- Default = 1e+75; See [link](https://www.ibm.com/docs/en/icos/12.8.0.0?topic=parameters-optimizer-time-limit-in-seconds) for more specifications.|
|| Gurobi: TimeLimit - Default = infinity; See [link](https://www.gurobi.com/documentation/9.1/refman/timelimit.html) for more specifications.|
|| clp: MaximumSeconds - Default = -1; See [link](https://www.coin-or.org/Doxygen/Clp/classClpModel.html) for more specifications.|
|MIPGap | Optimality gap in case of mixed-integer program.|
|| CPLEX: CPX\_PARAM\_EPGAP- Default = 1e-4; See [link](https://www.ibm.com/docs/en/icos/20.1.0?topic=parameters-relative-mip-gap-tolerance) for more specifications.|
|| Gurobi: MIPGap - Default = 1e-4; See [link](https://www.gurobi.com/documentation/9.1/refman/mipgap2.html) for more specifications.|
|DualObjectiveLimit | When using dual simplex (where the objective is monotonically changing), terminate when the objective exceeds this limit.|
|| clp: DualObjectiveLimit - Default = 1e308; See [link](https://www.coin-or.org/Doxygen/Clp/classClpModel.html) for more specifications.|
|MaximumIterations | Terminate after performing this number of simplex iterations.|
|| clp: MaximumIterations - Default = 2147483647; See [link](https://www.coin-or.org/Doxygen/Clp/classClpModel.html) for more specifications.|
|LogLevel | Set to 1, 2, 3, or 4 for increasing output. Set to 0 to disable output.|
|| clp: logLevel - Default = 1; See [link](https://www.coin-or.org/Doxygen/Clp/classClpModel.html) for more specifications.|
|| cbc: logLevel - Default = 1; See [link](https://www.coin-or.org/Doxygen/Cbc/classCbcModel.html#a244a08213674ce52ddcf33ab4ff53380a185d42e67d2c4cb7b79914c0ed322b5f) for more specifications.|
|InfeasibleReturn | Set to 1 to return as soon as the problem is found to be infeasible (by default, an infeasibility proof is computed as well).|
|| clp: InfeasibleReturn - Default = 0; See [link](https://www.coin-or.org/Doxygen/Clp/classClpModel.html) for more specifications.|
|Scaling | Sets or unsets scaling; 0 -off, 1 equilibrium, 2 geometric, 3 auto, 4 dynamic(later).|
|| clp: Scaling - Default = 3; See [link](https://www.coin-or.org/Doxygen/Clp/classClpModel.html) for more specifications.|
|Perturbation | Perturbs problem; Switch on perturbation (50), automatic (100), don't try perturbing (102).|
|| clp: Perturbation - Default = 3; See [link](https://www.coin-or.org/Doxygen/Clp/classClpModel.html) for more specifications.|
|maxSolutions | Terminate after this many feasible solutions have been found.|
|| cbc: maxSolutions - Default = -1; See [link](https://www.coin-or.org/Doxygen/Cbc/classCbcModel.html#a244a08213674ce52ddcf33ab4ff53380a185d42e67d2c4cb7b79914c0ed322b5f) for more specifications.|
|maxNodes | Terminate after this many branch-and-bound nodes have been evaluated|
|| cbc: maxNodes - Default = -1; See [link](https://www.coin-or.org/Doxygen/Cbc/classCbcModel.html#a244a08213674ce52ddcf33ab4ff53380a185d42e67d2c4cb7b79914c0ed322b5f) for more specifications.|
| allowableGap | Terminate after optimality gap is less than this value (on an absolute scale)|
|| cbc: allowableGap - Default = -1; See [link](https://www.coin-or.org/Doxygen/Cbc/classCbcModel.html#a244a08213674ce52ddcf33ab4ff53380a185d42e67d2c4cb7b79914c0ed322b5f) for more specifications.|
|ratioGap | Terminate after optimality gap is smaller than this relative fraction.|
|| cbc: ratioGap - Default = Inf; See [link](https://www.coin-or.org/Doxygen/Cbc/classCbcModel.html#a244a08213674ce52ddcf33ab4ff53380a185d42e67d2c4cb7b79914c0ed322b5f) for more specifications.|
|threads | Set the number of threads to use for parallel branch & bound.|
|| cbc: threads - Default = 1; See [link](https://www.coin-or.org/Doxygen/Cbc/classCbcModel.html#a244a08213674ce52ddcf33ab4ff53380a185d42e67d2c4cb7b79914c0ed322b5f) for more specifications.|