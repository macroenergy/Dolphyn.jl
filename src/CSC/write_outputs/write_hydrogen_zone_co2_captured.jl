function write_hydrogen_zone_co2_captured(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfH2Gen = inputs["dfH2Gen"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Carbon balance for each zone
	dfHydrogenZoneCapturedCO2Balance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 1)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["CO2 Captured"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			if setup["ParameterScale"]==1
	     		dfTemp1[t+rowoffset,1]= sum(value.(EP[:eHydrogen_CO2_captured_per_plant_per_time][dfH2Gen[(dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))*ModelScalingFactor
			else
				dfTemp1[t+rowoffset,1]= sum(value.(EP[:eHydrogen_CO2_captured_per_plant_per_time][dfH2Gen[(dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))
			end
	   	end

		if z==1
			dfHydrogenZoneCapturedCO2Balance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfHydrogenZoneCapturedCO2Balance = hcat(dfHydrogenZoneCapturedCO2Balance, dfTemp1)
		end
	end
	for c in 2:size(dfHydrogenZoneCapturedCO2Balance,2)
		dfHydrogenZoneCapturedCO2Balance[rowoffset,c]=sum(inputs["omega"].*dfHydrogenZoneCapturedCO2Balance[(rowoffset+1):size(dfHydrogenZoneCapturedCO2Balance,1),c])
	end
	dfHydrogenZoneCapturedCO2Balance = DataFrame(dfHydrogenZoneCapturedCO2Balance, :auto)
	CSV.write(string(path,sep,"Hydrogen_zone_co2_captured.csv"), dfHydrogenZoneCapturedCO2Balance, writeheader=false)
end
