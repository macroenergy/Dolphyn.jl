function h2_demand(EP::Model, inputs::Dict)

Z = inputs["Z"] #Set of zones
FLEX_H2 = inputs["FLEX_H2"] # Set of flexible demand resources"
#Define start subperiods and interior subperiods
START_SUBPERIODS = inputs["START_SUBPERIODS"]
INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

#YS I recreated this, because I was not sure if the way Guannan coded it was entirley consistent. Are you okay with these categories
#YS Would be cool if we can make this dynamic so that the categories can change depending on the project

#Net Hydrogen Demand
@variable(EP, vH2D[z=1:Z, t = 1:T] >= 0 )

#Variables expressing hydrogen demand by sector
#Industrial Hydrogen Demand
@variable(EP, vH2I[z=1:Z, t = 1:T] >= 0 )
#Transportation Hydrogen Demand
@variable(EP, vH2T[z=1:Z, t = 1:T] >= 0 )
#Other Hydrogen Demand
@variable(EP, vH2O[z=1:Z, t = 1:T] >= 0 )

#YS What's the difference between unmet and curtailed hydrogen demand?
#Unmet Hydrogen Demand
@variable(EP, vH2DUnmet[z=1:Z, t = 1:T] >= 0 )
#Curtailed Hydrogen Demand
@variable(EP, vH2Curtail[z=1:Z, t = 1:T] >= 0 )

#Hydrogen DR Variables
@variable(EP, vH2DRDelayBal[d=1:FLEX_H2, t = 1:T] >= 0 )
@variable(EP, vH2DRDelay[d=1:FLEX_H2, t = 1:T] >= 0 )
@variable(EP, vH2DRServe[d=1:FLEX_H2, t = 1:T] >= 0 )

## Balance Expressions ##

#Objective Function Expressions
#Cost of unmet H2 demand
#YS Need to deing unmetprice
@expression(EP, cTotalH2Unmet, sum(weights[t] *vH2DUnmet[z,t]* H2UnmetPrice for z=1:Z,t=1:T))
# Add term to objective function expression
EP[:eObj] += cTotalH2Unmet

# H2 balance
#Total H2 Demand across all time periods and zones
#YS Am I using weights correctly here?
#YS does it make a different if hydrogen demand is an expressiono or variable + constraint
@expression(EP, eTotalH2Demand, sum(weights[t] * (vH2I[z,t] + vH2T[z,t] + vH2O[z,t]) for z=1:Z,t = 1:T))

#H2 demand with time period and zone granularity
@expression(EP, eH2Demand[t=1:T, z=1:Z], vH2I[z,t] + vH2T[z,t] + vH2O[z,t])

#Constraints

#Hydrogen Demand = Industrial Hydrogen Demand + Transportation Hydrogen Demand + Other hydrogen Demand - Unment Hydrogen demand + Curtailed Hydrogen Demand
#YS Need to filter DR delay and DR serve by zone
@constraint(EP, vH2D[z,t] == H2I[z,t] + vH2T[z,t] + vH2O[z,t] - vH2DUnmet[z,t] + vH2Curtail[z,t] + sum(vDRServe[d,t] - vDRDelay[d,t] for d=1:FLEX_H2))

#H2 DR Constraints
#YS should this only be applied to transportation dmenad
@constraint(EP, vH2DRDelay[d,z,t] <= inputs_H2["dfH2DR"]["DRMaxRatio"][d,z] * H2T[z,t])

#Linking first time period to the last time period
@constraint(EP, [t in START_SUBPERIODS, d in FLEX_H2],
vH2DRDelayBal[d, t] == vH2DRDelayBal[d, t + hours_per_subperiod - 1] - inputs_H2["dfH2DR"]["DREfficiency"][d] * vDRServe[d,t] + vDRDelay[d,t])

@constraint(EP, [t in INTERIOR_SUBPERIODS, d in FLEX_H2],
vDRDelayBal[d, t] == vDRDelayBal[d,t-1] - inputs_H2["dfH2DR"]["DREfficiency"][d,z] * (vDRServe[d,t]) + (vDRDelay[d,t]))


#YS Questions 
#

# Require deferred demands to be satisfied within the specified time delay
if (Tw-inputs_H2["DR_par"]["DRMaxDuration"][d,z]) < h < Tw
    # Constraint wraps around to first hours of time series
        @constraint(HY, sum(vDRServe[d,z,e] for e=(t+1):tw_max)+sum(vDRServe[d,z,e] for e=tw_min:(tw_min-1+inputs_H2["DR_par"]["DRMaxDuration"][d,z]-(Tw-h))) >= vDRDelayBal[d,z,t])
elseif h == Tw
    # Constraint wraps around to first hours of time series
        @constraint(HY, sum(vDRServe[d,z,e] for e=tw_min:(tw_min-1+inputs_H2["DR_par"]["DRMaxDuration"][d,z])) >= vDRDelayBal[d,z,t])
else
    # Constraint looks back over last n hours, where n = inputs["Max_DSM_delay"][y]
        @constraint(HY, sum(vDRServe[d,z,e] for e=(t+1):(t+inputs_H2["DR_par"]["DRMaxDuration"][d,z])) >= vDRDelayBal[d,z,t])
end #END if
				




end
