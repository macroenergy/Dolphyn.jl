import pandas as pd
import matplotlib.pyplot as plt
import os


def create_viz_dir(dir):
    figures_path = dir + "/Figures"

    if not os.path.exists(figures_path):
        os.makedirs(figures_path)
        print(f"Created directory: {figures_path}")
    else:
        print(f"Directory already exists: {figures_path}")

    return figures_path


def create_stacked_bar_plot(df, target_type, save_path, fig_name):
    # Filter the DataFrame by the specified Type
    filtered_df = df[df['Type'] == target_type]
    
    # Pivot the filtered DataFrame
    pivoted_df = filtered_df.pivot(index='Zone', columns='Resource', values='Value')
    
    # Calculate the figure size based on the number of zones
    num_zones = len(pivoted_df.index)
    figsize = (num_zones * 1.5, 6)  # Adjust the multiplication factor as needed
    
    # Plot the stacked bar plot with the dynamic figure size
    ax = pivoted_df.plot(kind='bar', stacked=True, figsize=figsize)
    
    title_dict = {'elec_capacity': 'Power Capacity by Zone',
                  'elec_generation': 'Power Generation by Zone',
                  'h2_capacity' : 'H2 Generation Capacity by Zone',
                  'h2_generation' : 'H2 Generation by Zone'}
    
    y_axis_dict = {'elec_capacity': 'Power Capacity (MW)',
                  'elec_generation': 'Power Generation  (MWh)',
                  'h2_capacity' : 'H2 Generation Capacity by Zone (Tonne/hr)',
                  'h2_generation' : 'H2 Generation by Zone (Tonne)'}
    
    # Add labels and title
    plt.xlabel('Zone')
    plt.ylabel(y_axis_dict[fig_name])

    title_dict = {'elec_capacity': 'Power Generation Capacity by Zone',
                  'elec_generation': 'Power Generation by Zone',
                  'h2_capacity' : 'H2 Generation Capacity by Zone',
                  'h2_generation' : 'H2 Generation by Zone'}

    plt.title(title_dict[fig_name])
    
    # Show the legend
    plt.legend(title='Resource')
    
    plt.savefig(save_path + "/" + fig_name + ".jpeg", bbox_inches='tight')