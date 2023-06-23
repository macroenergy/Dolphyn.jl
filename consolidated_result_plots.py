#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib.ticker import ScalarFormatter
from matplotlib.ticker import FuncFormatter
import seaborn as sns
import numpy as np


# In[2]:


def save_and_show_plot(fig, filename, directory='plots_folder'):
    # Make sure the directory exists, if not, create it
    os.makedirs(directory, exist_ok=True)
    fig.savefig(f"{directory}/{filename}.png", bbox_inches='tight', dpi=300)
    plt.close(fig)  # Close the figure


# In[3]:


zones = [
    "MIS_INKY",
    "PJM_WMAC",
    "PJM_SMAC",
    "PJM_West",
    "PJM_AP",
    "PJM_COMD",
    "PJM_ATSI",
    "PJM_Dom",
    "PJM_PENE",
    "S_C_KY",
    "PJM_EMAC",
    "MIS_LMI"
]


generation_resources = [
    "conventional_hydroelectric",
    "conventional_steam_coal",
    "natural_gas_fired_combined_cycle",
    "natural_gas_fired_combustion_turbine",
    "solar_photovoltaic",
    "onshore_wind_turbine",
    "small_hydroelectric",
    "hydroelectric_pumped_storage",
    "nuclear",
    "naturalgas_ccccsavgcf_conservative",
    "naturalgas_ccavgcf_moderate",
    "naturalgas_ctavgcf_moderate",
    "landbasedwind",
    "battery",
    "utilitypv",
    "offshorewind",
    "CCGT-H2",
    "OCGT-H2",
]

# Mapping resources to categories
generation_resource_categories = {
    "conventional_hydroelectric": "Hydro",
    "conventional_steam_coal": "Coal",
    "natural_gas_fired_combined_cycle": "Existing_natural_gas",
    "natural_gas_fired_combustion_turbine": "Existing_natural_gas",
    "naturalgas_ccavgcf_moderate": "New_natural_gas",
    "naturalgas_ctavgcf_moderate": "New_natural_gas",
    "naturalgas_ccccsavgcf_conservative": "Natural_gas_with_CCS",
    "solar_photovoltaic": "Solar",
    "onshore_wind_turbine": "Wind",
    "small_hydroelectric": "Hydro",
    "hydroelectric_pumped_storage": "Hydro",
    "nuclear": "Nuclear",
    "landbasedwind": "Wind",
    "battery": "Battery",
    "utilitypv": "Solar",
    "offshorewind": "Wind",
    "CCGT-H2": "H2",
    "OCGT-H2": "H2",
}

H2_resource_categories = {
    "Electrolyzer": "Electrolyzer",
    "Large_SMR_wCCS_96pct": "Large_SMR_wCCS_96pct",
    "Large_SMR": "Large_SMR",
    "ATR_wCCS_94pct": "ATR_wCCS_94pct",
    "Salt_cavern_storage": "Salt_cavern_storage",
}

scenarios_no_caverns = ["NoCap_PJM_with_MI_no_cavern",
        "PJM_with_MI_no_caverns_70_red", 
        "PJM_with_MI_no_caverns_85_red",
        "PJM_with_MI_no_caverns_90_red", 
        "PJM_with_MI_no_caverns_95_red",
        "PJM_with_MI_no_caverns_no_emissions"]

scenarios_with_caverns = ["NoCap_PJM_with_MI_with_cavern",
        "PJM_with_MI_with_caverns_70_red", 
        "PJM_with_MI_with_caverns_85_red",
        "PJM_with_MI_with_caverns_90_red", 
        "PJM_with_MI_with_caverns_95_red",
        "PJM_with_MI_with_caverns_no_emissions"]


colors_generation = {
    'H2': 'skyblue', 
    'Battery': 'orange', 
    'Coal': 'black', 
    'Hydro': 'blue',
    'Existing_natural_gas': 'grey',
    'Natural_gas_with_CCS': 'lightgrey',
    'New_natural_gas': 'maroon',
    'Nuclear': 'purple',
    'Solar': '#FFD700',
    'Wind': 'green'
}


H2_colors = {
    "Electrolyzer": "#7B68EE",  # Medium Slate Blue 
    "Large_SMR_wCCS_96pct": "#808000", # Olive
    "Large_SMR": "darkgrey",  # Dark Grey
    "ATR_wCCS_94pct": "#008080",  # Teal
    "Salt_cavern_storage": "#BA55D3",  # Medium Orchid
    "Above_ground_storage": "saddlebrown"
}

costs_colors = {
    'cTotal': 'blue',
    'cFix_Thermal': 'firebrick',
    'cFix_VRE': 'orange',
    'cFix_Trans_VRE': 'gold',
    'cFix_Must_Run': 'yellowgreen',
    'cFix_Hydro': 'lightgreen',
    'cFix_Stor': 'darkgreen',
    'cVar': 'lightblue',
    'cNSE': 'dodgerblue',
    'cStart': 'navy',
    'cUnmetRsv': 'mediumpurple',
    'cNetworkExp': 'plum',
    'cH2Fix_Gen': 'violet',
    'cH2Fix_G2P': 'magenta',
    'cH2Fix_Stor': 'crimson',
    'cH2Fix_Truck': 'palevioletred',
    'cH2Var': 'pink',
    'cH2NSE': 'peachpuff',
    'cH2Start': 'sandybrown',
    'cH2NetworkExp': 'chocolate',
    'cDACFix': 'sienna',
    'cDACVar': 'maroon',
    'cCO2Comp': 'coral',
    'cCO2Start': 'tomato',
    'cCO2Stor': 'salmon',
    'cCO2NetworkExp': 'darkorange',
    'cBiorefineryFix': 'khaki',
    'cBiorefineryVar': 'yellow',
    'cHerb': 'springgreen',
    'cWood': 'mediumseagreen',
    'cSFFix': 'teal',
    'cSFVar': 'turquoise',
    'cSFByProdRev': 'cyan',
    'CSFConvDieselFuelCost': 'deepskyblue',
    'CSFConvJetfuelFuelCost': 'blue',
    'CSFConvGasolineFuelCost': 'slateblue',
    'cPower_Total': 'blueviolet',
    'cHSC_Total': 'purple',
    'cCSC_Total': 'indigo',
    'cBiorefinery': 'pink',
    'cBioresources': 'lightcoral',
    'cSF_Prod': 'lightsalmon',
    'cConv_Fuels': 'darkred',
    'cHydro_Must_Run': 'darkgrey',
}

