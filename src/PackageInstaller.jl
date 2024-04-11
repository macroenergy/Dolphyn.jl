using Pkg
import TOML

# Define the path to the 'Project.toml' file
const PROJECT_TOML_PATH = "./Project.toml"

# Read dependency information from 'Project.toml'
function read_deps_from_project_toml(path)
    # Parse the TOML file
    parsed_toml = TOML.parsefile(path)
    # Retrieve the dictionary of dependencies
    return get(parsed_toml, "deps", Dict())
end

# Install dependency packages
function install_dependencies(deps)
    for pkg in keys(deps)
        # Print installation message
        println("Installing package: ", pkg)
        # Install (or update to) the latest version
        Pkg.add(pkg)
    end
end

# Read and install dependencies from 'Project.toml'
function install_from_project_toml(path)
    # Read dependencies
    deps = read_deps_from_project_toml(path)
    # Install dependencies
    install_dependencies(deps)
    println("All required packages have been installed.")
end

# Execute the installation process
install_from_project_toml(PROJECT_TOML_PATH)

