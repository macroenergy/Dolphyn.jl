The MGA formulation is implemented in src/additional_tools/modeling_to_generate_alternatives.jl. An extra line was added to DOLPHYN.jl to read this file. Example_Systems/Eastern_US/ThreeZones has example results from MGA runs.

This commit also has src output writing files written closely in accordance with the genx_as_submodule branch for more efficient writing of output files.