rename_dict = {
    'NoCap_PJM_with_MI_no_cavern': 'No Emission Cap\n without Salt Caverns',
    'PJM_with_MI_no_caverns_70_red': '70% Emission Reduction Cap\n without Salt Caverns',
    'PJM_with_MI_no_caverns_85_red': '85% Emission Reduction Cap\n without Salt Caverns',
    'PJM_with_MI_no_caverns_90_red': '90% Emission Reduction Cap\n without Salt Caverns',
    'PJM_with_MI_no_caverns_95_red': '95% Emission Reduction Cap\n without Salt Caverns',
    'PJM_with_MI_no_caverns_no_emissions': '100% Emission Reduction Cap\n without Salt Caverns',
    'NoCap_PJM_with_MI_with_cavern': 'No Emission Cap\n with Salt Caverns',
    'PJM_with_MI_with_caverns_70_red': '70% Emission Reduction Cap\n with Salt Caverns',
    'PJM_with_MI_with_caverns_85_red': '85% Emission Reduction Cap\n with Salt Caverns',
    'PJM_with_MI_with_caverns_90_red': '90% Emission Reduction Cap\n with Salt Caverns',
    'PJM_with_MI_with_caverns_95_red': '95% Emission Reduction Cap\n with Salt Caverns',
    'PJM_with_MI_with_caverns_no_emissions': '100% Emission Reduction Cap\n with Salt Caverns'
}

scenarios = scenarios_no_caverns


# In[4]:


def identify_tech_type(df, resources):
    tech_types = []
    for name in df['Resource']:
        for zone in zones:
            if name.startswith(zone):
                cleaned_string = name[len(zone) + 1:]
                break
            else:
                cleaned_string = name
        
        for r in resources:
            if cleaned_string.startswith(r):
                result_string = resources[r]
                break
            else:
                result_string = cleaned_string
        tech_types.append(result_string)

    df['Tech_Type'] = tech_types
    
    # Aggregate other columns based on the identified technology types
    aggregated_df = df.groupby('Tech_Type').sum().reset_index()
    
    return aggregated_df

#aggregated_df = identify_tech_type(df_capacity_w_H2G2P)
#aggregated_df


# In[5]:


import os

def find_latest_result_folder(path):
    result_folders = [folder for folder in os.listdir(path) if folder.startswith("Results")]
    if not result_folders:
        raise ValueError("No 'Results' folders found.")
        
    result_numbers = [int(folder.split("_")[-1]) if "_" in folder else 0 for folder in result_folders]
    latest_result = max(result_numbers)
    
    if latest_result == 0:
        return "Results"
    else:
        return f"Results_{latest_result}"

def latest_result_finder(path):
    latest_result_path = find_latest_result_folder(path)
    path = path + '/' + latest_result_path + '/'
    #path_capacity = path + '/' + latest_result_path + '/capacity_w_H2G2P.csv'
    #path_power = path + '/' + latest_result_path + '/power_w_H2G2P.csv'
    #print(path_capacity)
    #print(path_power)
    #return(path_capacity, path_power)
    return(path)
    
def open_results_file(file_name, scenario):
    scenario = '/Users/lesarmstrong/Documents/GitHub/DOLPHYN_May2023/Example_Systems/PJM_with_MI/' + scenario
    path = latest_result_finder(scenario)
    if file_name.startswith('HSC'):
        path = path + 'Results_HSC/'
    path = path + file_name
    #print(path)
    df = pd.read_csv(path)
    return(df)


df_capacity_nocavern_nocap = open_results_file(file_name='capacity_w_H2G2P.csv', scenario='NoCap_PJM_with_MI_no_cavern')    


# In[6]:


def capacity_w_H2G2p_analysis(scenario, generation_resource_categories=generation_resource_categories):
    df = open_results_file('capacity_w_H2G2P.csv', scenario)
    aggregated_df = identify_tech_type(df, generation_resource_categories)
    return(aggregated_df)

def power_w_H2G2p_analysis(scenario, generation_resource_categories=generation_resource_categories):
    df = open_results_file('power_w_H2G2P.csv', scenario)
    df = df.T 

    # Step 1: Convert the index into a column
    df_with_index_as_column = df.reset_index()

    # Step 2: Rename the new column
    df_with_index_as_column = df_with_index_as_column.rename(columns={'index': 'your_new_column_name'})

    # Step 3: Convert the first row into column indices
    df_with_index_as_column.columns = df_with_index_as_column.iloc[0]

    # Step 4: Drop the first row
    df_with_index_as_column = df_with_index_as_column.drop(df_with_index_as_column.index[0])

    # Step 5: Reset the index
    df_with_index_as_column = df_with_index_as_column.reset_index(drop=True)
    df = df_with_index_as_column[['Resource', 'AnnualSum']]
    df = df.iloc[:-1]
    df = identify_tech_type(df, generation_resource_categories)
    return(df)

def generation_difference_analysis(scenario, generation_resource_categories=generation_resource_categories):
    df = open_results_file('capacity_w_H2G2P.csv', scenario)
    df = identify_tech_type(df, generation_resource_categories)
    df = df[['Tech_Type', 'StartCap', 'EndCap']]
    #df = df[df['Tech_Type'] != 'Total']
    df['Cap_difference'] = df['EndCap'] - df['StartCap'] 
    return(df)


#EndEnergyCap: Total installed energy capacity of each resource type in each zone; applies only to H2 storage tech. [Tonnes]
def h2_capacity_analysis(scenario,H2_resource_categories=H2_resource_categories ):
    #scenario = 'PJM_with_MI_no_caverns_70_red'
    df = open_results_file('HSC_generation_storage_capacity.csv', scenario)
    #aggregated_df = identify_tech_type(df, generation_resource_categories)
    aggregated_df = identify_tech_type(df, H2_resource_categories)
    return(aggregated_df)


