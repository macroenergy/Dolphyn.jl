#!/bin/bash

#SBATCH -J "SevenZones_test" # Set Jobid

#SBATCH -n 1 # Number of task
#SBATCH -c 28 # CPU per task
#SBATCH -o "SevenZones_test.out" # Standard output file
#SBATCH -e "SevenZones_test.err" # Standard error file

srun julia Run.jl