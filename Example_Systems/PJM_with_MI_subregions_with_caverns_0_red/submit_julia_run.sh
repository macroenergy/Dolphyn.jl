#!/bin/bash

# Step 1: Load julia and gurobi
module load julia/1.8.5
module load gurobi/gurobi-1000

# Step 2: Navigate to the DOLPHYNJulEnv directory and remove the Manifest.toml file
cd DOLPHYNJulEnv/
rm Manifest.toml

# Step 3: Go back to the previous directory
cd ..

# Step 4 to 8: Open Julia and perform various operations
julia << EOF
# Step 5: Go to packages and activate the DOLPHYNJulEnv
using Pkg
Pkg.activate("DOLPHYN")

# Step 7: Instantiate the packages
Pkg.instantiate()

# Step 8: Exit Julia
exit()
EOF

# Step 9: Run the LLsub command
LLsub Run.sh
