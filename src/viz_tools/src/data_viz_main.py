import numpy as np
import pandas as pd
import os

from data_wrangling.data_wrangling_long import electricity_analysis, h2_analysis, latest_result_finder
from viz.create_viz import create_viz_dir, create_stacked_bar_plot

def run_data_viz_single_run(dir):
    
    viz_path = create_viz_dir(dir)

    ###Power Sector Data
    
    #Power Sector Data Wranlging
    elec_viz_df = electricity_analysis(dir)

    print("Visualizing Power Data")

    #Power Sector Data Visualization
    create_stacked_bar_plot(df = elec_viz_df,
                            target_type = "electricity_capacity_MW",
                            save_path = viz_path,
                            fig_name = "elec_capacity")
    
    create_stacked_bar_plot(df = elec_viz_df,
                            target_type = "electricity_generation_MWh",
                            save_path = viz_path,
                            fig_name = "elec_generation")
    
    ###Hydrogen Sector Data
    results_dir = latest_result_finder(dir)

    #Checking if path exists
    if os.path.exists(results_dir + "/Results_HSC"):

        print("Visualizing H2 Data")

        #H2 Data Wrangling
        h2_viz_df = h2_analysis(dir)

        #H2 Data Viz
        create_stacked_bar_plot(df = h2_viz_df,
                                target_type = "h2_capacity_tonne_hr",
                                save_path = viz_path,
                                fig_name = "h2_capacity")
        
        create_stacked_bar_plot(df = h2_viz_df,
                                target_type = "h2_generation_tonne",
                                save_path = viz_path,
                                fig_name = "h2_generation")



    return None
