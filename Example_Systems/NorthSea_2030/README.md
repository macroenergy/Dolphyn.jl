# NorthSea 2030

**NorthSea 2030** is a combined power and hydrogen model for the EU for the year 2030. It contains a power model with hourly resolution, contains zones representing Belgium, Germany, Denmark, France, Great Britain, the Netherlands, Sweden, and Norway. The represented resources include nuclear, coal, hydro, oil, PHS, natural gas, solar PV, lithium-ion batteries, and wind. On the hydrogen side, resources such as fuel cells, electrolyzers, SMRs, SMRs w CCS, and H2 CCGTs are included. The demand for the model includes significant non-transportation electrification, as well as hydrogen demand resulting from transportation decarbonization. The model also includes a CO2 constraint representing 30% of 2015 power sector CO2 emissions applied to the hydrogen and power sector jointly.

To run the model, first navigate to the example directory at `Example_Systems/NorthSea_2030`:

`cd("Example_Systems/NorthSea_2030")`

Next, ensure that your settings in `global_model_settings.yml`, `GenX_settings.yml`, `hsc_settings` are correct. The default settings use the solver Gurobi (`Solver: HiGHS`), time domain reduced input data (`TimeDomainReduction: 1`). Other optional policies include minimum capacity requirements, a capacity reserve margin, and more. The CO2_cap.csv is not utilized in this case.

Once the settings are confirmed, run the model with the `Run.jl` script in the example directory:

`include("Run.jl")`

Once the model has completed, results will write to the `Results` directory. You can compare these results to example results (using the default settings provided here) in `Results_Example`, by running:

`include("Check_results.jl")`

If the example has run successfully, all of the files except `status.csv` should be identical.