## GET COSTS ##
def get_total(df, cost_name):
    total = df.loc[df['Costs'] == cost_name, 'Total'].values[0]
    return total

def cost_analysis(scenario, cost_name='cTotal'):
    df = open_results_file('costs_system.csv', scenario)
    cost = get_total(df, cost_name)
    return(cost)
   
    
def max_row_sum_for_yaxis(df):
    index_of_max_sum_row = df.clip(lower=0).sum(axis=1).idxmax()
    max_sum_row = df.loc[index_of_max_sum_row].clip(lower=0).sum()
    #print(df.loc[index_of_max_sum_row].sum())
    #print(max_sum_row)
    return(max_sum_row)

def min_row_sum_for_yaxis(df):
    #print(df)
    index_of_min_sum_row = df.sum(axis=1).idxmin()
    #print(index_of_min_sum_row)
    min_sum_row = df.loc[index_of_min_sum_row].sum()
    #print(df.loc[index_of_min_sum_row].sum())
    #print(min_sum_row)
    
    min_sum_row = df.min().min()
    #print(min_sum_row)
    return(min_sum_row)


# In[7]:




legend_title='Generation Type'
title = 'TITLE'
y_label = 'Y_LABEL'
'''
# If "units" = 1 => Generation (GW/GWh) | If "units" = 2 => H2 mass (metric tons) | If units = 3 => Costs $
def plot_stacked_barchart(df_main, title=title, legend_title=legend_title, y_label=y_label, units=1, retirement=False):
    
    if units == 1:
        # MW --> GW
        df_main = df_main.div(1000)
        colors = colors_generation
    if units == 2:
        colors = H2_colors
    if units == 3:
        colors = costs_colors
        
    #df_main = df_main[df_main.sum().sort_values(ascending=False).index]
    if retirement == False:
        # Create the bar chart and get the Axes object
        ax = df_main.plot(kind='bar', stacked=True, color=[colors[i] for i in df_main.columns], figsize=(16, 8))

        # With caverns generation retirement
        # With caverns generation retirement
    if retirement == True:
        # Split the dataframe into two: one for positive values and another for negative values
        df_pos = df_main.clip(lower=0)  # This replaces negative values with 0
        df_neg = df_main.clip(upper=0)  # This replaces positive values with 0

        # Create the bar chart for positive values and get the Axes object
        ax = df_pos.plot(kind='bar', stacked=True, color=[colors[i] for i in df_pos.columns], figsize=(16, 8))

        # Stack the negative values below by continuing the plot with negative dataframe
        ax = df_neg.plot(kind='bar', stacked=True, color=[colors[i] for i in df_neg.columns], ax=ax, figsize=(16, 8))

    # Set the y-axis label
    ax.set_ylabel(y_label)
    # Set y-axis limits. max_row_sum just finds the largest y axis value to be able to adjust well
    # Adjust the upper limit to 3% above the highest value
    min_value = min_row_sum_for_yaxis(df_main)
    print('MIN VALUE:')
    print(min_value)
    max_value = max_row_sum_for_yaxis(df_main)

    # If the minimum value is less than 0, we scale it down by 3%. 
    # Otherwise, we set it to 0 because we don't want to show negative area if there's no negative data.
    min_limit = min_value * 1.03 if min_value < 0 else 0

    # We always scale the max value up by 3% to ensure the highest data point is not on the edge of the plot.
    max_limit = max_value * 1.03

    ax.set_ylim([min_limit, max_limit])

    ax.axhline(0, color='black', linewidth=1)    
    # Set the title of the plot
    ax.set_title(title)

    # Set the legend title
    ax.legend(title=legend_title)

    # Change the x-axis ticks
    ax.set_xticks(range(len(df_main.index)))
    ax.set_xticklabels(df_main.index, rotation=45)
    
    # Set y-axis formatter to ScalarFormatter and disable scientific notation
    formatter = ScalarFormatter(useMathText=True)
    formatter.set_scientific(False)
    ax.yaxis.set_major_formatter(formatter)


    # Show the plot
    plt.show()
'''


# In[8]:


def plot_stacked_barchart(df_main, title=title, legend_title=legend_title, y_label=y_label, units=1, retirement=False, sort_values=False, legend_custom=False):
    
    
    H2_colors = {
        "Electrolyzer": "#7B68EE",  # Medium Slate Blue 
        "Large_SMR_wCCS_96pct": "#808000", # Olive
        "Large_SMR": "darkgrey",  # Dark Grey
        "ATR_wCCS_94pct": "#008080",  # Teal
        "Salt_cavern_storage": "#BA55D3",  # Medium Orchid
        "Above_ground_storage": "saddlebrown"
   }

    
    if units == 1:
        # MW --> GW
        df_main = df_main.div(1000)
        colors = colors_generation
    if units == 2:
        colors = H2_colors
    if units == 3:
        colors = costs_colors


    if sort_values == True:
        # Calculate the sum of each row (i.e., the total height of each bar)
        row_sums = df_main.sum(axis=1)

        # Sort the DataFrame by the row sums
        df_main = df_main.loc[row_sums.sort_values().index]
        
        
    # Create a new figure and axes
    fig, ax = plt.subplots(figsize=(16, 8))


    
    # With retirement
    #if retirement == True:
    if df_main.select_dtypes(include=[np.number]).min().min() < -1:
        # Split the dataframe into two: one for positive values and another for negative values
        df_pos = df_main.clip(lower=0)  # This replaces negative values with 0
        df_neg = df_main.clip(upper=0)  # This replaces positive values with 0

        # Create the bar chart for positive values
        ax = df_pos.plot(kind='bar', stacked=True, color=[colors[i] for i in df_pos.columns], ax=ax)

        # Stack the negative values below by creating a bar chart with negative dataframe
        ax = df_neg.plot(kind='bar', stacked=True, color=[colors[i] for i in df_neg.columns], ax=ax)

    else:
        ax = df_main.plot(kind='bar', stacked=True, color=[colors[i] for i in df_main.columns], ax=ax)
        
        
    df_main.rename(index=rename_dict, inplace=True)
   # Create a custom legend
    handles, labels = ax.get_legend_handles_labels()
    # Create a dictionary to eliminate duplicate entries
    legend_dict = dict(zip(labels, handles))
    ax.legend(legend_dict.values(), legend_dict.keys(), title=legend_title)

    # Set the y-axis label
    ax.set_ylabel(y_label)
    # Add grid lines
    ax.set_axisbelow(True)
    ax.grid(True, linestyle='--', which='major', color='gray', alpha=.3, axis='y')

    # Adjust y-axis limits
    max_value = max_row_sum_for_yaxis(df_main)
    max_limit = max_value * 1.1
    
    min_value = min_row_sum_for_yaxis(df_main)
    min_limit = min_value * 1.5 if min_value < 0 else 0

    ax.set_ylim([min_limit, max_limit])

    ax.axhline(0, color='black', linewidth=1)
    ax.set_title(title)
    ax.set_xticks(range(len(df_main.index)))
    ax.set_xticklabels(df_main.index, rotation=45)
    
    
    # Set y-axis formatter to ScalarFormatter and disable scientific notation
    formatter = ScalarFormatter(useMathText=True)
    formatter.set_scientific(False)
    ax.yaxis.set_major_formatter(formatter)


    plt.show()

    #save_and_show_plot(fig, title)
    


