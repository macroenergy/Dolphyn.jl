# Small New England: One Zone

**SmallNewEngland** is set of a simplified power and hydrogen models. It is condensed for easy comprehension and quick testing of different components of the DOLPHYN. **SmallNewEngland/OneZone** is our most basic model, a one-year example with hourly resolution containing only one zone representing New England. The power resources in the model are natural gas, solar PV, wind, and lithium-ion battery storage with no initial capacity. The hydrogen resources include electrolyzers, SMRs, SMRs with CCS, and above ground storage.

To run the model, first navigate to the example directory at `DOLPHYN-dev/Example_Systems/SmallNewEngland/OneZone`:

`cd("Example_Systems/SmallNewEngland/OneZone")`
   
Next, ensure that your settings in `global_model_settings.yml`, `GenX_settings.yml`, `hsc_settings` are correct. The default settings use the solver Gurobi (`Solver: Gurobi`), time domain reduced input data (`TimeDomainReduction: 1`). Other optional policies include minimum capacity requirements, a capacity reserve margin, CO2 cap and and more.

Once the settings are confirmed, run the model with the `Run.jl` script in the example directory:

`include("Run.jl")`

Once the model has completed, results will write to the `Results` directory. You can compare these results to example results (using the default settings provided here) in `Results_Example`, by running:

`include("Check_results.jl")`

If the example has run successfully, all of the files except `status.csv` should be identical