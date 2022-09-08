function write_power_zone_co2_captured(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfGen = inputs["dfGen"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Carbon balance for each zone
	dfPowerZoneCapturedCO2Balance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 1)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["CO2 Captured"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			if setup["ParameterScale"]==1
	     		dfTemp1[t+rowoffset,1]= sum(value.(EP[:ePower_CO2_captured_per_plant_per_time][dfGen[(dfGen[!,:Zone].==z),:][!,:R_ID],t]))*ModelScalingFactor
			else
				dfTemp1[t+rowoffset,1]= sum(value.(EP[:ePower_CO2_captured_per_plant_per_time][dfGen[(dfGen[!,:Zone].==z),:][!,:R_ID],t]))
			end
	   	end

		if z==1
			dfPowerZoneCapturedCO2Balance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfPowerZoneCapturedCO2Balance = hcat(dfPowerZoneCapturedCO2Balance, dfTemp1)
		end
	end
	for c in 2:size(dfPowerZoneCapturedCO2Balance,2)
		dfPowerZoneCapturedCO2Balance[rowoffset,c]=sum(inputs["omega"].*dfPowerZoneCapturedCO2Balance[(rowoffset+1):size(dfPowerZoneCapturedCO2Balance,1),c])
	end
	dfPowerZoneCapturedCO2Balance = DataFrame(dfPowerZoneCapturedCO2Balance, :auto)
	CSV.write(string(path,sep,"Power_zone_co2_captured.csv"), dfPowerZoneCapturedCO2Balance, writeheader=false)
end