# In[9]:


#title = 'Installed Capacity (MW) Across Different Decarbonization Scenarios without Salt Cavern H2 Storage'
def generation_capacity_barchart(scenarios=scenarios, title=title, y_label=y_label):
    df_main = pd.DataFrame()

    for scenario in scenarios:

        df = capacity_w_H2G2p_analysis(scenario)
        df = df[['Tech_Type', 'EndCap']]
        # Remove the 'Total' row
        df = df[df['Tech_Type'] != 'Total']
        df = df.rename(columns={'EndCap': scenario})

        # Transpose the dataframe
        df = df.set_index('Tech_Type').T

        df_main = df_main.append(df, ignore_index=False)
    
    df_main = df_main[df_main.sum().sort_values(ascending=False).index]
    
    plot_stacked_barchart(df_main, title=title, y_label=y_label)
    return(df_main)

def generation_capacity_retirement_barchart(scenarios=scenarios, title=title, y_label=y_label):
    
    df_main = pd.DataFrame()
    for scenario in scenarios:

        df = generation_difference_analysis(scenario)
        df = df.drop(['StartCap', 'EndCap'], axis=1)
        df = df[df['Tech_Type'] != 'Total']
        
        df = df.rename(columns={'Cap_difference': scenario})
        # Transpose the dataframe
        df = df.set_index('Tech_Type').T

        df_main = df_main.append(df, ignore_index=False)
        df_main = df_main[df_main.sum().sort_values(ascending=False).index]
    plot_stacked_barchart(df_main, title=title, y_label=y_label, retirement=True)
    #print(df_main)
    return(df_main)

def generation_power_barchart(scenarios=scenarios, title=title, y_label=y_label):
    df_main = pd.DataFrame()

    for scenario in scenarios:
        df = capacity_w_H2G2p_analysis(scenario)
        df = df[['Tech_Type', 'EndCap']]
        # Remove the 'Total' row
        df = df[df['Tech_Type'] != 'Total']
        df = df.rename(columns={'EndCap': scenario})

        # Transpose the dataframe    
        df = df.set_index('Tech_Type').T
        #df.plot(kind='bar', stacked=True, label=scenario)
        
        df_main = df_main.append(df, ignore_index=False)
    
    # Sort ascending values
    df_main = df_main[df_main.sum().sort_values(ascending=False).index]
    plot_stacked_barchart(df_main, title=title, y_label=y_label)
    return(df_main)
 
def h2_storage_capacity_barchart(scenarios, title=title, y_label=y_label, units=2):
    df_main = pd.DataFrame()

    for scenario in scenarios:
        df = h2_capacity_analysis(scenario)
        
        df = df[['Tech_Type', 'EndEnergyCap']]
        df = df[df['Tech_Type'] != 'Total']
        df = df.rename(columns={'EndEnergyCap': scenario})
        # removes rows with 0 (non-storage tech)
        df = df.loc[df[scenario] != 0]

        # Transpose the dataframe    
        df = df.set_index('Tech_Type').T
        #df.plot(kind='bar', stacked=True, label=scenario)
        
        df_main = df_main.append(df, ignore_index=False)
    
    
    # Sort ascending values
    df_main = df_main[df_main.sum().sort_values(ascending=False).index]
    plot_stacked_barchart(df_main, title=title, y_label=y_label, units=units)
    return(df_main)
    
def h2_capacity_generation(scenarios, title=title, y_label=y_label, units=2):
    df_main = pd.DataFrame()

    for scenario in scenarios:
        df = h2_capacity_analysis(scenario)

        df = df[['Tech_Type', 'EndCap']]
        df = df[df['Tech_Type'] != 'Total']
        df = df.rename(columns={'EndCap': scenario})

        df = df[df['Tech_Type'] != 'Above_ground_storage']
        df = df[df['Tech_Type'] != 'Salt_cavern_storage']
        
        # Transpose the dataframe    
        df = df.set_index('Tech_Type').T
        #df.plot(kind='bar', stacked=True, label=scenario)
        
        df_main = df_main.append(df, ignore_index=False)
    #print(df_main)
    plot_stacked_barchart(df_main, title=title, y_label=y_label, units=units)
    return(df_main)

def costs_breakdown(scenarios, title=title, y_label=y_label, units=3):

    df_main = pd.DataFrame()
    for scenario in scenarios:

        df = open_results_file('costs_system.csv', scenario)
        # Set 'Costs' as the index
        df.set_index('Costs', inplace=True)

        # Keep only the 'Total' column
        df = df[['Total']]
        #df = df[df['Total'] != 0]
        df = df.rename(columns={'Total': scenario})
        df = df.drop('cTotal', errors='ignore')
        df = df.drop('cPower_Total', errors='ignore')
        df = df.drop('cHSC_Total', errors='ignore')
        df = df.drop('cCSC_Total', errors='ignore')
        # Join dataframes
        if df_main.empty:
            df_main = df
        else:
            df_main = df_main.join(df, how='outer')

    # Remove rows where all values are NaN
    df_main = df_main.dropna(how='all')
    # Remove 'cTotal' row
    df_main = df_main.drop('cTotal', errors='ignore')
    df_main = df_main.T

    plot_stacked_barchart(df_main, title=title, y_label=y_label, units=units)
    return(df_main)
    
