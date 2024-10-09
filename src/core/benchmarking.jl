function format_summary(summary)
    if length(summary) == 1
        return summary
    end
    # Find the number of elements in the summary array, splitting on "|"
    num_elem = maximum(length(split(s,"|")) for s in summary)
    # Pad each element so the "|" are aligned
    summary = [split(s,"|") for s in summary]
    for idx in 2:num_elem
        max_length = maximum([length(s[1]) for s in summary])
        for s in summary
            if idx > length(s)
                continue
            end
            s[1] = "$(s[1])$(repeat(" ", max_length - length(s[1]))) | $(s[idx])"
        end
    end
    summary = [s[1] for s in summary]
    return summary
end