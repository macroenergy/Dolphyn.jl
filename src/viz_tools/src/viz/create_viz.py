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

# Dictionary of colors for the technologies
elec_colors = {
    'natural_gas': '#808080',  # grey
    'natural_gas_w_CCS': '#d3d3d3',  # light grey
    'hydroelectric': '#0000FF',  # blue
    'coal': '#000000',  # black
    'solar': '#ffdb58',  # gold
    'wind': '#008000',  # green
    'nuclear': '#9400d3',  # violet
    'battery': '#ff4500',  # orange
    'phs': '#4682b4',  # steel blue
    'oil': '#8b4513',  # saddle brown
    'biomass': '#228b22',  # forest green
    'H2': '#89CFF0'  # baby blue
}

h2_colors = {
    'smr': '#2f4f4f',  # dark grey
    'atr': '#800000',  # bordeaux
    'electrolyzer': '#00ffff',  # aqua blue
    'h2_storage': '#ffc0cb'  # pink
}




# Define a list of 15 distinct fallback colors in case there are technologies that are not caught by the categorizing dictionaries
fallback_colors = [
    '#e6194B', '#3cb44b', '#ffe119', '#0082c8', '#f58231',
    '#911eb4', '#46f0f0', '#f032e6', '#d2f53c', '#fabebe',
    '#008080', '#e6beff', '#aa6e28', '#fffac8', '#800000'
]

# Assigns preset colors to stacked barplots
def get_resource_colors(resources, tech_type):
    if tech_type.startswith('elec'):
        color_map = elec_colors
    if tech_type.startswith('h2'):
        color_map = h2_colors

    colors = []
    fallback_index = 0
    for resource in resources:
        if resource in color_map:
            colors.append(color_map[resource])
        else:
            # Use a color from the fallback list if the resource is not found in the dictionary
            colors.append(fallback_colors[fallback_index])
            # Optional: Print a warning or log it
            print(f"Warning: Color not defined for '{resource}'. Using a fallback color.")
            
            # Move to the next fallback color, cycle back if we run out
            fallback_index = (fallback_index + 1) % len(fallback_colors)

    return colors




def create_stacked_bar_plot(df, target_type, save_path, fig_name):
    # Filter the DataFrame by the specified Type
    filtered_df = df[df['Type'] == target_type]
    
    # Pivot the filtered DataFrame
    pivoted_df = filtered_df.pivot(index='Zone', columns='Resource', values='Value')
    
    # Get colors for the resources in the pivoted dataframe
    resource_colors = get_resource_colors(pivoted_df.columns, fig_name)
    
    # Calculate the figure size based on the number of zones
    num_zones = len(pivoted_df.index)
    figsize = (num_zones * 1.5, 6)  # Adjust the multiplication factor as needed
    
    # Plot the stacked bar plot with the dynamic figure size
    ax = pivoted_df.plot(kind='bar', stacked=True, figsize=figsize, color=resource_colors)

    
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