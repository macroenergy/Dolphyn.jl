function parse_file(filepath::String)
    output_lines = Vector{String}()
    output_parse = Vector{Expr}()
    open(filepath, "r") do io
        active_str = ""
        long_comment = false
        for line in eachline(io)
            # Check for doc strings and ignore them
            if contains(line, """\"\"\"""")
                long_comment = !long_comment
                continue
            end
            if !long_comment
                # Remove comments
                if !startswith(strip(line), "#") && line != ""
                    # Remove end-of-line commments
                    line = split(line, "#")[1]
                    # Remove tabs
                    line = replace(line, "\t" => "")
                    active_str = string(active_str, "\n", line)
                    try Meta.parse(active_str)
                        parse = Meta.parse(active_str)
                        if parse.head == :incomplete
                            continue
                        end
                        # if parse.head == :incomplete && !startswith(strip(active_str), "function")
                            # continue
                        # end
                        push!(output_parse, parse)
                        push!(output_lines, active_str)
                        active_str = ""
                    catch
                        continue
                    end
                end
            end
        end
    end
    return (output_parse, output_lines)
end

function find_symbol_expr(output_parse::Vector{Expr}, target::Symbol)
    for e in output_parse
        if e.args[1] == target
            return e
        end
    end
    return nothing
end

function get_pages_dict(filepath::String)
    output_parse, _ = parse_file(filepath)
    pages_expr = find_symbol_expr(output_parse, :pages)
    if isnothing(pages_expr)
        return nothing
    end
    return eval(pages_expr.args[2])
end