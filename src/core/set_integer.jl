
function set_opVar_integer(commit_var::AbstractArray{VariableRef}, start_var::AbstractArray{VariableRef}, shut_var::AbstractArray{VariableRef})
    set_integer.(commit_var)
    set_integer.(start_var)
    set_integer.(shut_var)
end

function set_invVar_integer(ret_var::AbstractArray{VariableRef}, new_var::AbstractArray{VariableRef})
    set_integer.(ret_var)
    set_integer.(new_var)
end