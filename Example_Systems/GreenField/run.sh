#!/bin/bash

#SBATCH --job-name="CSC_TEST_2022_08_11"
#SBATCH --output="%j.out"
#SBATCH --error="%j.err"

#SBATCH --mail-type=fail
#SBATCH --mail-user="2845024327@qq.com"

#SBATCH -p C032M0128G
#SBATCH --qos=normal

#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32

module load ~/modulefiles/julia/1.7.3
module load ~/modulefiles/gurobi/9.1.2

julia Run.jl
