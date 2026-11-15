function write_Ethylene_Existing_Plants(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	###########################################################################################
	## Ethylene balance for each zone
	dfEthyleneBalance = Array{Any}
	rowoffset=3
	dfTemp1_Ethylene = Array{Any}(nothing, T+rowoffset, 5)
	dfTemp1_Ethylene[1,1:size(dfTemp1_Ethylene,2)] = ["TSC: H2","TSC: H2","TSC: H2","TSC: H2","TSC: H2"]
	dfTemp1_Ethylene[2,1:size(dfTemp1_Ethylene,2)] = ["4","5","6","7","8"]
    
	for t in 1:T
        for dum1 in 1:5
            dfTemp1_Ethylene[t+rowoffset,dum1] = 0
        end
        #=
		dfTemp1_Ethylene[t+rowoffset,2] = 0
		dfTemp1_Ethylene[t+rowoffset,3] = 0
		dfTemp1_Ethylene[t+rowoffset,4] = 0
		dfTemp1_Ethylene[t+rowoffset,5] = 0
		dfTemp1_Ethylene[t+rowoffset,6] = 0t
		dfTemp1_Ethylene[t+rowoffset,7] = 0
		dfTemp1_Ethylene[t+rowoffset,8] = 0
		dfTemp1_Ethylene[t+rowoffset,9] = 0
		dfTemp1_Ethylene[t+rowoffset,10] = 0
		dfTemp1_Ethylene[t+rowoffset,11] = 0
		dfTemp1_Ethylene[t+rowoffset,12] = 0
		dfTemp1_Ethylene[t+rowoffset,13] = 0
		dfTemp1_Ethylene[t+rowoffset,14] = 0
		dfTemp1_Ethylene[t+rowoffset,15] = 0
		dfTemp1_Ethylene[t+rowoffset,16] = 0
        dfTemp1_Ethylene[t+rowoffset,17] = 0
		dfTemp1_Ethylene[t+rowoffset,18] = 0
		dfTemp1_Ethylene[t+rowoffset,19] = 0
		dfTemp1_Ethylene[t+rowoffset,20] = 0
		dfTemp1_Ethylene[t+rowoffset,21] = 0
		dfTemp1_Ethylene[t+rowoffset,22] = 0
		dfTemp1_Ethylene[t+rowoffset,23] = 0
		dfTemp1_Ethylene[t+rowoffset,24] = 0
		dfTemp1_Ethylene[t+rowoffset,25] = 0
		dfTemp1_Ethylene[t+rowoffset,26] = 0
		dfTemp1_Ethylene[t+rowoffset,27] = 0
		dfTemp1_Ethylene[t+rowoffset,28] = 0
		dfTemp1_Ethylene[t+rowoffset,29] = 0
		dfTemp1_Ethylene[t+rowoffset,30] = 0
		dfTemp1_Ethylene[t+rowoffset,31] = 0
		dfTemp1_Ethylene[t+rowoffset,32] = 0
        dfTemp1_Ethylene[t+rowoffset,33] = 0
		dfTemp1_Ethylene[t+rowoffset,34] = 0
		dfTemp1_Ethylene[t+rowoffset,35] = 0
        # eEthylene_Prod_Plant[k,t]
        value.(EP[:eEthylene_Prod_Plant][4,t])
        =#

		if setup["ModelEthyleneProduction"] == 1
            for dum2 in 1:5
                dfTemp1_Ethylene[t+rowoffset,dum2] = value.(EP[:eEthylene_Prod_Plant][dum2,t])
            end
        end
        #=

			dfTemp1_Ethylene[t+rowoffset,1] = value.(EP[:eEthylene_Prod_Plant][4,t])
			dfTemp1_Ethylene[t+rowoffset,2] = value.(EP[:eEthylene_Prod_Plant][4,t]) # value.(EP[:eEthylene_Prod_RES][14*z-12,t]) 
			dfTemp1_Ethylene[t+rowoffset,3] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-11,t]) 
			dfTemp1_Ethylene[t+rowoffset,4] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-10,t]) 
			dfTemp1_Ethylene[t+rowoffset,5] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-9,t]) 
			dfTemp1_Ethylene[t+rowoffset,6] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-8,t]) 
			dfTemp1_Ethylene[t+rowoffset,7] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-7,t]) 
			dfTemp1_Ethylene[t+rowoffset,8] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-6,t]) 
			dfTemp1_Ethylene[t+rowoffset,9] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-5,t]) 
			dfTemp1_Ethylene[t+rowoffset,10] = value.(EP[:eEthylene_Prod_Plant][4,t]) #value.(EP[:eEthylene_Prod_RES][14*z-4,t]) 
			dfTemp1_Ethylene[t+rowoffset,11] = 5 #value.(EP[:eEthylene_Prod_RES][14*z-3,t]) 
			dfTemp1_Ethylene[t+rowoffset,12] = 10 #value.(EP[:eEthylene_Prod_RES][14*z-2,t]) 
			dfTemp1_Ethylene[t+rowoffset,13] = 8 #value.(EP[:eEthylene_Prod_RES][14*z-1,t]) 
			dfTemp1_Ethylene[t+rowoffset,14] = 6 #value.(EP[:eEthylene_Prod_RES][14*z,t]) 
            dfTemp1_Ethylene[t+rowoffset,15] = 6 
            dfTemp1_Ethylene[t+rowoffset,16] = 8
            dfTemp1_Ethylene[t+rowoffset,17] = 1
            dfTemp1_Ethylene[t+rowoffset,18] = 3
            dfTemp1_Ethylene[t+rowoffset,19] = 4
            dfTemp1_Ethylene[t+rowoffset,20] = 0
            dfTemp1_Ethylene[t+rowoffset,21] = 5
            dfTemp1_Ethylene[t+rowoffset,22] = 0
            dfTemp1_Ethylene[t+rowoffset,23] = 45
            dfTemp1_Ethylene[t+rowoffset,24] = 8
            dfTemp1_Ethylene[t+rowoffset,25] = 4
            dfTemp1_Ethylene[t+rowoffset,26] = 1
            dfTemp1_Ethylene[t+rowoffset,27] = 5
            dfTemp1_Ethylene[t+rowoffset,28] = 0
            dfTemp1_Ethylene[t+rowoffset,29] = 7
            dfTemp1_Ethylene[t+rowoffset,30] = 4
            dfTemp1_Ethylene[t+rowoffset,31] = 56
            dfTemp1_Ethylene[t+rowoffset,32] = 8
            dfTemp1_Ethylene[t+rowoffset,33] = 7
            dfTemp1_Ethylene[t+rowoffset,34] = 32
            dfTemp1_Ethylene[t+rowoffset,35] = 4
		end
        =#
    end
    dfEthyleneBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Ethylene)
	#dfEthyleneBalance = hcat(dfEthyleneBalance, dfTemp1_Ethylene)
    
    # println(inputs["omega"])


	for c in 2:size(dfEthyleneBalance,2)
        # println(dfEthyleneBalance[(rowoffset+1):size(dfEthyleneBalance,1), c])
        cleaned_values = replace(dfEthyleneBalance[(rowoffset+1):size(dfEthyleneBalance,1), c], nothing => 0.0)
        dfEthyleneBalance[rowoffset, c] = sum(inputs["omega"] .* cleaned_values)
		# dfEthyleneBalance[rowoffset,c]=sum(inputs["omega"].*dfEthyleneBalance[(rowoffset+1):size(dfEthyleneBalance,1),c])		
	end


	dfEthyleneBalance = DataFrame(dfEthyleneBalance, :auto)
	
	CSV.write(string(path,sep,"Ethylene_Plant_Balance.csv"), dfEthyleneBalance, writeheader=false)

end
