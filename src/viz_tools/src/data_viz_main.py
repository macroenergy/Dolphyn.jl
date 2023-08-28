import numpy as np
import pandas as pd

from data_wrangling.data_wrangling_long import electricity_analysis, h2_analysis
from viz.create_viz import create_viz_dir, create_stacked_bar_plot

def run_data_viz_single_run(dir):
    elec_viz_df = electricity_analysis(dir)
    h2_viz_df = h2_analysis(dir)

    viz_path = create_viz_dir(dir)

    create_stacked_bar_plot(df = elec_viz_df,
                            target_type = "electricity_capacity_MW",
                            save_path = viz_path,
                            fig_name = "elec_capacity")
    
    create_stacked_bar_plot(df = h2_viz_df,
                            target_type = "h2_capacity_tonne_hr",
                            save_path = viz_path,
                            fig_name = "h2_capacity")



    return None
