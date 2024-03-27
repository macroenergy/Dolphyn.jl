

@doc raw"""
    print_and_log(message::AbstractString)

This function takes a message which is one-piece string in julia and print it in console or
log file depending on global ```Log``` flag.
"""
function print_and_log(message::AbstractString)

    # Log is set as global variable

    if Log
        println(message)
        @info("$(Dates.format(now(), "yyyy-mm-dd HH:MM:SS")) $message")
    else
        println(message)
    end

end
