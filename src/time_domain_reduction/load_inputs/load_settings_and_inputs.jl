@doc raw"""
    load_settings_and_inputs(inpath::String, settings_path::String, mysetup::Dict, v::Bool=false)
"""

function load_settings_and_inputs(inpath::String, settings_path::String, mysetup::Dict, v::Bool=false)

    # Define a local version of the setup so that you can modify the mysetup["ParameterScale"] value to be zero in case it is 1
    mysetup_local = copy(mysetup)
    # If ParameterScale =1 then make it zero, since clustered inputs will be scaled prior to generating model
    mysetup_local["ParameterScale"]=0  # Performing cluster and report outputs in user-provided units
    if v println(" -- Loading inputs") end

    myinputs=Dict()
    myinputs = load_inputs(mysetup_local,inpath)

    if mysetup["ModelH2"] == 1
      myinputs = load_h2_inputs(myinputs, mysetup_local, inpath)
    end

    if mysetup["ClusterSubPeriodResults"] == 1
      myinputs = load_subperiod_results(myinputs, mysetup_local, inpath)
    end

    if v println() end

    #Copy Original Parameter Scale Variable
    parameter_scale_org = mysetup["ParameterScale"]
    #Copy setup from set-up local. Set-up local contains some H2 setup inputs, except for correct parameter scale
    mysetup = copy(mysetup_local)
    #Overwrites paramater scale
    mysetup["ParameterScale"] = parameter_scale_org 

    return mysetup, myinputs
end
