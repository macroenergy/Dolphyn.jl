"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	write_power_outputs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Function for the entry-point for writing the different output files. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_power_outputs(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	# Create directory if it does not exist
    if !isdir(path)
        mkdir(path)
    end
	
	elapsed_time_costs = @elapsed write_costs(path, setup, inputs, EP)
	println("Time elapsed for writing costs is")
	println(elapsed_time_costs)
	dfCap = write_capacity(path, setup, inputs, EP)
	dfPower = write_power(path, setup, inputs, EP)
	dfCharge = write_charge(path, setup, inputs, EP)
	elapsed_time_storage = @elapsed write_storage(path, inputs, setup, EP)
	println("Time elapsed for writing storage is")
	println(elapsed_time_storage)
	dfCurtailment = write_curtailment(path, setup, inputs, EP)
	elapsed_time_nse = @elapsed write_nse(path, setup, inputs, EP)
	println("Time elapsed for writing nse is")
	println(elapsed_time_nse)
	elapsed_time_power_balance = @elapsed write_power_balance(path, setup, inputs, EP)
	println("Time elapsed for writing power balance is")
	println(elapsed_time_power_balance)
	if inputs["Z"] > 1
		elapsed_time_flows = @elapsed write_transmission_flows(path, setup, inputs, EP)
		println("Time elapsed for writing transmission flows is")
		println(elapsed_time_flows)
		elapsed_time_losses = @elapsed write_transmission_losses(path, setup, inputs, EP)
		println("Time elapsed for writing transmission losses is")
		println(elapsed_time_losses)
		if setup["NetworkExpansion"] == 1
			elapsed_time_expansion = @elapsed write_nw_expansion(path, setup, inputs, EP)
			println("Time elapsed for writing network expansion is")
			println(elapsed_time_expansion)
		end
	end
	
	if setup["CO2Cap"] == 1
		elapsed_time_emissions = @elapsed write_emissions(path, setup, inputs, EP)
		println("Time elapsed for writing emissions is")
		println(elapsed_time_emissions)
	end

	if has_duals(EP) == 1
		elapsed_time_reliability = @elapsed write_reliability(path, setup, inputs, EP)
		println("Time elapsed for writing reliability is")
		println(elapsed_time_reliability)
		elapsed_time_stordual = @elapsed write_storagedual(path, setup, inputs, EP)
		println("Time elapsed for writing storage duals is")
		println(elapsed_time_stordual)
	end

	if setup["UCommit"] >= 1
		elapsed_time_commit = @elapsed write_commit(path, setup, inputs, EP)
		println("Time elapsed for writing commitment is")
		println(elapsed_time_commit)
		elapsed_time_start = @elapsed write_start(path, setup, inputs, EP)
		println("Time elapsed for writing startup is")
		println(elapsed_time_start)
		elapsed_time_shutdown = @elapsed write_shutdown(path, setup, inputs, EP)
		println("Time elapsed for writing shutdown is")
		println(elapsed_time_shutdown)
		if setup["Reserves"] == 1
			elapsed_time_reg = @elapsed write_reg(path, setup, inputs, EP)
			println("Time elapsed for writing regulation is")
			println(elapsed_time_reg)
			elapsed_time_rsv = @elapsed write_rsv(path, setup, inputs, EP)
			println("Time elapsed for writing reserves is")
			println(elapsed_time_rsv)
		end
	end

	# Output additional variables related inter-period energy transfer via storage
	if setup["OperationWrapping"] == 1 && !isempty(inputs["STOR_LONG_DURATION"])
		elapsed_time_lds_init = @elapsed write_opwrap_lds_stor_init(path, setup, inputs, EP)
		println("Time elapsed for writing lds init is")
		println(elapsed_time_lds_init)
		elapsed_time_lds_dstor = @elapsed write_opwrap_lds_dstor(path, setup, inputs, EP)
		println("Time elapsed for writing lds dstor is")
		println(elapsed_time_lds_dstor)
	end

	dfPrice = DataFrame()
	dfEnergyRevenue = DataFrame()
	dfChargingcost = DataFrame()
	dfSubRevenue = DataFrame()
	dfRegSubRevenue = DataFrame()
	if has_duals(EP) == 1
		dfPrice = write_price(path, setup, inputs, EP)
		dfEnergyRevenue = write_energy_revenue(path, setup, inputs, EP, dfPower, dfPrice, dfCharge)
		dfChargingcost = write_charging_cost(path, setup, inputs, dfCharge, dfPrice, dfPower)
		dfSubRevenue, dfRegSubRevenue = write_subsidy_revenue(path, setup, inputs, EP)
	end

	dfESR = DataFrame()
	dfESRRev = DataFrame()
	if setup["EnergyShareRequirement"] == 1 && has_duals(EP) == 1
		dfESR = write_esr_prices(path, setup, inputs, setup)
		dfESRRev = write_esr_revenue(path, setup, inputs, dfPower, dfESR)
	end
	dfResMar = DataFrame()
	dfResRevenue = DataFrame()
	if setup["CapacityReserveMargin"] == 1 && has_duals(EP) == 1
		dfResMar = write_reserve_margin(path, setup, inputs, EP)
		elapsed_time_rsv_margin = @elapsed write_reserve_margin_w(path, setup, inputs, EP)
		println("Time elapsed for writing reserve margin is")
		println(elapsed_time_rsv_margin)
		dfResRevenue = write_reserve_margin_revenue(path, setup, inputs, dfPower, dfCharge, dfResMar, dfCap)
		elapsed_time_cap_value = @elapsed write_capacity_value(path, setup, inputs, dfPower, dfCharge, dfResMar, dfCap)
		println("Time elapsed for writing capacity value is")
		println(elapsed_time_cap_value)
	end

	elapsed_time_net_rev = @elapsed write_net_revenue(path, setup, inputs, EP, dfCap, dfESRRev, dfResRevenue, dfChargingcost, dfPower, dfEnergyRevenue, dfSubRevenue, dfRegSubRevenue)
	println("Time elapsed for writing net revenue is")
	println(elapsed_time_net_rev)

	println("Wrote power outputs to $path")

end # END output()
