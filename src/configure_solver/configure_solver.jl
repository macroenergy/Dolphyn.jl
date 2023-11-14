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

@doc raw"""
    configure_solver(solver::String, solver_settings_path::String)

This method returns a solver-specific MathOptInterface OptimizerWithAttributes optimizer instance to be used in the DOLPHYN.generate\_model() method.

The "solver" argument is a string which specifies the solver to be used. It is not case sensitive.
Currently supported solvers include: "Clp", "Cbc", "HiGHS", "Gurobi" or "CPLEX".

The "solver\_settings\_path" argument is a string which specifies the path to the directory that contains the settings YAML file for the specified solver.

"""
function configure_solver(solver::String, solver_settings_path::String)

    solver = lowercase(solver)

    # Set solver as HiGHS
    if solver == "highs"
        if check_if_solver_available("HiGHS")
            highs_settings_path = joinpath(solver_settings_path, "highs_settings.yml")
            optimizer = configure_highs(highs_settings_path)
        else
            error("
                HiGHS is not an available solver on your computer.
                Please check DOLPHYN has been installed correctly.
            ")
        end
        
    # Set solver as Gurobi
    elseif solver == "gurobi"
        if check_if_solver_available("Gurobi")
            gurobi_settings_path = joinpath(solver_settings_path, "gurobi_settings.yml")
            optimizer = configure_gurobi(gurobi_settings_path)
        else
            error_on_solver("Gurobi")
        end
    # Set solver as CPLEX
    elseif solver == "cplex"
        if check_if_solver_available("CPLEX")
            cplex_settings_path = joinpath(solver_settings_path, "cplex_settings.yml")
            optimizer = configure_cplex(cplex_settings_path)
        else
            error_on_solver("CPLEX")
        end
    # Set solver as Clp
    elseif solver == "clp"
        if check_if_solver_available("Clp")
            clp_settings_path = joinpath(solver_settings_path, "clp_settings.yml")
            optimizer = configure_clp(clp_settings_path)
        else
            error_on_solver("Clp")
        end
    # Set solver as Cbc
    elseif solver == "cbc"
        if check_if_solver_available("Cbc")
            cbc_settings_path = joinpath(solver_settings_path, "cbc_settings.yml")
            optimizer = configure_cbc(cbc_settings_path)
        else
            error_on_solver("Cbc")
        end
    end
    return optimizer
end

function find_optimizer_packagename(optimizer::DataType)
    return lowercase(string(parentmodule(optimizer)))
end

function check_if_solver_available(optimizer_name::String)
    try
        eval(Meta.parse("using $optimizer_name"))
        return true
    catch
        return false
    end
end

function error_on_solver(optimizer_name::String)
    error("
        $optimizer_name is not an available solver on your computer.
        Either change the solver to HiGHS, which is included with DOLPHYN
        or install $optimizer_name and add it to your Julia environment.
    ")
end