def costs_scenarios(scenarios, title=title, y_label=y_label, units=3):
    
    df_main = pd.DataFrame()
    for scenario in scenarios:

        df = open_results_file('costs_system.csv', scenario)
        # Set 'Costs' as the index
        df.set_index('Costs', inplace=True)

        # Keep only the 'Total' column and 'cTotal' row
        df = df.loc[['cTotal'], ['Total']]
        df = df.rename(columns={'Total': scenario})
        # Join dataframes
        if df_main.empty:
            df_main = df
        else:
            df_main = df_main.join(df, how='outer')

        # Find the scenario that contains 'NoCap'
    base_scenario = df_main.columns[df_main.columns.str.contains('NoCap')][0]
            
    # Transpose the DataFrame so that the scenarios are the rows and costs are the columns
    df_main = df_main.T

    # Normalize the data with respect to the 'NoCap' scenario and convert to percentage increase
    df_main = (df_main / df_main.loc[base_scenario])

    plot_stacked_barchart(df_main, title=title, y_label=y_label, units=units)
    return(df_main)



#def costs_scenarios_comparison_caverns(scenario_no_cavern=scenario_no_caverns, scenario_with_cavern=scenario_with_caverns, units=3):
    
 #   costs_no_cavern_df = costs_scenarios(scenarios_no_caverns, units=3)
  #  costs_with_cavern_df = costs_scenarios(scenarios_with_caverns, units=3)
    
    
    
    


# In[45]:


# Without caverns
h2_pipe_cap_list_no_caverns = []
for scenario in scenarios_no_caverns:
    df = open_results_file('HSC_pipeline_expansion.csv', scenario)
    new_h2_pipeline_cap_total = df['New_Trans_Capacity'].sum()
    h2_pipe_cap_list_no_caverns.append(new_h2_pipeline_cap_total)

# With caverns
h2_pipe_cap_list_with_caverns = []
for scenario in scenarios_with_caverns:
    df = open_results_file('HSC_pipeline_expansion.csv', scenario)
    new_h2_pipeline_cap_total = df['New_Trans_Capacity'].sum()
    h2_pipe_cap_list_with_caverns.append(new_h2_pipeline_cap_total)

    
# Settings for the bars
bar_width = 0.35
opacity = 0.8

# Rename scenarios
scenarios_renamed = [rename_dict[s] for s in scenarios_no_caverns]

# Create an array with the position of each bar along the x-axis
r1 = np.arange(len(h2_pipe_cap_list_no_caverns))
r2 = [x + bar_width for x in r1]

plt.figure(figsize=(10, 6))

# Plot bars
plt.bar(r1, h2_pipe_cap_list_no_caverns, color='purple', width=bar_width, alpha=opacity, label='Without Salt Caverns')
plt.bar(r2, h2_pipe_cap_list_with_caverns, color='orange', width=bar_width, alpha=opacity, label='With Salt Caverns')

# Add labels, title, legend, etc
plt.xlabel('Scenarios')  
plt.ylabel('MT/hour')
plt.title('H2 Pipeline Capacity Comparison')
plt.xticks([r + bar_width / 2 for r in range(len(h2_pipe_cap_list_no_caverns))], scenarios_renamed, rotation=45)
plt.legend()

plt.show()


# In[44]:


rename_dict = {
    'NoCap_PJM_with_MI_no_cavern': 'No Emission Cap',
    'PJM_with_MI_no_caverns_70_red': '70% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_85_red': '85% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_90_red': '90% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_95_red': '95% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_no_emissions': '100% Emission Reduction Cap'
}



h2_pipe_cap_list = []
for scenario in scenarios_no_caverns:
    df = open_results_file('HSC_pipeline_expansion.csv',scenario )
    new_h2_pipeline_cap_total = df['New_Trans_Capacity'].sum()
    h2_pipe_cap_list.append(new_h2_pipeline_cap_total)

# Rename scenarios
scenarios_renamed = [rename_dict[s] for s in scenarios]

plt.figure(figsize=(10,6))
plt.bar(scenarios_renamed, h2_pipe_cap_list, color='purple')
plt.xlabel('Scenarios')  
plt.ylabel('MT/hour')
plt.title('H2 Pipeline Capacity Without Salt Caverns')
plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
plt.show()


# In[43]:


rename_dict = {
    'NoCap_PJM_with_MI_no_cavern': 'No Emission Cap',
    'PJM_with_MI_no_caverns_70_red': '70% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_85_red': '85% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_90_red': '90% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_95_red': '95% Emission Reduction Cap',
    'PJM_with_MI_no_caverns_no_emissions': '100% Emission Reduction Cap'
}



h2_pipe_cap_list = []
for scenario in scenarios_with_caverns:
    df = open_results_file('HSC_pipeline_expansion.csv',scenario )
    new_h2_pipeline_cap_total = df['New_Trans_Capacity'].sum()
    h2_pipe_cap_list.append(new_h2_pipeline_cap_total)

# Rename scenarios
scenarios_renamed = [rename_dict[s] for s in scenarios]

plt.figure(figsize=(10,6))
plt.bar(scenarios_renamed, h2_pipe_cap_list, color='purple')
plt.xlabel('Scenarios')  
plt.ylabel('MT/hour')
plt.title('H2 Pipeline Capacity With Salt Caverns')
plt.xticks(rotation=45)  # Rotate x-axis labels for better visibility
plt.show()


# In[10]:


