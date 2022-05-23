function h2_storage_symmetric(EP::Model, inputs::Dict)
    # Set up additional variables, constraints, and expressions associated with hydrogen storage resources with symmetric charge & discharge capacity
    # STOR = 1 corresponds to storage with distinct power and energy capacity decisions but symmetric charge/discharge power ratings

    println("H2 Storage Resources with Symmetric Charge/Discharge Capacity Module")

    T = inputs["T"]

    H2_STOR_SYMMETRIC = inputs["H2_STOR_SYMMETRIC"]

    ### Constraints ###

    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    @constraints(
        EP,
        begin
            # Maximum charging rate must be less than symmetric power rating
            [y in H2_STOR_SYMMETRIC, t in 1:T], EP[:vH2_CHARGE_STOR][y,t] <= EP[:eH2GenTotalCap][y] * inputs["pH2_Max"][y,t]
        end
    )

    return EP
end