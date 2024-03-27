

@doc raw"""
    h2_storage_asymmetric(EP::Model, inputs::Dict)

Sets up variables and constraints specific to hydrogen storage resources with asymmetric charge and discharge capacities.

For storage technologies with asymmetric charge and discharge capacities (all $s \in \mathcal{S}^{asym}$), charge rate $x_{s,z,t}^{\textrm{H,CHA}}$, is constrained by the total installed charge capacity $y_{s,z}^{\textrm{H,STO,CHA}}$, as follows:

```math
\begin{equation*}
    0 \leq x_{s,z,t}^{\textrm{H,CHA}} \leq y_{s,z}^{\textrm{H,STO,CHA}} \quad \forall s \in \mathcal{S}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
"""
function h2_storage_asymmetric(EP::Model, inputs::Dict)
    # Set up additional variables, constraints, and expressions associated with storage resources with asymmetric charge & discharge capacity
    # STOR = 2 corresponds to storage with distinct power and energy capacity decisions and distinct charge and discharge power capacity decisions/ratings

    println("H2 Storage Resources with Asmymetric Charge/Discharge Capacity Module")

    T = inputs["T"]::Int     # Number of time steps (hours)

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
