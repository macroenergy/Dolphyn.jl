# DOLPHYN Documentation

```@meta
CurrentModule = DOLPHYN
```

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

## Installing DOLPHYN

### If you are doing a fresh install

#### ZIP download

If you would like a one-time download of DOLPHYN which is not set up to pull updates using git, then simply download and unzip the files [using this link](https://github.com/macroenergy/DOLPHYN/archive/refs/heads/main.zip).

#### Fresh Install Using GitHub Desktop

Use the File -> Clone Respository -> URL dropdown menu to clone the DOLPHYN repository from:

- https://github.com/macroenergy/DOLPHYN.git

#### Fresh Install Using GitHub via your terminal / command line

In the top-level folder where you want to place DOLPHYN, run:

- <code>git clone https://github.com/macroenergy/DOLPHYN</code>

### If you are working from an existing project

#### Existing Project Using GitHub Desktop

Pull the latest version of DOLPHYN from the main branch. If you previously used the verison of DOLPHYN where GenX was a submodule (as opposed to ordinary folder as it is now) then some of the submodule config files may remain in your project. The easiest solution is to delete your entire DOLPHYN folder from your computer and re-clone the repository.

#### Existing Project Using GitHub via your terminal / command line

In your top-level folder (generally DOLPHYN or DOLPHYN-DEV), run:

-	<code>git pull</code>
-	<code>git checkout main</code>
-	<code>cd src/GenX</code>

## Install the Gurobi and / or HiGHS solvers

HiGHS will be automatically downloaded and installed when you instantiate the DOLPHYN Julia environment, so you do not need to download it separately. However if you would like to use a specific version of have a separate copy, it can be downloaded from: [https://highs.dev/](https://highs.dev/)

Gurobi is a commercial solver which requires either a free academic license or paid commercial license. You should download the latest version of the Gurobi Optimizer from:[https://www.gurobi.com/downloads/gurobi-software/](https://www.gurobi.com/downloads/gurobi-software/)

## Setting up the Julia environment

In order to run DOLPHYN, several Julia packages must be downloaded and installed. To help users install the correct packages and versions, we have created a Julia environment file. This file is located in the top-level DOLPHYN folder and is called `Project.toml`.

### First time running DOLPHYN

The first time you run DOLPHYN, you must instantiate the Julia environment. This will download and install all the required packages.

In your command terminal (not the Julia REPL), navigate to your DOLPHYN folder then run the following commands:

- <code>julia --project=.</code> (this starts the Julia REPL using the environment file found in the current directory)
- <code>julia> ]</code> (Enter ']' at the prompt)
- <code>(DOLPHYN) pkg> instantiate</code> (you should see DOLPHYN project name here, if not, enter `activate .`)
- <code>(DOLPHYN) pkg> build Gurobi</code> (if you plan to use Gurobi)

Here is a snapshot for you to see the commands (instantiate and build Gurobi) used from above:
![Screen Shot 2023-09-07 at 11 19 22 AM](https://github.com/macroenergy/DOLPHYN/assets/2174909/8e5720fd-28f5-4bdc-840c-70fec0212cd3)

If the step to build Gurobi fails, the most likely cause is that the Gurobi installation cannot be found. [Use the following instructions](https://support.gurobi.com/hc/en-us/articles/13443862111761-How-do-I-set-system-environment-variables-for-Gurobi-) to define the "GUROBI_HOME" and "GRB_LICENSE_FILE" environment variables on your computer. For example, for Gurobi 10.0 on Ubuntu they should point to:
- GUROBI_HOME = ...path to Gurobi install/gurobi1000/linux64
- GRB_LICENSE_FILE = ...path to Gurobi install/gurobi1000/gurobi.lic

You can now press backspace to exit the Julia package manager and start using DOLPHYN by [running your first example](#running-your-first-example).

### Second+ time running DOLPHYN:

In your command terminal (not the Julia REPL), navigate to your DOLPHYN folder then run the following commands:

- <code>julia --project=.</code>
- <code>julia> ]</code> 
- <code>(DOLPHYN) pkg> st</code> (this is for checking the status of packages installed for DOLPHYN)

## Running your first example: 

Navigate to one of the example systems, e.g.:

`julia> cd("Example_Systems/SmallNewEngland/OneZone")`

Ensure you are not in the package manager by hitting the backspace key.

Use the Run.jl file to run the case:

`julia> include("Run.jl")`

Once the model has completed running, results will be written into the "Results" folder.

## Example Systems

**SmallNewEngland: OneZone** is a one-year example with hourly resolution representing Massachusetts. A rate-based carbon cap of 50 gCO<sub>2</sub> per kWh is specified in the `CO2_cap.csv` input file. Expect a run time of ~5 seconds.

**SmallNewEngland: ThreeZones** is similar to the above example but contains zones representing Massachusetts, Connecticut, and Maine. Expect a run time of ~1 minute.

**NorthSea_2030** is a combined power and hydrogen model for the EU for the year 2030. It contains a power model with hourly resolution, contains zones representing Belgium, Germany, Denmark, France, Great Britain, the Netherlands, Sweden, and Norway. The model also includes a CO2 constraint representing 30% of 2015 power sector CO2 emissions applied to the hydrogen and power sector jointly. Expect a run time of ~10 minutes.

## DOLPHYN Team
The model was originally [developed](https://pubs.rsc.org/en/content/articlehtml/2021/ee/d1ee00627d) by [Guannan He](https://www.guannanhe.com/) while at the MIT Energy Initiative, and is now maintained by a team contributors at [MITEI](https://energy.mit.edu/) led by [Dharik Mallapragada](http://mallapragada.mit.edu/) and Ruaridh Macdonald as well as Guannan He's research group at Peking University. Key contributors include Dharik S. Mallapragada, Ruaridh Macdonald, Guannan He, Mary Bennett, Shantanu Chakraborty, Anna Cybulsky, Michael Giovanniello, Jun Wen Law, Youssef Shaker, Nicole Shi and Yuheng Zhang.
