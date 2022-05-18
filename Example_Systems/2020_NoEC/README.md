# 2020_NOEC

**2020_NOEC** is a power model for the EU for the year 2020. It contains a power model with hourly resolution, contains zones representing Belgium, Germany, Denmark, France, Great Britain, the Netherlands, Sweden, and Norway. The represented resources include nuclear, coal, hydro, oil,, PHS, natural gas, solar PV, and wind. It does not allow for expansion, and is meant for baseline model validation.

To run the model, first navigate to the example directory at `DOLPHYN-dev/Example_Systems/2020_NOEC`:

`cd("Example_Systems/2020_NOEC")`

Next, ensure that your settings in `global_model_settings.yml` and `GenX_settings.yml` are correct. The default settings use the solver Gurobi (`Solver: Gurobi`), time domain reduced input data (`TimeDomainReduction: 1`). Other optional policies include minimum capacity requirements, a capacity reserve margin, and more. The CO2_cap.csv is not utilized in this case.

Once the settings are confirmed, run the model with the `Run.jl` script in the example directory:

`include("Run.jl")`

Once the model has completed, results will write to the `Results` directory.
