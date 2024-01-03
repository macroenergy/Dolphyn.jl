using Pkg

# List of required packages
required_packages = [
    "JuMP",
    "DataFrames",
    "CSV",
    "StatsBase",
    "LinearAlgebra",
    "YAML",
    "Dates",
    "Clustering",
    "Distances",
    "Combinatorics",
    "Revise",
    "Glob",
    "LoggingExtras",
    "Random",
    "RecursiveArrayTools",
    "Statistics",
    "HiGHS"
]

# Function to check and install missing packages
function install_missing_packages(packages)
    for package in packages
        if !any(x -> x.name == package, Pkg.installed())
            println("Installing missing package: ", package)
            Pkg.add(package)
        else
            println("Package already installed: ", package)
        end
    end
end

# Install missing packages
install_missing_packages(required_packages)

println("All required packages are installed.")
