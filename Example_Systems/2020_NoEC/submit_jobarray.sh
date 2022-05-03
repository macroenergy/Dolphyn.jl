#!/bin/bash

#SBATCH --job-name="T1"
#SBATCH --output="FoS.%j.%N.out"
#SBATCH --error="FoS.%j.%N.err"

#SBATCH -c 8

# Initialize Modules
source /etc/profile #keep this

module load julia/1.6.1
module load gurobi/gurobi-903

julia RunCloud.jl
