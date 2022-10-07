function syn_fuels_storage_symmetric(EP::Model, inputs::Dict)
    # Set up additional variables, constraints, and expressions associated with hydrogen storage resources with symmetric charge & discharge capacity
    # STOR = 1 corresponds to storage with distinct power and energy capacity decisions but symmetric charge/discharge power ratings

    println("Synthesis Fuels Storage Resources with Symmetric Charge/Discharge Capacity Module")

    T = inputs["T"]

    SYN_STOR_SYMMETRIC = inputs["SYN_STOR_SYMMETRIC"]

    ### Constraints ###

    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    @constraints(
        EP,
        begin
            # Maximum charging rate must be less than symmetric power rating
            [y in SYN_STOR_SYMMETRIC, t in 1:T], EP[:vSYN_CHARGE_STOR][y,t] <= EP[:eSYNGenTotalCap][y] * inputs["pSyn_Max"][y,t]
        end
    )

    return EP
end