def compare_scenarios(scenarios_1, scenarios_2, operation, title=""):
    df_1 = operation(scenarios_1)
    df_2 = operation(scenarios_2)
    
    # Rename the indices of df_2 to match those of df_1
    df_2.index = df_2.index.str.replace("_with_cavern", "_no_cavern")
    
    missing_in_2 = df_1.index.difference(df_2.index)
    print("Scenarios present in 1 but missing in 2:", missing_in_2)

    missing_in_1 = df_2.index.difference(df_1.index)
    print("Scenarios present in 2 but missing in 1:", missing_in_1)
    
    assert (df_1.columns == df_2.columns).all(), "Tech_Types do not match."
    assert (df_1.index == df_2.index).all(), "Scenarios do not match."
    
    df_diff = df_2 - df_1
    
    df_diff = df_diff.dropna(how="all")
    
    plot_stacked_barchart(df_diff, title=title)
    return df_diff


# In[11]:


# No caverns generation retirement
title = 'Generation Capacity Expansion/Retirement without Salt Caverns(2035) [GW]'
y_label = 'Installed Generation Capacity [GW]'

generation_capacity_retirement_barchart(scenarios=scenarios_no_caverns, title=title, y_label=y_label)


# In[12]:


# With caverns generation retirement
title = 'Generation Capacity Expansion/Retirement with Salt Caverns (2035)[GW]'
y_label = 'Generation [GW]'
generation_capacity_retirement_barchart(scenarios=scenarios_with_caverns, title=title, y_label=y_label)


# In[13]:


# With caverns generation retirement
title = 'Generation Capacity Mix without Salt Caverns (2035)[GW]'
y_label = 'Generation [GW]'
generation_capacity_barchart(scenarios=scenarios_no_caverns, title=title, y_label=y_label)


# In[14]:


# With caverns generation retirement
title = 'Generation Capacity Mix with Salt Caverns (2035)[GW]'
y_label = 'Generation [GW]'
generation_capacity_barchart(scenarios=scenarios_with_caverns, title=title, y_label=y_label)


# In[15]:


# With caverns generation retirement
title = 'Generation Power Mix without Salt Caverns (2035)[GWh]'
y_label = 'Generation Power [GWh]'
generation_power_barchart(scenarios=scenarios_no_caverns, title=title, y_label=y_label)


# In[16]:


# With caverns generation retirement
title = 'Generation Power Mix with Salt Caverns (2035)[GWh]'
y_label = 'Generation Power [GWh]'
generation_power_barchart(scenarios=scenarios_with_caverns, title=title, y_label=y_label)


# In[17]:


# With caverns generation retirement
title = 'H2 Production Capacity Mix without Salt Caverns (2035)[MT]'
y_label = 'H2 Production Capacity [MT]'
h2_capacity_generation(scenarios=scenarios_no_caverns, title=title, y_label=y_label)


# In[18]:


# With caverns generation retirement
title = 'H2 Production Capacity Mix with Salt Caverns (2035)[MT]'
y_label = 'H2 Production Capacity [MT]'
h2_capacity_generation(scenarios=scenarios_with_caverns, title=title, y_label=y_label)


# In[19]:


# With caverns generation retirement
title = 'H2 Storage Capacity Mix with only Above Ground Storage (2035)[MT]'
y_label = 'H2 Storage Capacity [MT]'
h2_storage_capacity_barchart(scenarios=scenarios_no_caverns, title=title, y_label=y_label)


# In[20]:


# With caverns generation retirement
title = 'H2 Storage Capacity Mix with Salt Caverns (2035)[MT]'
y_label = 'H2 Storage Capacity [MT]'
h2_storage_capacity_barchart(scenarios=scenarios_with_caverns, title=title, y_label=y_label)


# In[21]:


# With caverns generation retirement
title = 'Costs Comparison Ratios without Salt Caverns - Base Case: No Emission Cap '
y_label = 'Normalized Cost'
costs_scenarios(scenarios=scenarios_no_caverns, title=title, y_label=y_label)


# In[22]:


# With caverns generation retirement
title = 'Costs Comparison Ratios with Salt Caverns - Base Case: No Emission Cap'
y_label = 'Normalized Cost'
costs_scenarios(scenarios=scenarios_no_caverns, title=title, y_label=y_label)


# In[23]:


def compare_scenarios(scenarios_no_caverns, scenarios_with_caverns, title=""):
    df_no_caverns = generation_capacity_barchart(scenarios_no_caverns)
    df_with_caverns = generation_capacity_barchart(scenarios_with_caverns)
    
    # Rename the indices of df_with_caverns to match those of df_no_caverns
    df_with_caverns.index = df_with_caverns.index.str.replace("_with_cavern", "_no_cavern")
    
    missing_in_with_caverns = df_no_caverns.index.difference(df_with_caverns.index)
    print("Scenarios present in no_caverns but missing in with_caverns:", missing_in_with_caverns)

    # Identify which scenarios are in df_with_caverns but not in df_no_caverns
    missing_in_no_caverns = df_with_caverns.index.difference(df_no_caverns.index)
    print("Scenarios present in with_caverns but missing in no_caverns:", missing_in_no_caverns)
    
    # Check that the indices (scenarios) and columns (Tech_Type) match between the two data sets
    assert (df_no_caverns.columns == df_with_caverns.columns).all(), "Tech_Types do not match."
    assert (df_no_caverns.index == df_with_caverns.index).all(), "Scenarios do not match."
    
    # Calculate the difference between the scenarios
    df_diff =  df_with_caverns - df_no_caverns
    
    # Remove rows where all values are NaN
    df_diff = df_diff.dropna(how="all")
    
    plot_stacked_barchart(df_diff, title=title)
    return df_diff



    
compare_scenarios(scenarios_no_caverns,scenarios_with_caverns)


# In[24]:



'''
df_no_caverns = generation_power_barchart(scenarios_no_caverns)
df_with_caverns = generation_power_barchart(scenarios_with_caverns)

# Rename the indices of df_with_caverns to match those of df_no_caverns
df_with_caverns.index = df_with_caverns.index.str.replace("_with_cavern", "_no_cavern")

missing_in_with_caverns = df_no_caverns.index.difference(df_with_caverns.index)
print("Scenarios present in no_caverns but missing in with_caverns:", missing_in_with_caverns)

# Identify which scenarios are in df_with_caverns but not in df_no_caverns
missing_in_no_caverns = df_with_caverns.index.difference(df_no_caverns.index)
print("Scenarios present in with_caverns but missing in no_caverns:", missing_in_no_caverns)

# Check that the indices (scenarios) and columns (Tech_Type) match between the two data sets
assert (df_no_caverns.columns == df_with_caverns.columns).all(), "Tech_Types do not match."
assert (df_no_caverns.index == df_with_caverns.index).all(), "Scenarios do not match."

# Calculate the difference between the scenarios
df_diff =  df_with_caverns - df_no_caverns

# Remove rows where all values are NaN
df_diff = df_diff.dropna(how="all")

plot_stacked_barchart(df_diff, title=title)
return df_diff
'''


