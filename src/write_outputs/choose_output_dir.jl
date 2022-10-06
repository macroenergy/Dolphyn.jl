"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	path = choose_output_dir(pathinit)

Avoid overwriting (potentially important) existing results by appending to the directory name\n
Checks if the suggested output directory already exists. While yes, it appends _1, _2, etc till an unused name is found
"""
function choose_output_dir(pathinit::String)
    path = pathinit
    counter = 1

    while isdir(path)
        path = string(pathinit, "_", counter)
        counter += 1
    end

    return path

end
