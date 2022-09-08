"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
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

################################################################################
## function output
##
## description: Writes results to multiple .csv output files in path directory
##
## returns: n/a
################################################################################
@doc raw"""
	write_outputs(EP::Model, path::AbstractString, setup::Dict, inputs::Dict)

Function for the entry-point for writing the different output files. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_CSC_outputs(EP::Model, path::AbstractString, setup::Dict, inputs::Dict)

  ## Use appropriate directory separator depending on Mac or Windows config
  if Sys.isunix()
    sep = "/"
    elseif Sys.iswindows()
    sep = "\U005c"
    else
        sep = "/"
  end
    # Create directory if it does not exist
    if !(isdir(path))
      mkdir(path)
    end

    write_co2_capture_capacity(path, sep, inputs, setup, EP)
    write_co2_capture_plant(path, sep, inputs, setup, EP)
    write_co2_capture_zone(path, sep, inputs, setup, EP)
    write_co2_capture_costs(path, sep, inputs, setup, EP)
    write_co2_fuel_emission(path, sep, inputs, setup, EP)
    write_co2_capture_power_consumption(path, sep, inputs, setup, EP)
    
    write_co2_storage_injection_power_consumption(path, sep, inputs, setup, EP)
    write_co2_storage_injection_plant(path, sep, inputs, setup, EP)
    write_co2_storage_injection_zone(path, sep, inputs, setup, EP)
    write_co2_storage_injection_costs(path, sep, inputs, setup, EP)
    write_co2_storage_injection_capacity(path, sep, inputs, setup, EP)

    write_co2_capture_compression_power_consumption(path, sep, inputs, setup, EP)
    write_co2_capture_compression_plant(path, sep, inputs, setup, EP)
    write_co2_capture_compression_zone(path, sep, inputs, setup, EP)
    write_co2_capture_compression_costs(path, sep, inputs, setup, EP)
    write_co2_capture_compression_capacity(path, sep, inputs, setup, EP)

    write_power_plant_co2_captured(path, sep, inputs, setup, EP)
    write_power_zone_co2_captured(path, sep, inputs, setup, EP)

    if setup["ModelH2"] == 1
      write_hydrogen_plant_co2_captured(path, sep, inputs, setup, EP)
      write_hydrogen_zone_co2_captured(path, sep, inputs, setup, EP)
    end
    
    if setup["ModelCO2Pipelines"] ==1 

      write_co2_pipeline_flow(path, sep, inputs, setup, EP)
      write_co2_pipeline_expansion(path, sep, inputs, setup, EP)
      write_co2_pipeline_power_consumption(path, sep, inputs, setup, EP)
      write_co2_pipeline_power_consumption_comp(path, sep, inputs, setup, EP)

      if setup["CO2Pipeline_Loss"] ==1 
        write_co2_pipeline_loss(path, sep, inputs, setup, EP)
      end
    end
    
    
  ## Print confirmation
  println("Wrote CSC outputs to $path$sep")

end # END output()