# In[25]:


def compare_scenarios(scenarios_1, scenarios_2, operation, title="", y_label=""):
    
    df_1 = operation(scenarios_1, title="", y_label="")
    df_2 = operation(scenarios_2, title="", y_label="")
    
    # Rename the indices of df_2 to match those of df_1
    df_2.index = df_2.index.str.replace("_with_cavern", "_no_cavern")
    
    missing_in_2 = df_1.index.difference(df_2.index)
    print("Scenarios present in 1 but missing in 2:", missing_in_2)

    missing_in_1 = df_2.index.difference(df_1.index)
    print("Scenarios present in 2 but missing in 1:", missing_in_1)
    
    assert (df_1.columns == df_2.columns).all(), "Tech_Types do not match."
    assert (df_1.index == df_2.index).all(), "Scenarios do not match."
    
    df_diff = df_2 - df_1
    
    df_diff = df_diff.dropna(how="all")
    
    plot_stacked_barchart(df_diff, title=title, y_label=y_label)
    return df_diff



# In[26]:


title = "With Salt Cavern scenarios - Without Salt Cavern Scenarios Yearly Generation Mix Delta [GWh]"
y_label = "Generation [GWh]"

df_diff = compare_scenarios(scenarios_no_caverns, scenarios_with_caverns, generation_power_barchart, title=title, y_label=y_label)


# In[27]:


#title = "With Salt Cavern scenarios - Without Salt Cavern Scenarios Yearly H2 Production Mix Delta [MT]"
#y_label = "H2 Production [MT]"

#df_diff = compare_scenarios(scenarios_no_caverns, scenarios_with_caverns, h2_capacity_generation, title=title, y_label=y_label)


# In[28]:


#title = "With Salt Cavern scenarios - Without Salt Cavern Scenarios Yearly H2 Production Mix Delta [MT]"
#y_label = "H2 Production [MT]"

#df_diff = compare_scenarios(scenarios_no_caverns, scenarios_with_caverns, costs_scenarios, title=title, y_label=y_label)


# In[29]:


'''
def costs_scenarios(scenarios, title=title, y_label=y_label, units=3, sort_values=False):
    
    df_main = pd.DataFrame()
    for scenario in scenarios:

        df = open_results_file('costs_system.csv', scenario)
        # Set 'Costs' as the index
        df.set_index('Costs', inplace=True)

        # Keep only the 'Total' column and 'cTotal' row
        df = df.loc[['cTotal'], ['Total']]
        df = df.rename(columns={'Total': scenario})
        # Join dataframes
        if df_main.empty:
            df_main = df
        else:
            df_main = df_main.join(df, how='outer')

    # Find the scenario that contains 'NoCap' and 'no_cavern'
    base_scenario = df_main.columns[(df_main.columns.str.contains('NoCap')) & 
                                    (df_main.columns.str.contains('no_cavern'))][0]

    # Transpose the DataFrame so that the scenarios are the rows and costs are the columns
    df_main = df_main.T

    # Normalize the data with respect to the 'NoCap' and 'no_cavern' scenario and convert to percentage increase
    df_main = (df_main / df_main.loc[base_scenario])

    plot_stacked_barchart(df_main, title=title, y_label=y_label, units=units, sort_values=sort_values, legend_custom=True)
    return(df_main)
'''


# In[30]:


'''
def costs_scenarios(scenarios_with_caverns, scenarios_without_caverns, title=title, y_label=y_label, units=3, sort_values=False):

    df_main = pd.DataFrame()
    cavern_info = {} # Here's where we'll store the metadata

    base_scenario = [s for s in scenarios_without_caverns if 'NoCap' in s and 'no_cavern' in s][0]
    df_base_scenario = open_results_file('costs_system.csv', base_scenario)
    df_base_scenario.set_index('Costs', inplace=True)
    df_base_scenario = df_base_scenario.loc[['cTotal'], ['Total']]
    df_base_scenario = df_base_scenario.rename(columns={'Total': base_scenario})
    base_scenario_cost = df_base_scenario.iloc[0][0]
    
    for scenario in scenarios_without_caverns + scenarios_with_caverns:

        df = open_results_file('costs_system.csv', scenario)
        df.set_index('Costs', inplace=True)
        df = df.loc[['cTotal'], ['Total']]
        df = df.rename(columns={'Total': scenario})

        cavern_info[scenario] = 'with Caverns' if scenario in scenarios_with_caverns else 'without Caverns' # Update the metadata

        if df_main.empty:
            df_main = df
        else:
            df_main = df_main.join(df, how='outer')

    df_main = df_main.T
    df_main = df_main.astype(float) / base_scenario_cost
    print(df_main)
    # Keep a copy of the DataFrame for the plot
    df_plot = df_main.copy()
    df_plot['Cavern Info'] = df_plot.index.map(cavern_info) # Add the metadata back

    plot_stacked_barchart(df_plot, title=title, y_label=y_label, units=units, sort_values=sort_values, legend_custom=True)

    # Add the metadata to the original DataFrame for the return
    df_main['Cavern Info'] = df_main.index.map(cavern_info)

    return(df_main)
'''


# In[31]:


scenarios_without_caverns = scenarios_no_caverns

df_main = pd.DataFrame()
cavern_info = {} # Here's where we'll store the metadata

base_scenario = [s for s in scenarios_without_caverns if 'NoCap' in s and 'no_cavern' in s][0]
df_base_scenario = open_results_file('costs_system.csv', base_scenario)
df_base_scenario.set_index('Costs', inplace=True)
df_base_scenario = df_base_scenario.loc[['cTotal'], ['Total']]
df_base_scenario = df_base_scenario.rename(columns={'Total': base_scenario})
base_scenario_cost = df_base_scenario.iloc[0][0]

