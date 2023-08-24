#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 16 14:16:47 2023

@author: lesarmstrong
"""

import pandas as pd
import os
import matplotlib.pyplot as plt


# Get the directory of the script, which should be 'src'
current_directory = os.getcwd()

# Navigate one directory up to the 'viz_tools'
viz_tools_directory = os.path.dirname(current_directory)

# Now, navigate to 'Run'
runs_directory_path = os.path.join(viz_tools_directory, 'runs')

# Check if the directory exists and change to it
if os.path.exists(runs_directory_path ):
    os.chdir(runs_directory_path )
    print(f"Changed directory to: {runs_directory_path }")
else:
    print("Run directory not found!")

def list_directories(path):
    # Get all the entries in the directory
    entries = os.listdir(path)

    # Filter out only the directories from the list
    directories = [entry for entry in entries if os.path.isdir(os.path.join(path, entry))]

    return directories


def save_and_show_plot(fig, filename, directory='plots_folder'):
    # Make sure the directory exists, if not, create it
    os.makedirs(directory, exist_ok=True)
    fig.savefig(f"{directory}/{filename}.png", bbox_inches='tight', dpi=300)
    plt.close(fig)  # Close the figure


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
    return(path)
    
def open_results_file(file_name, run):
    #run = runs_directory_path + '/' + run
    path = latest_result_finder(run)
    if file_name.startswith('HSC'):
        path = path + 'Results_HSC/'
    path = path + file_name
    #print(path)
    df = pd.read_csv(path)
    return(df)

def open_inputs_file(file_name, run):
    path = runs_directory_path + run + '/' + file_name
    df = pd.read_csv(path)
    return(df)




# Dictionary to map patterns to energy types
elec_bins = {
    'natural_gas': ['natural_gas', 'naturalgas', 'ng', 'combined_cycle', 'ocgt', 'ccgt'],
    'natural_gas_w_CCS': ['natural_gas_ccs'],
    'hydroelectric': ['hydro', 'hydroelectric', 'ror'],  # added 'hydroelectric' to the list for better matching
    'coal': ['coal'],
    'solar': ['solar', 'pv'],
    'wind': ['wind'],
    'nuclear': ['nuclear'],
    'battery': ['battery', 'lithium', 'storage'],
    'phs' : ['phs', "pumped"],
    'oil' : ['oil'],
    'biomass' : ["biomass"],
    'H2': ['H2']
}

h2_bins = {
    'smr': ['smr'],
    'atr': ['atr'],
    'elecrolyzer': ['electrolyzer'],  # added 'hydroelectric' to the list for better matching
    'h2_storage': ['storage']}


# Function to categorize energy types based on patterns in a resource name.
def categorize_energy_type(resource_name, bin_type):
    # Convert the resource name to lowercase to ensure case-insensitive matching.
    resource_name = resource_name.lower()
    
    # Check if 'H2' pattern is in the resource_name first, and if so, return 'H2' immediately to avoid CCGT and OCGT confusion
    if 'h2' in resource_name:
        return 'H2'

    if bin_type == "elec":
        cat_bins = elec_bins
    elif bin_type == "h2":
        cat_bins = h2_bins
    else:
        TypeError("bin_type invalid")
        

    # Iterate through each energy bin and its associated patterns.
    for cat_bin, patterns in cat_bins.items():
        for pattern in patterns:
            # Check if the current pattern exists in the resource name.
            if pattern in resource_name:
                # Special handling for natural gas with CCS:
                # If the energy bin is "natural_gas" and "ccs" is also in the resource name,
                # then it's categorized as "natural_gas_w_CCS".
                if cat_bin in resource_name and "ccs" in resource_name:
                    return cat_bin + "_ccs"
                
                # Return the identified energy bin.
                return cat_bin
        
    # If no patterns matched, return the original resource_name
    return resource_name



def identify_tech_type(df, bin_type, resources='', aggregate=True, dont_aggregate=''):
    
    # Bin Energy Groups
    df['Resource'] = df['Resource'].apply(categorize_energy_type, args = (bin_type,))

    if aggregate == True:
        # Aggregate columns based on both Zone and the identified technology types
        aggregated_df = df.groupby(['Zone', 'Resource']).sum().reset_index()
        
        return aggregated_df

    return df

    
    
'''
def zone_ID(run, file_name='HSC_h2_generation_discharge.csv'):
    df = open_results_file(run=run, file_name='HSC_h2_generation_discharge.csv')
    df = df.T
    df = df.reset_index()
    df.columns = df.iloc[0]
    df = df[1:]
    df = df.rename(columns={'Zone': 'Zone_N'})
    df = df[df['Resource'] != 'Total']
    resources = df[df['Resource'] != 'Total']

    df = identify_tech_type(df, resources, aggregate=False)
    df = df.iloc[:-1]
    df = df.reset_index()
    df['Zone'] = df['Resource'].apply(lambda resource: next((zone for zone in zones_names if zone in resource), None))
    zone_dict = pd.Series(df.Zone.values,index=df.Zone_N).to_dict()
    zone_dict = {f'z{int(k)}': v for k, v in zone_dict.items()}
    # Create a dictionary identifying zone numbers to zone names. Zone numbers are the keys and zone names are the values
    zone_number_dict = df.set_index('Zone_N')['Zone'].to_dict()
    
    return(zone_dict, zone_number_dict)
'''



def capacity_w_H2G2p_analysis(run):
    df = open_results_file('capacity_w_H2G2P.csv', run)
    #drop total row
    df = df[df['Resource'] != 'Total']

    df = identify_tech_type(df)
    
    #breakpoint()
    
    variables_of_interest = ['Zone', 'EndCap', 'AnnualGeneration', 'Resource']
    df = df[variables_of_interest]

    # Capacity
    melted_cap_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['EndCap', 'Resource'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_cap_df['Type'] = melted_cap_df['Type'].replace({
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })
    
    
    # Annual Generation
    
    # Capacity
    melted_gen_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['AnnualGeneration', 'Resource'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_gen_df['Type'] = melted_gen_df['Type'].replace({
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })
    
    
    melted_df = pd.concat([melted_cap_df, melted_gen_df], ignore_index=True)
    
    
    return(melted_df)


# NEED TO DO FOR H2 NOW


def capacity_w_H2G2p_analysis(run):
    df = open_results_file('capacity_w_H2G2P.csv', run)
    #drop total row
    df = df[df['Resource'] != 'Total']

    df = identify_tech_type(df)
    
    #breakpoint()
    
    variables_of_interest = ['Zone', 'EndCap', 'AnnualGeneration', 'Resource']
    df = df[variables_of_interest]

    # Capacity
    melted_cap_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['EndCap', 'Resource'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_cap_df['Type'] = melted_cap_df['Type'].replace({
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })
    
    
    # Annual Generation
    
    # Capacity
    melted_gen_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['AnnualGeneration', 'Resource'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_gen_df['Type'] = melted_gen_df['Type'].replace({
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })
    
    
    melted_df = pd.concat([melted_cap_df, melted_gen_df], ignore_index=True)
    
    
    return(melted_df)


def electricity_analysis(run):
    df = open_results_file('capacity.csv', run)
    #drop total row
    df = df[df['Resource'] != 'Total']

    df = identify_tech_type(df, bin_type = "elec")
    
    #breakpoint()
    
    variables_of_interest = ['Zone', 'EndCap', 'AnnualGeneration', 'Resource']
    df = df[variables_of_interest]

    # Capacity
    melted_cap_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['EndCap', 'AnnualGeneration'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_cap_df['Type'] = melted_cap_df['Type'].replace({
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })
    
    
    # Annual Generation
    
    # Capacity
    melted_gen_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['AnnualGeneration', 'EndCap'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_gen_df['Type'] = melted_gen_df['Type'].replace({
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })
    
    
    melted_df = pd.concat([melted_cap_df, melted_gen_df], ignore_index=True)
    
    
    return(melted_df)



def h2_analysis(run):
    df = open_results_file('HSC_generation_storage_capacity.csv', run)
    #drop total row
    df = df[df['Resource'] != 'Total']

    df = identify_tech_type(df, "h2")
    
    #breakpoint()
    
    variables_of_interest = ['Zone', 'EndCap', 'AnnualGeneration', 'Resource']
    df = df[variables_of_interest]

    # Capacity
    melted_cap_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['EndCap', 'AnnualGeneration'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_cap_df['Type'] = melted_cap_df['Type'].replace({
        'EndCap': 'h2_capacity_tonne_hr',
        'AnnualGeneration': 'h2_generation_tonne'
    })
    
    
    # Annual Generation
    
    # Capacity
    melted_gen_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['AnnualGeneration', 'EndCap'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_gen_df['Type'] = melted_gen_df['Type'].replace({
        'EndCap': 'h2capacity_MW',
        'AnnualGeneration': 'h2_generation_MWh'
    })
    
    
    melted_df = pd.concat([melted_cap_df, melted_gen_df], ignore_index=True)
    
    
    return(melted_df)

'''
def main():
    runs_list = list_directories(runs_directory_path)
    
    dfs = []  # A list to store individual DataFrames
    
    for run in runs_list:  
        df_elec = electricity_analysis(run)
        df_elec['Run'] = run
        dfs.append(df_elec)
        df_h2 = h2_analysis(run)
        df_h2['Run'] = run
        dfs.append(df_h2)  # Append individual DataFrame to the list
        
    df = pd.concat(dfs)  # Concatenate all DataFrames in the list
    
    return(df)

df = main()
'''







