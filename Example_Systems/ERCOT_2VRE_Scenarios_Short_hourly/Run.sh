#!/bin/bash
#SBATCH --job-name=_full_test        # create a short name for your job
#SBATCH --nodes=1                           # node count
#SBATCH --ntasks=1                          # total number of tasks across all nodes
#SBATCH --cpus-per-task=5                  # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=25G                    # memory per cpu-core
#SBATCH --time=48:00:00                     # total run time limit (HH:MM:SS)
#SBATCH --output="./Example_Systems/2_VRE_Scenarios_Short_hourly/H2_test-%j.out"
#SBATCH --error="./Example_Systems/2_VRE_Scenarios_Short_hourly/H2_test-%j.err"
#SBATCH --mail-type=FAIL                    # notifications for job done & fail
#SBATCH --mail-user=magio1@mit.edu          # send-to address
#!/bin/bash

source /etc/profile
module load julia/1.9.2
module load gurobi/gurobi-1000

#echo "My SLURM_ARRAY_TASK_ID: " $LLSUB_RANK
#echo "Number of Tasks: " $LLSUB_SIZE

# export GUROBI_HOME = "/home/gridsan/mgiovanniello/gurobi1000/linux64"

julia --project=. ./Example_Systems/2_VRE_Scenarios_Short_hourly/Run.jl

dates
