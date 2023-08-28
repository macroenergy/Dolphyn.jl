#!/bin/bash

# SLURM directives for job configuration:

#SBATCH --job-name=ThreeZones        # Sets the job name to "ThreeZones".
#SBATCH --nodes=1                    # Requests 1 node.
#SBATCH --ntasks=1                   # Requests 1 task in total for all nodes.
#SBATCH --cpus-per-task=8            # Requests 8 CPU cores per task.
#SBATCH --mem-per-cpu=10G            # Allocates 10G memory per CPU core.
#SBATCH --time=12:00:00              # Sets the max run time limit to 12 hours.
#SBATCH --output="test.out"          # Directs the job's standard output to "test.out".
#SBATCH --error="test.err"           # Directs the job's standard error to "test.err".

# Set up environment:

source /etc/profile                  # Sources the global profile, setting up the shell environment.
module load julia/1.8.5              # Loads the Julia module (version 1.8.5).
module load gurobi/gurobi-1000      # Loads the Gurobi optimizer module (version gurobi-1000).

# Loop to process directories and run Julia scripts:

# Define the base directory path for the looping directories.
base_dir="/home/gridsan/larmstrong/DOLPHYN_modeling/DOLPHYN-dev/supercloud_run_all"

# Define the base directory path for the Julia project.
julia_project_dir="/home/gridsan/larmstrong/DOLPHYN_modeling/DOLPHYN-dev"

# Loop through all sub-directories in supercloud_run_all.
for dir in $base_dir/*; do
    
    # Check if the item is a directory.
    if [ -d "$dir" ]; then
        # Print notifications:
        echo "-----------------------------------------------------"
        echo "Accessing directory: $dir"
        
        # Formulate the full path to the Run.jl in the current directory.
        run_script_path="$dir/Run.jl"
        
        # Check for the existence of "Run.jl" and execute it if found.
        if [ -f "$run_script_path" ]; then
            echo "Running the Run.jl script in $dir"
            # Print the current directory
            echo "Current directory is: $(pwd)"
            echo "Julia Project Dir is: $julia_project_dir"
            echo "Run Script Pathway is: $run_script_path"

            julia --project=. $run_script_path
        else
            echo "No Run.jl found in $dir"
        fi
    fi
done


# Print a final notification:
echo "-----------------------------------------------------"
echo "Finished processing all directories."

# Print the current date and time as a timestamp:
date
