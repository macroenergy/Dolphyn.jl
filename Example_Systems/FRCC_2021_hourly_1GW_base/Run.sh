#!/bin/bash
#SBATCH --job-name=hourly_1GW_FRCC_2021              # create a short name for your job
#SBATCH --nodes=1                           # node count
#SBATCH --ntasks=1                          # total number of tasks across all nodes
#SBATCH --cpus-per-task=8                   # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --time=12:00:00                     # total run time limit (HH:MM:SS)
#SBATCH --output="test.out"
#SBATCH --error="test.err"
#SBATCH --mail-type=FAIL                    # notifications for job done & fail
#SBATCH --mail-user=dharik@mit.edu          # send-to address

source /etc/profile
module load julia/1.7.3

export GUROBI_HOME="/home/gridsan/dmallapragada/gurobi912/linux64"

julia --project=/home/gridsan/dmallapragada/Time_matching/DOLPHYN-dev_hourly/DOLPHYNJulEnv Run.jl

date
