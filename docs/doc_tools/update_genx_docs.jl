function insert_new_genx_pages!(pages::OrderedDict, genx_doc_path::String)
# Try to insert GenX pages if they exist
    if isdir(genx_doc_path)
        genx_pages = get_pages_dict(joinpath(genx_doc_path, "make.jl"))
        if haskey(genx_pages, "Model Inputs/Outputs Documentation")
            pages["Model Inputs/Outputs Documentation"][2] = "GenX Database Documentation" => genx_pages["Model Inputs/Outputs Documentation"]
        end
        if haskey(genx_pages, "Model Function Reference")
            pages["GenX"][5] = "GenX Function Reference" => genx_pages["Model Function Reference"]
        end
        if haskey(genx_pages, "Notation")
            pages["GenX"][3] = "Genx Notation" => genx_pages["Notation"]
        end
    end
end

function change_module_to_dolphyn(filepath::String)
    # Read a file line by line
    # If the line contains Modules = [GenX], replace it with Modules = [DOLPHYN]
    # Save the lines as arrays.
    lines = []
    open(filepath) do file
        for line in eachline(file)
            if contains(line, "Modules = [GenX]")
                line = "Modules = [DOLPHYN]"
            end
            push!(lines, line)
        end
    end
    return lines
end

function update_genx_docs(genx_doc_path::String)
    # List all the genx and dolphyn doc files
    genx_docs = readdir(joinpath(genx_doc_path, "src"))
    dolphyn_doc_path = dirname(@__DIR__)
    dolphyn_docs = readdir(joinpath(dolphyn_doc_path, "src"))
    # For each doc in genx_docs, copy or replace it in dolphyn_docs
    for doc in genx_docs
        if !contains(doc, ".md")
            continue
        end
        if !(doc in dolphyn_docs)
            print("Copying $doc from GenX to DOLPHYN --- ")
            updated_file = change_module_to_dolphyn(joinpath(genx_doc_path, "src", doc))
            open(joinpath(dolphyn_doc_path, "src", doc), "w") do file
                for line in updated_file
                    println(file, line)
                end
            end
            print("Done\n")
        end
    end
end

# Copy all assets from GenX to DOLPHYN
function copy_assets(genx_doc_path::String)
    genx_assets = readdir(joinpath(genx_doc_path, "src", "assets"))
    dolphyn_doc_path = dirname(@__DIR__)
    for asset in genx_assets
        if !contains(asset, ".")
            continue
        end
        if !isfile(joinpath(dolphyn_doc_path, "src", "assets", asset))
            cp(joinpath(genx_doc_path, "src", "assets", asset), joinpath(@__DIR__, "src", "assets", asset))
        end
    end
end