for scenario in scenarios_without_caverns + scenarios_with_caverns:

    df = open_results_file('costs_system.csv', scenario)
    df.set_index('Costs', inplace=True)
    df = df.loc[['cTotal'], ['Total']]
    df = df.rename(columns={'Total': scenario})

    cavern_info[scenario] = 'with Caverns' if scenario in scenarios_with_caverns else 'without Caverns' # Update the metadata

    if df_main.empty:
        df_main = df
    else:
        df_main = df_main.join(df, how='outer')

df_main = df_main.T
df_main = df_main.astype(float) / base_scenario_cost
df_main.sort_values('cTotal')


df_plot = df_main.copy()#.sort_values('cTotal')
df_plot['Cavern Info'] = df_plot.index.map(cavern_info) # Add the metadata back
df_plot.rename(index=rename_dict, inplace=True)

print(df_plot)

# Create a color palette with two distinct colors
palette ={"with Caverns": "skyblue", "without Caverns": "orange"}

# Plot
plt.figure(figsize=(10,6))
sns.barplot(data=df_plot, x=df_plot.index, y='cTotal', hue='Cavern Info', palette=palette)
plt.grid(True,linestyle='--', which='major', color='gray', alpha=.5, axis='y') 
plt.xlabel('Scenarios')  
plt.ylabel('Normalized Costs')
plt.title('Bar chart of Costs')
plt.xticks(rotation=90)  # Rotate x-axis labels for better visibility
plt.legend(title='Cavern Info')
plt.show()

#ax.grid(True, linestyle='--', which='major', color='gray', alpha=.3, axis='y')


# In[32]:


scenarios_without_caverns = scenarios_no_caverns

df_main = pd.DataFrame()
cavern_info = {} # Here's where we'll store the metadata

base_scenario = [s for s in scenarios_without_caverns if 'NoCap' in s and 'no_cavern' in s][0]
df_base_scenario = open_results_file('costs_system.csv', base_scenario)
df_base_scenario.set_index('Costs', inplace=True)
df_base_scenario = df_base_scenario.loc[['cTotal'], ['Total']]
df_base_scenario = df_base_scenario.rename(columns={'Total': base_scenario})
base_scenario_cost = df_base_scenario.iloc[0][0]

for scenario in scenarios_without_caverns + scenarios_with_caverns:

    df = open_results_file('costs_system.csv', scenario)
    df.set_index('Costs', inplace=True)
    df = df.loc[['cTotal'], ['Total']]
    df = df.rename(columns={'Total': scenario})

    cavern_info[scenario] = 'with Caverns' if scenario in scenarios_with_caverns else 'without Caverns' # Update the metadata

    if df_main.empty:
        df_main = df
    else:
        df_main = df_main.join(df, how='outer')

df_main = df_main.T
df_main = (df_main.astype(float) - base_scenario_cost) / base_scenario_cost
df_main.sort_values('cTotal')

df_plot = df_main.copy()
df_plot['Cavern Info'] = df_plot.index.map(cavern_info) # Add the metadata back
df_plot.rename(index=rename_dict, inplace=True)

# List to hold the differences
differences = []

# Loop over unique scenario names
for scenario in set(df_plot.index.str.replace(" with Salt Caverns", "").str.replace(" without Salt Caverns", "")):
    # Get the values for the scenario with and without caverns
    with_caverns = df_plot.loc[scenario + " with Salt Caverns", "cTotal"]
    without_caverns = df_plot.loc[scenario + " without Salt Caverns", "cTotal"]
    
    # Calculate the difference and append to the list
    differences.append(with_caverns - without_caverns)

# Create a new DataFrame with the differences
df_differences = pd.DataFrame(differences, index=set(df_plot.index.str.replace(" with Salt Caverns", "").str.replace(" without Salt Caverns", "")), columns=["Difference"])



# Define the order
order_dict = {"No Emission Cap\n": 1,
              "70% Emission Reduction Cap\n": 2,
              "85% Emission Reduction Cap\n": 3,
              "90% Emission Reduction Cap\n": 4,
              "95% Emission Reduction Cap\n": 5,
              "100% Emission Reduction Cap\n": 6}

# Add a new column to the DataFrame with the order
df_differences["Order"] = df_differences.index.map(order_dict)
print(df_differences)
# Sort by the new column
df_differences.sort_values("Order", inplace=True)

# Drop the order column
df_differences.drop("Order", axis=1, inplace=True)

# Plot the differences
# Convert 'Difference' to percentage
df_differences['Difference'] = df_differences['Difference'] * 100

# Plot
df_differences.plot(kind='bar', legend=False)
plt.grid(True, linestyle='--', which='major', color='gray', alpha=.5, axis='y')
plt.xlabel('Scenarios')  
plt.ylabel('Difference in Normalized Costs from base case (No Cap + No Caverns) [%]')  # indicate percentages in y-label
plt.title('Bar chart of Difference in Costs between with and without Caverns')
plt.xticks(rotation=90)  # Rotate x-axis labels for better visibility
plt.show()

#save_and_show_plot(fig, 'your_image_name')


# In[33]:


scenarios_without_caverns = scenarios_no_caverns

df_main = pd.DataFrame()
# Find the scenario with 'NoCap' and 'no_cavern' in the string
base_scenario = [s for s in scenarios_without_caverns if 'NoCap' in s and 'no_cavern' in s][0]
#print(base_scenario)
df_base_scenario = open_results_file('costs_system.csv', base_scenario)
    # Set 'Costs' as the index
df_base_scenario.set_index('Costs', inplace=True)
# Keep only the 'Total' column and 'cTotal' row
df_base_scenario = df_base_scenario.loc[['cTotal'], ['Total']]
df_base_scenario = df_base_scenario.rename(columns={'Total': base_scenario})
print(df_base_scenario.iloc[0][0])


# In[34]:


#costs_scenarios(scenarios_with_caverns, scenarios_no_caverns, sort_values=True)


# In[ ]:





# In[ ]:



# In[ ]:





# In[ ]:





# In[ ]:




