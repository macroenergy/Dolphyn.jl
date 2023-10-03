# DOLPHYN
## Overview
DOLPHYN is a configurable, [open source](https://github.com/macroenergy/DOLPHYN/blob/README_Doc_Update/LICENSE) energy system optimization model developed to explore interactions between multiple energy vectors and emerging technologies across their supply chains as part of a future integrated low-carbon energy system.

The DOLPHYN model evaluates investments and operations across the electricity and Hydrogen (H2) supply chains, including production, storage, transmission, conditioning, and end-use consumption. Importantly, the model is able to capture interactions between electricity and hydrogen infrastructure through: a) using hydrogen for power generation and b) production of hydrogen using electricity. The model is set up as a single-stage investment planning model and determines the least-cost mix of electricity and H2 infrastructure to meet electricity and H2 demand subject to a variety of operational, policy and carbon emission constraints. The DOLPHYN model incorporates the [GenX](https://github.com/GenXProject/GenX) electricity system model to characterize electricity system operations and investments (v0.3.6). Periodically, the electricity system representation is regularly updated to the latest GenX version.

DOLPHYN is designed to be highly flexible and configurable, for use in a variety of applications from academic research and technology evaluation to public policy and regulatory analysis and resource planning. We are currently working to add biofuel supply chains and carbon capture, transport, and storage to the model. 

We welcome you to add new features and resources to DOLPHYN for use in your own work and to [share them here for others](https://github.com/macroenergy/DOLPHYN/pulls). If you have issues using DOLPHYN [please let us know by opening an issue](https://github.com/macroenergy/DOLPHYN/issues).
 
## Requirements

DOLPHYN is written in [Julia](https://julialang.org/) and requires a mathematical programme solver to run. We recommend using the [latest stable version of Julia](https://julialang.org/downloads/) unless otherwise noted in the installation instructions below. DOLPHYN can run using several open-source and commercial solvers. DOLPHYN is most extensively tested using:
- [HiGHS](https://highs.dev/) - a free open-source solver
- [Gurobi](https://www.gurobi.com) - a commercial solver requiring a paid commercial license or free academic license

DOLPHYN also has limited support for:
- [Clp](https://github.com/jump-dev/Clp.jl) - a free open-source solver
- [Cbc](https://github.com/jump-dev/Cbc.jl) - a free open-source solver
- [CPLEX](https://www.ibm.com/analytics/cplex-optimizer) - a commercial solver requiring a paid commercial license or free academic license

## Running an Instance of DOLPHYN

### If you are doing a fresh install:

In your top-level folder where you want to place DOLPHYN, run:

- <code>git clone --recurse-submodules https://github.com/macroenergy/DOLPHYN</code>

### If you are working from an existing project:

In your top-level folder (generally DOLPHYN or DOLPHYN-DEV), run:

- <code>git pull</code>
- <code>git checkout main</code>
- <code>cd src/GenX</code>
- <code>git submodule init</code>
- <code>git submodule update</code>

The Run.jl file in each of the example sub-folders within `Example_Systems/` provides an example of how to use DOLPHYN.jl for capacity expansion modeling. Descriptions of each example system is included in the next section. The following are the main steps performed in the Run.jl script:

1. Establish path to environment setup files and DOLPHYN source files.
2. Read in model settings `genx_settings.yml` for electricity sector and other setting files for H2 supply chain from the example directory.
3. Configure solver settings.
4. Load the model inputs from the example directory and perform time-domain clustering if required.
5. Generate a DOLPHYN model instance.
6. Solve the model.
7. Write the output files to a specified directory.

Ensure that your settings in `global_model_settings.yml`, `GenX_settings.yml`, `hsc_settings` are correct. The default settings use the solver Gurobi (`Solver: Gurobi`) (for configuring your local machine to use Gurobi, please follow instructions [here](https://github.com/macroenergy/DOLPHYN/wiki/Installing-and-running-DOLPHYN#download-the-gurobi-and--or-highs-solvers)), time domain reduced input data (`TimeDomainReduction: 1`). Other optional policies include minimum capacity requirements, a capacity reserve margin, and more.

### Setting up the Julia environment 

#### First time running DOLPHYN:

In your command terminal (not the Julia REPL), navigate to your DOLPHYN folder then run the following commands:

- <code>julia --project=.</code>
- <code>julia> ]</code> (Enter ']' at the prompt)
- <code>(DOLPHYN) pkg> instantiate</code> (you should see DOLPHYN project name here, if not, enter `activate .`)
- <code>(DOLPHYN) pkg> build Gurobi</code> (if you plan to use Gurobi)

Here is a snapshot for you to see the commands (instantiate and build Gurobi) used from above:
![Screen Shot 2023-09-07 at 11 19 22 AM](https://github.com/macroenergy/DOLPHYN/assets/2174909/8e5720fd-28f5-4bdc-840c-70fec0212cd3)

You can now press backspace to exit the Julia package manager and start using DOLPHYN by [running your first example](#running-your-first-example).

#### Second+ time running DOLPHYN:

In your command terminal (not the Julia REPL), navigate to your DOLPHYN folder then run the following commands:

- <code>julia --project=.</code>
- <code>julia> ]</code> 
- <code>(DOLPHYN) pkg> st</code> (this is for checking the status of packages installed for DOLPHYN)

### Running your first example: 

Exit the package manager by hitting your backspace key. Then, navigate to one of the example systems, e.g.:

`julia> cd("Example_Systems/SmallNewEngland/OneZone")`

Use the Run.jl file to run the case:

`julia> include("Run.jl")`

Once the model has completed running, results will be written into the 'Results' directory. 

## Example Systems

**SmallNewEngland: OneZone** is a one-year example with hourly resolution representing Massachusetts. A rate-based carbon cap of 50 gCO<sub>2</sub> per kWh is specified in the `CO2_cap.csv` input file. Expect a run time of ~5 seconds.

**SmallNewEngland: ThreeZones** is similar to the above example but contains zones representing Massachusetts, Connecticut, and Maine. Expect a run time of ~5 seconds.

**2030_CombEC_DETrans** is a combined power and hydrogen model for the EU for the year 2030. It contains a power model with hourly resolution, contains zones representing Belgium, Germany, Denmark, France, Great Britain, the Netherlands, Sweden, and Norway. The model also includes a CO2 constraint representing 30% of 2015 power sector CO2 emissions applied to the hydrogen and power sector jointly. Expect a run time of ~8 minutes.


## DOLPHYN Team
The model was originally [developed](https://pubs.rsc.org/en/content/articlehtml/2021/ee/d1ee00627d) by [Guannan He](https://www.guannanhe.com/) while at the MIT Energy Initiative, and is now maintained by a team contributors at [MITEI](https://energy.mit.edu/) led by [Dharik Mallapragada](http://mallapragada.mit.edu/) as well as Guannan He's research group at Peking University. Key contributors include Dharik S. Mallapragada, Guannan He, Yuheng Zhang, Youssef Shaker, Jun Wen Law, Nicole Shi and Anna Cybulsky.
