#!/bin/bash

#SBATCH --job-name="CSC_NO_COMMIT_TEST_2022_07_12"
#SBATCH --output="CSC_NO_COMMIT_TEST_2022_07_12.%A.%a.out"
#SBATCH --error="CSC_NO_COMMIT_TEST_2022_07_12.%A.%a.err"

#SBATCH --mail-type=fail
#SBATCH --mail-user="2845024327@qq.com"

#SBATCH -p C032M0128G
#SBATCH --qos=low

#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8

module load ~/modulefiles/julia/1.7.3
module load ~/modulefiles/gurobi/9.1.2

julia Run.jl
