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

################################################################################
## function output
##
## description: Writes results to multiple .csv output files in path directory
##
## returns: n/a
################################################################################
@doc raw"""
	write_BESC_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

Function for the entry-point for writing the different output files. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_BESC_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

   ## Use appropriate directory separator depending on Mac or Windows config
   if Sys.isunix()
    sep = "/"
  elseif Sys.iswindows()
    sep = "\U005c"
  else
        sep = "/"
  end
  if !haskey(setup, "OverwriteResults") || setup["OverwriteResults"] == 1
    # Overwrite existing results if dir exists
    # This is the default behaviour when there is no flag, to avoid breaking existing code
    # Create directory if it does not exist
    path = joinpath(genx_path, "Results_BESC");
    if !(isdir(path))
        mkpath(path)
    end
  else
    # Find closest unused ouput directory name
    path = choose_besc_output_dir(genx_path)
    # Create directory if it does not exist
    if !(isdir(path))
        mkpath(path)
    end
  end

    write_BESC_costs(path, sep, inputs, setup, EP)
    write_bio_plant_capacity(path, sep, inputs, setup, EP)
    write_bio_zone_herb_consumed(path, sep, inputs, setup, EP)
    write_bio_zone_wood_consumed(path, sep, inputs, setup, EP)

    if setup["Bio_Electricity_On"] == 1
      write_bio_zone_bioelectricity_produced(path, sep, inputs, setup, EP)
    end

    if setup["Bio_H2_On"] == 1
      write_bio_zone_biohydrogen_produced(path, sep, inputs, setup, EP)
    end

    if setup["Bio_Diesel_On"] == 1
      write_bio_zone_biodiesel_produced(path, sep, inputs, setup, EP)
    end
    
    if setup["Bio_Jetfuel_On"] == 1
      write_bio_zone_biojetfuel_produced(path, sep, inputs, setup, EP)
    end

    if setup["Bio_Gasoline_On"] == 1
      write_bio_zone_biogasoline_produced(path, sep, inputs, setup, EP)
    end

    if setup["Bio_Ethanol_On"] == 1
      write_bio_zone_bioethanol_produced(path, sep, inputs, setup, EP)
    end
    
  ## Print confirmation
  println("Wrote BESC outputs to $path$sep")

end # END output()
