# DOLPHYN

## Overview
DOLPHYN is a configurable, [open source](https://github.com/macroenergy/Dolphyn.jl/blob/README_Doc_Update/LICENSE) energy system optimization model developed to explore interactions between multiple energy vectors and emerging technologies across their supply chains as part of a future integrated low-carbon energy system.

The DOLPHYN model evaluates investments and operations across the electricity and Hydrogen (H2) supply chains, including production, storage, transmission, conditioning, and end-use consumption. Importantly, the model is able to capture interactions between electricity and hydrogen infrastructure through: a) using hydrogen for power generation and b) production of hydrogen using electricity. The model is set up as a single-stage investment planning model and determines the least-cost mix of electricity and H2 infrastructure to meet electricity and H2 demand subject to a variety of operational, policy and carbon emission constraints. The DOLPHYN model incorporates the [GenX](https://github.com/GenXProject/GenX) electricity system model to characterize electricity system operations and investments (v0.3.6). Periodically, the electricity system representation is regularly updated to the latest GenX version.

DOLPHYN is designed to be highly flexible and configurable, for use in a variety of applications from academic research and technology evaluation to public policy and regulatory analysis and resource planning. We are currently working to add biofuel supply chains and carbon capture, transport, and storage to the model. 

We welcome you to add new features and resources to DOLPHYN for use in your own work and to [share them here for others](https://github.com/macroenergy/Dolphyn.jl/pulls). If you have issues using DOLPHYN [please let us know by opening an issue](https://github.com/macroenergy/Dolphyn.jl/issues).
 
## Requirements

DOLPHYN is written in [Julia](https://julialang.org/). We recommend using the [latest version of Julia](https://julialang.org/downloads/) to run DOLPHYN but will support all versions back to the current long term stable version. 

You need a mathematical programme solver to run DOLPHYN. DOLPHYN comes packaged with [HiGHS](https://highs.dev/), a free open-source solver. This will be installed automatically by the [HiGHS.jl](https://github.com/jump-dev/HiGHS.jl) package when you use DOLPHYN.

DOLPHYN also works with several other open-source and commercial solvers via the [JuMP.jl](https://jump.dev) package. DOLPHYN is most extensively tested using [Gurobi](https://www.gurobi.com), a commercial solver requiring a paid commercial license or free academic license

DOLPHYN also has limited support for:

- [CPLEX](https://www.ibm.com/analytics/cplex-optimizer) - a commercial solver requiring a paid commercial license or free academic license
- [Clp](https://github.com/jump-dev/Clp.jl) - a free open-source solver
- [Cbc](https://github.com/jump-dev/Cbc.jl) - a free open-source solver

## Installing and Running DOLPHYN

DOLPHYN is available as a Julia package. To install DOLPHYN, open the Julia REPL and run:

`using Pkg`

`Pkg.add("Dolphyn")`

### Running your first example

Download the example systems by downloading or cloning the Dolphyn.jl repository by [following the instruction here](#if-you-are-doing-a-fresh-install). Navigate to one of the example systems, e.g.:

`julia> cd("Example_Systems/SmallNewEngland/OneZone")`

Here you will find:

- Input data contained in several CSV files
- A settings folder containing:
  - global_model_settings.yml: settings across all sectors
  - gens_settings.yml: setting for the electricity sector
  - hsc_settings.yml: settings for the hydrogen sector
  - solver settings, e.g. highs_settings.yml
- A Run.jl file which constructs, runs, and outputs the model

To run the model, ensure you are not in the package manager by hitting the backspace key, then execute the Run.jl file:

`julia> include("Run.jl")`

Once the model has completed running, results will be written into the "Results" folder. The hydrogen sector results are saved inthe Results/Results_HSC folder.

### Example Systems

**SmallNewEngland: OneZone** is a one-year example with hourly resolution representing Massachusetts. A rate-based carbon cap of 50 gCO<sub>2</sub> per kWh is specified in the `CO2_cap.csv` input file. Expect a run time of ~5 seconds.

**SmallNewEngland: ThreeZones** is similar to the above example but contains zones representing Massachusetts, Connecticut, and Maine. Expect a run time of ~1 minute.

**NorthSea_2030** is a combined power and hydrogen model for the EU for the year 2030. It contains a power model with hourly resolution, contains zones representing Belgium, Germany, Denmark, France, Great Britain, the Netherlands, Sweden, and Norway. The model also includes a CO2 constraint representing 30% of 2015 power sector CO2 emissions applied to the hydrogen and power sector jointly. Expect a run time of ~10 minutes.

### Creating Your Own System

The DOLPHYN model is designed to be highly flexible and configurable. We recommend using the example input files and Run.jl file as templates. The [Model Inputs / Outputs Documentation](https://macroenergy.github.io/Dolphyn.jl/dev/global_data_documentation/) details the input files and data required for different sectors, resources, and policies.

## Installing Gurobi or an alternative solver

HiGHS will be automatically downloaded and installed when you install DOLPHYN so you do not need to download it separately. However if you would like to use a specific version of have a separate copy, it can be downloaded from: [https://highs.dev/](https://highs.dev/).

If you wish to use another solver you will need to install it separately and add the corresponding Julia package to your Julia environment. Most [solvers supported by JuMP.jl](https://jump.dev/JuMP.jl/stable/packages/solvers/) should be compatible. The instructions below are for Gurobi, but the process is similar for other solvers.

To use Gurobi instead of HiGHS to solve the `.../SmallNewEngland/OneZone` example:

- Download and install the latest version of the Gurobi Optimizer from: [https://www.gurobi.com/downloads/gurobi-software/](https://www.gurobi.com/downloads/gurobi-software/)
- Install the Gurobi Julia package by running the following commands in the Julia REPL:
  - `using Pkg`
  - `Pkg.add("Gurobi")`
  - `Pkg.build("Gurobi")`
- In the `Settings/global_model_settings.yml` file, change the solver to Gurobi by changing the line `Solver: HiGHS` to `Solver: Gurobi`
- Add the following line to the `Run.jl` file:
  - `using Gurobi`

If the step to build Gurobi fails, the most likely cause is that the Gurobi installation cannot be found. [Use the following instructions](https://support.gurobi.com/hc/en-us/articles/13443862111761-How-do-I-set-system-environment-variables-for-Gurobi-) to define the "GUROBI_HOME" and "GRB_LICENSE_FILE" environment variables on your computer. For example, for Gurobi 10.0 on Ubuntu they should point to:
- GUROBI_HOME = ...path to Gurobi install/gurobi1000/linux64
- GRB_LICENSE_FILE = ...path to Gurobi install/gurobi1000/gurobi.lic

Once you have successfully built Gurobi.jl, run the model as described above. The model should now run using Gurobi instead of HiGHS.

## Installing DOLPHYN as a Developer

Intalling DOLPHYN via the package manager will allow you to use Dolphyn and it is possible to install specific versions from branches or forks of the Dolphyn.jl repo by specifying the URL when adding the package.

However, if you would like to extend, modify or contribute to DOLPHYN then we recommend cloning the repository and installing it as a developer. This will allow you to make changes to the code, test them, and contribute them back to the main repository.

### If you are doing a fresh install

#### ZIP download

If you would like a one-time download of DOLPHYN which is not set up to pull updates using git, then simply download and unzip the files [using this link](https://github.com/macroenergy/Dolphyn.jl/archive/refs/heads/main.zip).

#### Fresh Install Using GitHub Desktop

Use the File -> Clone Respository -> URL dropdown menu to clone the DOLPHYN repository from:

`https://github.com/macroenergy/Dolphyn.jl.git`

#### Fresh Install Using GitHub via your terminal / command line

In the top-level folder where you want to place DOLPHYN, run:

`git clone https://github.com/macroenergy/Dolphyn.jl.git`

### If you are working from an existing project

#### Existing Project Using GitHub Desktop

Pull the latest version of DOLPHYN from the main branch. If you previously used the verison of DOLPHYN where GenX was a submodule (as opposed to ordinary folder as it is now) then some of the submodule config files may remain in your project. The easiest solution is to delete your entire DOLPHYN folder from your computer and re-clone the repository.

#### Existing Project Using GitHub via your terminal / command line

In your top-level folder (generally DOLPHYN or DOLPHYN-DEV), run:

`git pull`

`git checkout main`

### Setting up the Julia environment

In order to run DOLPHYN from the cloned repo, several Julia packages must be downloaded and installed. To help users install the correct packages and versions, we have created a Julia environment file. This file is located in the top-level DOLPHYN folder and is called `Project.toml`.

### First time running DOLPHYN

The first time you run DOLPHYN, you must instantiate the Julia environment. This will download and install all the required packages.

In your command terminal (not the Julia REPL), navigate to your DOLPHYN folder then run the following commands:

- <code>julia --project=.</code> (this starts the Julia REPL using the environment file found in the current directory)
- <code>julia> ]</code> (Enter ']' at the prompt)
- <code>(DOLPHYN) pkg> instantiate</code> (you should see DOLPHYN project name here, if not, enter `activate .`)

If you plan to use Gurobi or another solver other than HiGHS, you should add the corresponding Julia package to your Julia environment, [as described in the section above](#installing-gurobi-or-an-alternative-solver).

Here is a snapshot for you to see the commands in action. The user instantiates the environment and then builds Gurobi. Not shown, is that they added the Gurobi package to the environment using `add Gurobi` before instantiating.

![Screen Shot 2023-09-07 at 11 19 22 AM](https://github.com/macroenergy/Dolphyn.jl/assets/2174909/8e5720fd-28f5-4bdc-840c-70fec0212cd3)

You can now press backspace to exit the Julia package manager and start using DOLPHYN by [running your first example](#running-your-first-example).

### Second+ time running DOLPHYN:

In your command terminal (not the Julia REPL), navigate to your DOLPHYN folder then run the following commands:

`julia --project=.`

`julia> ]`

`(DOLPHYN) pkg> st` (this is for checking the status of packages installed for DOLPHYN)

## DOLPHYN Team

The original version of the model was [developed](https://pubs.rsc.org/en/content/articlehtml/2021/ee/d1ee00627d) by [Guannan He](https://www.guannanhe.com/) while at the MIT Energy Initiative, and is now maintained by a team contributors at New York University (NYU), led by [Dharik Mallapragada](https://engineering.nyu.edu/faculty/dharik-mallapragada), [Massachusetts Institute of Technology](https://energy.mit.edu/), led by Ruaridh Macdonald, as well as Guannan He's research group at Peking University. Key contributors include Dharik S. Mallapragada, Ruaridh Macdonald, Guannan He, Mary Bennett, Shantanu Chakraborty, Anna Cybulsky, Michael Giovanniello, Jun Wen Law, Youssef Shaker, Nicole Shi and Yuheng Zhang.

## Citing DOLPHYN
G. He, D. S. Mallapragada, R. Macdonald, J. W. Law, Y. Shaker, Y. Zhang, A. Cybulsky, S. Chakraborty, M. Giovanniello. DOLPHYN: decision optimization for low-carbon power and hydrogen networks. n.d. https://github.com/macroenergy/Dolphyn.jl
