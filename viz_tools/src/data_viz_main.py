import numpy as np

from data_wrangling.data_wrangling_long import electricity_analysis, h2_analysis
from viz.create_viz import create_viz_dir, create_stacked_bar_plot

def run_data_viz_single_run(dir):
    elec_viz_df = electricity_analysis(dir)
    h2_viz_df = h2_analysis(dir)

    viz_path = create_viz_dir(dir)

    print(viz_path)

    create_stacked_bar_plot(df = elec_viz_df,
                            target_type = "electricity_capacity_MW",
                            save_path = viz_path,
                            fig_name = "elec_capacity")

    print(elec_viz_df)
    print(h2_viz_df)

    return None

run_data_viz_single_run("/Users/youssefshaker/Dropbox (MIT)/Mobility_center_2021_projects/Liquid_Fuels/Input Construction/Demand/2023_Jan Non Trans Demand/Jul_13_Scenarios_v2/S1_Jul_13_2040_90_40EC_Base_SF_0.2_co2_0.4electro_opt_co2stor_baseline_sf_0.0")