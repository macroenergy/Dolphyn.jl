# DOLPHYN Documentation

```@meta
CurrentModule = DOLPHYN
```

## Overview

DOLPHYN is a highly-configurable, [open source](https://github.com/gn-he/DOLPHYN-dev/blob/main/LICENSE) Julia package aimed to design and explore future energy system
in corporation with new energy sytechnologies like electrolysis and caprbo capture.

The DOLPHYN model evaluates investments and operations across the bulk supply chain for electricity, H2 and CO2, including production, storage, transmission, conditioning (compression/liquefaction in the case of H2 as well as CO2) and demand. The model determines the least-cost mix of electricity and H2 production, storage, and transmission infrastructures to meet power and H2 demands subject to a variety of operational and policy constraints, considering carbon emissions at the same time. 

The developed model can incorporate a wide range of power and H2 technology options, including VRE generation, carbon capture and storage (CCS) applied to power and H2 generation, and truck (gaseous, liquid) and pipelines for H2 transportation. The power systems and H2 supply chain are coupled primarily through electrolysis and power generation technologies fueled by H2, as well as electricity consumption in H2 compression/liquefaction. 
The key operational constraints of the model include: 
+ supply-demand balance for H2 and electricity at each zone;
+ inventory balance constraints for stationary storage technologies;
+ inventory balance constraints related to trucks at a given location (any of the zones and routes, arriving, departing or in transit) and for different states (empty and full), and
+ linearized unit commitment for conventional thermal power generation technologies and natural gas based H2 production technologies.

DOLPHYN features a modular and transparent code structure developed in [Julia](http://julialang.org/) + [JuMP](http://jump.dev/). The model is designed to be highly flexible and configurable for use in a variety of applications from academic research and technology evaluation to public policy and regulatory analysis and resource planning. 
## Requirements

DOLPHYN currently exists in version 0.2.0 and runs on Julia versions above 1.4 series, and a minimum version of JuMP v0.21.x. It is currently setup to use one of the following open-source freely available solvers: A) [Clp](https://github.com/jump-dev/Clp.jl) for linear programming (LP) problems and (B) [Cbc](https://github.com/jump-dev/Cbc.jl) for mixed integer linear programming (MILP) problems. We also provide the option to use one of these two commercial solvers: C) [Gurobi](https://www.gurobi.com), and D) [CPLEX](https://www.ibm.com/analytics/cplex-optimizer). Note that using Gurobi and CPLEX requires a valid license on the host machine. 

The file `julenv.jl` in the parent directory lists all of the packages and their versions needed to run DOLPHYN. You can see all of the packages installed in your Julia environment and their version numbers by running `pkg> status` on the package manager command line in the Jula REPL.

## Running an Instance of DOLPHYN

Download or clone the DOLPHYN repository on your machine in a directory named 'DOLPHYN-dev'. Create this new directory in a location where you wish to store the DOLPHYNJulEnv environment.

The Run.jl file in each of the example sub-folders within `Example_Systems/` provides an example of how to use DOLPHYN.jl for capacity expansion modeling. The following are the main steps performed in the Run.jl script:

1. Establish path to environment setup files and DOLPHYN source files.
2. Read in model settings `genx_settings.yml` for electricity sector and other setting files for H2 and CO2 sectors from the example directory.
3. Configure solver settings.
4. Load the model inputs from the example directory and perform time-domain clustering if required.
5. Generate a DOLPHYN model instance.
6. Solve the model.
7. Write the output files to a specified directory.
