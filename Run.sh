#!/bin/bash
#SBATCH --job-name=ThreeZones        # create a short name for your job
#SBATCH --nodes=1              # node count
#SBATCH --ntasks=1             # total number of tasks across all nodes
#SBATCH --cpus-per-task=8          # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=10G          # memory per cpu-core
#SBATCH --time=12:00:00           # total run time limit (HH:MM:SS)
#SBATCH --output="test.out"
#SBATCH --error="test.err"

# Initialize module
source /etc/profile
module load julia/1.8.5
module load gurobi/gurobi-1000
julia --project=. /home/gridsan/larmstrong/DOLPHYN_modeling/DOLPHYN-dev/supercloud_run_all/PJM_with_MI_subregions_no_caverns_0_red/Run.jl
date