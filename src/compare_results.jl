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


function compare_results(path1::AbstractString, path2::AbstractString, output_filename::AbstractString="summary.txt")
    lines_to_write = compare_dir(path1, path2)
    print_comparison(lines_to_write, output_filename)
end

function print_comparison(lines_to_write::Array{Any,1}, output_filename::AbstractString="summary.txt")
    summary_file = open(output_filename, "w")
    write(summary_file, join(lines_to_write))
    close(summary_file)
end

@doc raw"""
    compare_dir(path1::AbstractString, path2::AbstractString)

This function compares the contents of two directories and returns a summary file of the differences
"""
function compare_dir(path1::AbstractString, path2::AbstractString, inset::String="")
    # Get the list of files in each directory
    files1 = readdir(path1)
    files2 = readdir(path2)
    dirname1 = split(path1, "\\")[end]
    dirname2 = split(path2, "\\")[end]

    # Get the list of files that are in both directories
    common_files = intersect(files1, files2)

    # Get the list of files that are in only one directory
    only1 = setdiff(files1, common_files)
    only2 = setdiff(files2, common_files)

    # Create a summary file
    
    lines_to_write = []
    push!(lines_to_write, "$inset--- $dirname2 ---\n")

    # Write the summary file
    if length(only1) > 0
        push!(lines_to_write, join([inset, "Files in $dirname1 but not in $dirname2:"]))
        for file in only1
            push!(lines_to_write, file)
        end
    end
    if length(only2) > 0
        push!(lines_to_write, join([inset, "Files in $dirname2 but not in $dirname1:"]))
        for file in only2
            push!(lines_to_write, file)
        end
    end
    
    common_files_matching = []
    common_files_diff = []
    subdirs = []

    if length(common_files) > 0
        push!(lines_to_write, join([inset, "Files in both $dirname1 and $dirname2:\n"]))
        for file in common_files
            if isfile(joinpath(path1, file)) || isfile(joinpath(path2, file))
                # Compare the files by byte comparison
                if filecmp(joinpath(path1, file), joinpath(path2, file))
                    push!(common_files_matching, file)
                else
                    push!(common_files_diff, file)
                end
            elseif isdir(joinpath(path1, file)) || isdir(joinpath(path2, file))
                push!(subdirs, file)
            end
        end
        push!(lines_to_write, "\n")
        if length(common_files_matching) > 0
            push!(lines_to_write, join([inset, "Matching result files: \n"]))
            push!(lines_to_write, join([inset, join(common_files_matching, "\n$inset")]))
        else
            push!(lines_to_write, join([inset, "No matching result files"]))
        end
        push!(lines_to_write, "\n")
        push!(lines_to_write, "\n")
        if length(common_files_diff) > 0
            push!(lines_to_write, join([inset, "Mismatched result files: \n"]))
            push!(lines_to_write, join([inset, join(common_files_diff, "\n$inset")]))
        else
            push!(lines_to_write, join([inset, "No mismatched result files"]))
        end
        push!(lines_to_write, "\n")

        if length(subdirs) > 0
            push!(lines_to_write, "\n")
            push!(lines_to_write, join([inset, "Sub-directories"]))
            push!(lines_to_write, "\n ")
            for subdir in subdirs
                lines_to_write = [lines_to_write; compare_dir(joinpath(path1, subdir), joinpath(path2, subdir), join([inset, "  "]))]
            end
        end
    end
    return lines_to_write
end
    
@doc raw"""
    filecmp(path1::AbstractString, path2::AbstractString)

Compare two files on a byte-wise basis and return a boolean indicating whether they are identical
"""
function filecmp(path1::AbstractString, path2::AbstractString)
    stat1, stat2 = stat(path1), stat(path2)
    if !(isfile(stat1) && isfile(stat2)) || filesize(stat1) != filesize(stat2)
        return false # or should it throw if a file doesn't exist?
    end
    stat1 == stat2 && return true # same file
    open(path1, "r") do file1
        open(path2, "r") do file2
            buf1 = Vector{UInt8}(undef, 32768)
            buf2 = similar(buf1)
            while !eof(file1) && !eof(file2)
                n1 = readbytes!(file1, buf1)
                n2 = readbytes!(file2, buf2)
                n1 != n2 && return false
                0 != Base._memcmp(buf1, buf2, n1) && return false
            end
            return eof(file1) == eof(file2)
        end
    end
end