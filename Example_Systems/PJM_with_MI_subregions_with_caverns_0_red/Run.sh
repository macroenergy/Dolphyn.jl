#!/bin/bash
#SBATCH --job-name=CTUS_99pRed        # create a short name for your job
#SBATCH --nodes=1              # node count
#SBATCH --ntasks=1             # total number of tasks across all nodes
#SBATCH --cpus-per-task=8          # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=10G          # memory per cpu-core
#SBATCH --time=36:00:00           # total run time limit (HH:MM:SS)
#SBATCH --output="test.out"
#SBATCH --error="test.err"
# Initialize module
source /etc/profile
module load julia/1.8.5
module load gurobi/gurobi-951
# julia Run.jl
julia --project=. /home/gridsan/larmstrong/DOLPHYN-dev/Example_Systems/PJM_with_MI_subregions_with_caverns_0_red/Run.jl
date
