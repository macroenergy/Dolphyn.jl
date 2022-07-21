"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
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

@doc raw"""
    load_network_data(path::AbstractString, setup::Dict, inputs::Dict)

Function for reading input parameters related to the electricity transmission network
"""
function load_network_data(path::AbstractString, setup::Dict, inputs::Dict)

    # Network zones inputs and Network topology inputs
    network_var = DataFrame(CSV.File(joinpath(path, "Network.csv"), header=true), copycols=true)

    # Number of zones in the network
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    # Filter lines which links zones not modelled
    network_var = filter(row -> ((row.StartZone in Zones) || (row.EndZone in Zones)), network_var)

    # Number of lines in the network
    inputs["L"] = size(collect(skipmissing(network_var[!, :Network_Lines])), 1)
    L = inputs["L"]

    # Topology of the network source-sink matrix
    Network_map = zeros(L, Z)
    for l in 1:L
        z_start = parse(Int32, network_var[!, :StartZone][l][2:end])
        z_end = parse(Int32, network_var[!, :EndZone][l][2:end])
        Network_map[l, z_start] = 1
        Network_map[l, z_end] = -1
    end

    inputs["pNet_Map"] = Network_map

    # Transmission capacity of the network (in MW)
    if setup["ParameterScale"] == 1  # Parameter scaling turned on - adjust values of subset of parameter values to GW
        inputs["pTrans_Max"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Max_Flow_MW])))/ModelScalingFactor  # convert to GW
    else # no scaling
        inputs["pTrans_Max"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Max_Flow_MW])))
    end

    if setup["Trans_Loss_Segments"] == 1 ##Aaron Schwartz Please check
        # Line percentage Loss - valid for case when modeling losses as a fixed percent of absolute value of power flows
        inputs["pPercent_Loss"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Loss_Percentage])))
    elseif setup["Trans_Loss_Segments"] >= 2
        # Transmission line voltage (in kV)
        inputs["kV"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Voltage_kV])))
        # Transmission line resistance (in Ohms) - Used when modeling quadratic transmission losses
        inputs["Ohms"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Resistance_ohms])))
    end

    # Maximum possible flow after reinforcement for use in linear segments of piecewise approximation
    inputs["pTrans_Max_Possible"] = zeros(Float64, L)
        
    if setup["NetworkExpansion"] == 1
        if setup["ParameterScale"] == 1  # Parameter scaling turned on - adjust values of subset of parameter values
            # Read between zone network reinforcement costs per peak MW of capacity added
            inputs["pC_Line_Reinforcement"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Reinforcement_Cost_per_MWyr])))/ModelScalingFactor # convert to million $/GW/yr with objective function in millions
            # Maximum reinforcement allowed in MW
            #NOTE: values <0 indicate no expansion possible
            inputs["pMax_Line_Reinforcement"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Max_Reinforcement_MW])))/ModelScalingFactor # convert to GW
        else
            # Read between zone network reinforcement costs per peak MW of capacity added
            inputs["pC_Line_Reinforcement"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Reinforcement_Cost_per_MWyr])))
            # Maximum reinforcement allowed in MW
            #NOTE: values <0 indicate no expansion possible
            inputs["pMax_Line_Reinforcement"] = convert(Array{Float64}, collect(skipmissing(network_var[!,:Line_Max_Reinforcement_MW])))
        end
        for l in 1:L
            if inputs["pMax_Line_Reinforcement"][l] > 0
                inputs["pTrans_Max_Possible"][l] = inputs["pTrans_Max"][l] + inputs["pMax_Line_Reinforcement"][l]
            else
                inputs["pTrans_Max_Possible"][l] = inputs["pTrans_Max"][l]
            end
        end
    else
        inputs["pTrans_Max_Possible"] = inputs["pTrans_Max"]
    end

    # Transmission line (between zone) loss coefficient (resistance/voltage^2)
    inputs["pTrans_Loss_Coef"] = zeros(Float64, L)
    for l in 1:L
        # For cases with only one segment
        if setup["Trans_Loss_Segments"] == 1
            inputs["pTrans_Loss_Coef"][l] = inputs["pPercent_Loss"][l]
        elseif setup["Trans_Loss_Segments"] >= 2
            # If zones are connected, loss coefficient is R/V^2 where R is resistance in Ohms and V is voltage in Volts
            if setup["ParameterScale"] == 1  # Parameter scaling turned on - adjust values of subset of parameter values
                inputs["pTrans_Loss_Coef"][l] = (inputs["Ohms"][l]/10^6)/(inputs["kV"][l]/10^3)^2 *ModelScalingFactor # 1/GW ***
            else
                inputs["pTrans_Loss_Coef"][l] = (inputs["Ohms"][l]/10^6)/(inputs["kV"][l]/10^3)^2 # 1/MW
            end
        end
    end

    ## Sets and indices for transmission losses and expansion
    inputs["TRANS_LOSS_SEGS"] = setup["Trans_Loss_Segments"] # Number of segments used in piecewise linear approximations quadratic loss functions
    inputs["LOSS_LINES"] = findall(inputs["pTrans_Loss_Coef"].!=0) # Lines for which loss coefficients apply (are non-zero);

    if setup["NetworkExpansion"] == 1
        # Network lines and zones that are expandable have non-negative maximum reinforcement inputs
        inputs["EXPANSION_LINES"] = findall(inputs["pMax_Line_Reinforcement"].>=0)
        inputs["NO_EXPANSION_LINES"] = findall(inputs["pMax_Line_Reinforcement"].<0)
    end

    println("Network.csv Successfully Read!")

    return inputs, network_var
end
