"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

import Pkg
using Pkg
Pkg.activate("DOLPHYNJulEnv")
Pkg.add(Pkg.PackageSpec(name="Cbc", version="0.8.0"))
Pkg.add(Pkg.PackageSpec(name="Clp", version="0.8.4"))
Pkg.add(Pkg.PackageSpec(name="HiGHS", version="1.1.4"))
Pkg.add(Pkg.PackageSpec(name="DataStructures", version="0.18.9"))
Pkg.add(Pkg.PackageSpec(name="Dates"))
Pkg.add(Pkg.PackageSpec(name="GLPK", version="0.14.12"))
Pkg.add(Pkg.PackageSpec(name="Ipopt", version="0.7.0"))
Pkg.add(Pkg.PackageSpec(name="JuMP", version="0.21.8"))
Pkg.add("MathOptInterface")
#Pkg.add(Pkg.PackageSpec(name="CPLEX", version="0.7.7"))
Pkg.add(Pkg.PackageSpec(name="CSV", version="0.8.5"))
Pkg.add(Pkg.PackageSpec(name="Clustering", version="0.14.2"))
Pkg.add(Pkg.PackageSpec(name="Combinatorics", version="1.0.2"))
Pkg.add(Pkg.PackageSpec(name="Distances", version="0.10.3"))
Pkg.add(Pkg.PackageSpec(name="DataFrames", version="1.0.0")) #0.20.2
Pkg.add(Pkg.PackageSpec(name="Documenter", version="0.27.3"))
Pkg.add(Pkg.PackageSpec(name="DocumenterTools", version="0.1.13"))
Pkg.add(Pkg.PackageSpec(name="Gurobi", version="0.11.3"))

# Julia environment variable GUROBI_HOME set to your running machine location
# ENV["GUROBI_HOME"] = "/usr/local/gurobi/gurobi912/linux64/"
Pkg.build("Gurobi")
Pkg.pin(Pkg.PackageSpec(name="Gurobi", version="0.11.3"))

##Add if elseif with Method of Morris for these
Pkg.add(Pkg.PackageSpec(name="DiffEqSensitivity", version="6.52.1"))
Pkg.add(Pkg.PackageSpec(name="Statistics"))
Pkg.add(Pkg.PackageSpec(name="OrdinaryDiffEq", version="5.60.1"))
Pkg.add(Pkg.PackageSpec(name="QuasiMonteCarlo", version="0.2.3"))
##Add if elseif with Method of Morris for these
Pkg.add(Pkg.PackageSpec(name="BenchmarkTools", version="1.1.1"))
Pkg.add(Pkg.PackageSpec(name="MathProgBase", version="0.7.8"))
Pkg.add(Pkg.PackageSpec(name="StatsBase", version="0.33.8"))
Pkg.add(Pkg.PackageSpec(name="YAML", version="0.4.7"))
Pkg.add(Pkg.PackageSpec(name="LinearAlgebra"))
Pkg.add(Pkg.PackageSpec(name="Revise"))

# Logging
Pkg.add(Pkg.PackageSpec(name="Logging"))
Pkg.add(Pkg.PackageSpec(name="LoggingExtras"))