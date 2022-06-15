function h2_storage_asymmetric(EP::Model, inputs::Dict)
    # Set up additional variables, constraints, and expressions associated with storage resources with asymmetric charge & discharge capacity
    # STOR = 2 corresponds to storage with distinct power and energy capacity decisions and distinct charge and discharge power capacity decisions/ratings

    println("H2 Storage Resources with Asmymetric Charge/Discharge Capacity Module")

    T = inputs["T"]     # Number of time steps (hours)

    H2_STOR_ASYMMETRIC = inputs["H2_STOR_ASYMMETRIC"]

    ### Constraints ###

    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    # Maximum charging rate must be less than charge power rating
    @constraint(
        EP,
        [y in H2_STOR_ASYMMETRIC, t in 1:T],
        EP[:vH2_CHARGE_STOR][y, t] <= EP[:eTotalH2CapCharge][y]
    )

    return EP
end
