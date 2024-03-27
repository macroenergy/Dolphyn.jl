

@doc raw"""
    compare_results(path1::AbstractString, path2::AbstractString, output_filename::AbstractString="summary.txt")

This function compares the contents of two directories and returns a summary file of the differences
"""
function compare_results(
    path1::AbstractString,
    path2::AbstractString,
    output_filename::AbstractString = "summary.txt",
)
    ## Check that the paths are valid
    if !isdir(path1) || !isdir(path2) || path1 == path2
        println("One or Both of the Paths Doesn't Exist or They are the Same")
    else
        lines_to_write, identical_structure, identical_contents = compare_dir(path1, path2)
        if identical_structure
            println("Structure of $path1 and $path2 is Identical")
        end
        if identical_contents
            println("Contents of $path1 and $path2 is Identical")
        end
        if !identical_structure || !identical_contents
            print_comparison(lines_to_write, output_filename)
        end
    end
end

@doc raw"""
    print_comparison(path1::AbstractString, path2::AbstractString, output_filename::AbstractString="summary.txt")

Takes a string array of differences between two directories and prints them to a file
"""
function print_comparison(
    lines_to_write::Array{Any,1},
    output_filename::AbstractString = "summary.txt",
)
    summary_file = open(output_filename, "a")
    write(summary_file, join(lines_to_write))
    close(summary_file)
end

@doc raw"""
    compare_dir(path1::AbstractString, path2::AbstractString)

Compares the contents of two directories and returns a string array of the differences
"""
function compare_dir(path1::AbstractString, path2::AbstractString, inset::String = "")
    # Get the list of files in each directory
    files1 = filter(x -> !any(occursin.(["log", "lp", "txt"], x)), readdir(path1))
    files2 = filter(x -> !any(occursin.(["log", "lp", "txt"], x)), readdir(path2))
    dirname1 = split(path1, "\\")[end]
    dirname2 = split(path2, "\\")[end]

    ## Flag denoting whether the structure and contents are identical
    identical_structure = true
    identical_contents = true

    # Get the list of files that are in both directories
    common_files = intersect(files1, files2)

    # Get the list of files that are in only one directory
    only1 = setdiff(files1, common_files)
    only2 = setdiff(files2, common_files)

    # Create a summary file

    lines_to_write = []
    push!(lines_to_write, "$(inset)Comparing the following directories:\n")
    push!(lines_to_write, "$(inset)--- $dirname1 ---\n")
    push!(lines_to_write, "$(inset)--- $dirname2 ---\n")
    push!(lines_to_write, "\n")

    # Write the summary file
    if length(only1) > 0
        push!(lines_to_write, "$(inset)Files in $dirname1 but not in $dirname2:\n")
        push!(lines_to_write, join([inset, join(only1, "\n$inset")]))
        push!(lines_to_write, "\n")
        identical_structure = false
    end
    if length(only2) > 0
        push!(lines_to_write, "$(inset)Files in $dirname2 but not in $dirname1:\n")
        push!(lines_to_write, join([inset, join(only2, "\n$inset")]))
        push!(lines_to_write, "\n")
        identical_structure = false
    end
    if length(only1) == 0 && length(only2) == 0
        push!(
            lines_to_write,
            "$(inset)Both directories contain the same files and subdirectories\n",
        )
    end
    push!(lines_to_write, "\n")

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
            identical_contents = false
        else
            push!(lines_to_write, join([inset, "No mismatched result files"]))
        end
        push!(lines_to_write, "\n")

        if length(subdirs) > 0
            push!(lines_to_write, "\n")
            push!(lines_to_write, join([inset, "Sub-directories"]))
            push!(lines_to_write, "\n")
            for subdir in subdirs
                lines_to_write = [
                    lines_to_write
                    first(
                        compare_dir(
                            joinpath(path1, subdir),
                            joinpath(path2, subdir),
                            join([inset, "  "]),
                        ),
                    )
                ]
            end
            push!(lines_to_write, "\n")
        end
    end
    return lines_to_write, identical_structure, identical_contents
end

@doc raw"""
    filecmp_byte(path1::AbstractString, path2::AbstractString)

Compare two files on a byte-wise basis and return a boolean indicating whether they are identical
"""
function filecmp_byte(path1::AbstractString, path2::AbstractString)
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

function filecmp_str(path1::AbstractString, path2::AbstractString)
    open(path1, "r") do file1
        open(path2, "r") do file2
            while !eof(file1) && !eof(file2)
                line1 = readline(file1)
                line2 = readline(file2)
                if line1 != line2
                    return false
                end
            end
            return eof(file1) == eof(file2)
        end
    end
end

function filecmp(path1::AbstractString, path2::AbstractString)
    # First do quick (but slightly temperamental) byte comparison
    if filecmp_byte(path1, path2)
        return true
    else
        # If that fails, do a line-by-line comparison
        if filecmp_str(path1, path2)
            return true
        else
            return false
        end
    end
end
