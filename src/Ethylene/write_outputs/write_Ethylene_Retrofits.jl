function write_Ethylene_Retrofits(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	###########################################################################################
	## Ethylene balance for each zone
	dfEthyleneBalance = Array{Any}
	rowoffset=3
	dfTemp1_Ethylene = Array{Any}(nothing, T+rowoffset, 30)
	dfTemp1_Ethylene[1,1:size(dfTemp1_Ethylene,2)] = ["TSC+H2in:CH4","TSC+H2in:CH4","TSC+H2in:CH4","TSC+H2in:CH4","TSC+H2in:CH4","TSC","TSC","TSC","TSC","TSC","TSC+CC90","TSC+CC90","TSC+CC90","TSC+CC90","TSC+CC90","TSC+CC90: H2","TSC+CC90: H2","TSC+CC90: H2","TSC+CC90: H2","TSC+CC90: H2","TSC+H2in","TSC+H2in","TSC+H2in","TSC+H2in","TSC+H2in","ESC","ESC","ESC","ESC","ESC"]
	dfTemp1_Ethylene[2,1:size(dfTemp1_Ethylene,2)] = ["4","5","6","7","8","4","5","6","7","8","4","5","6","7","8","4","5","6","7","8","4","5","6","7","8","4","5","6","7","8"]
    
	for t in 1:T
        for dum1 in 1:30
            dfTemp1_Ethylene[t+rowoffset,dum1] = 0
        end

		if setup["ModelEthyleneRetrofitting"] == 1
            for dum2 in 1:30
                dfTemp1_Ethylene[t+rowoffset,dum2] = value.(EP[:eEthylene_Prod_RetrofitRES][dum2,t])
            end
			#dfTemp1_Ethylene[t+rowoffset,4] = 4
			#dfTemp1_Ethylene[t+rowoffset,29] = 4
        end

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
	
	CSV.write(string(path,sep,"Ethylene_Retrofit_Balance.csv"), dfEthyleneBalance, writeheader=false)

end
