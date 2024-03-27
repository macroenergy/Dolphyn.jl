

@doc raw"""
    configure_solver(solver::String, solver_settings_path::String)

This method returns a solver-specific MathOptInterface OptimizerWithAttributes optimizer instance to be used in the DOLPHYN.generate\_model() method.

The "solver" argument is a string which specifies the solver to be used. It is not case sensitive.
Currently supported solvers include: "Clp", "Cbc", "HiGHS", "Gurobi" or "CPLEX".

The "solver\_settings\_path" argument is a string which specifies the path to the directory that contains the settings YAML file for the specified solver.

"""
function configure_solver(solver_name::String, solver_settings_path::String, solver::DataType=HiGHS.Optimizer)

    solver_name = lowercase(solver_name)

    solvers = Dict{String,Dict{String,Any}}(
        "highs" => Dict{String,Any}(
            "name" => "HiGHS",
            "settings_path" => joinpath(solver_settings_path, "highs_settings.yml"),
            "config_function" => configure_highs
        ),
        "gurobi" => Dict{String,Any}(
            "name" => "Gurobi",
            "settings_path" => joinpath(solver_settings_path, "gurobi_settings.yml"),
            "config_function" => configure_gurobi
        ),
        "cplex" => Dict{String,Any}(
            "name" => "CPLEX",
            "settings_path" => joinpath(solver_settings_path, "cplex_settings.yml"),
            "config_function" => configure_cplex
        ),
        "clp" => Dict{String,Any}(
            "name" => "Clp",
            "settings_path" => joinpath(solver_settings_path, "clp_settings.yml"),
            "config_function" => configure_clp
        ),
        "cbc" => Dict{String,Any}(
            "name" => "Cbc",
            "settings_path" => joinpath(solver_settings_path, "cbc_settings.yml"),
            "config_function" => configure_cbc
        )
    )

    # Set solver as HiGHS
    if solver_name == "highs"
        if check_if_solver_loaded("HiGHS")
            optimizer = configure_highs(solvers["highs"]["settings_path"], solver)
        else
            error("
                HiGHS is not an available solver on your computer.
                Please check DOLPHYN has been installed correctly.
            ")
        end
    else
        if haskey(solvers, solver_name)
            optimizer = check_solver_and_configure(solvers[solver_name], solver)
        else
            error("
                $solver is not a supported solver.
                Please choose from: $(join(keys(solvers), ", ")).
            ")
        end
    end
    return optimizer
end

function check_solver_and_configure(solver_details::Dict, solver::DataType)
    optimizer_name = solver_details["name"]
    if check_if_solver_loaded(optimizer_name)
        println("-- Using $optimizer_name")
        optimizer = solver_details["config_function"](solver_details["settings_path"], solver)
        return optimizer
    else
        if check_if_solver_installed(optimizer_name)
            error_solver_not_loaded(optimizer_name)
        else
            error_solver_not_installed(optimizer_name)
        end
    end
    return nothing
end

function find_optimizer_packagename(optimizer::DataType)
    return lowercase(string(parentmodule(optimizer)))
end

function check_if_solver_loaded(optimizer_name::AbstractString)
    return optimizer_name in string.(Base.loaded_modules_array())
end

function check_if_solver_installed(optimizer_name::AbstractString)
    return Base.find_package(optimizer_name) !== nothing
end

function error_solver_not_loaded(optimizer_name::AbstractString)
    error("
        $optimizer_name is not an available solver but it appears to be in your Julia environment.
        Either change the solver to HiGHS, which is included with DOLPHYN,
        or include $optimizer_name in your runfile and change the solver passed to configure_solver().
    ")
end

function error_solver_not_installed(optimizer_name::AbstractString)
    error("
        $optimizer_name is not in your Julia environment.
        Either change the solver to HiGHS, which is included with DOLPHYN,
        or install $optimizer_name, add it to your Julia environment,
        and include it in your runfile and change the solver passed to configure_solver().
    ")
end