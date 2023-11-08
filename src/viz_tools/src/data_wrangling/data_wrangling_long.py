#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 16 14:16:47 2023

@author: lesarmstrong
"""

import pandas as pd
import os
import matplotlib.pyplot as plt


# Dictionary to map patterns to energy types
elec_bins = {
    'natural_gas': ['natural_gas', 'naturalgas', 'ng', 'combined_cycle', 'ocgt', 'ccgt'],
    'hydroelectric': ['hydro', 'hydroelectric', 'ror'],  # added 'hydroelectric' to the list for better matching
    'coal': ['coal', 'lignite'],
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
    'electrolyzer': ['electrolyzer', 'electrolyzers'],  # added 'hydroelectric' to the list for better matching
    'h2_storage': ['storage'],
    'flex_demand':['flex_demand']}


# Get the directory of the script, which should be 'src'
current_directory = os.getcwd()

# Navigate one directory up to the 'viz_tools'
viz_tools_directory = os.path.dirname(current_directory)

# Now, navigate to 'Run'
runs_directory_path = os.path.join(viz_tools_directory, 'runs')

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

    if "Results_Example" in result_folders:
        return "Results_Example"

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
    path = latest_result_finder(run)
    if file_name.startswith('HSC'):
        path = path + 'Results_HSC/'
    path = path + file_name
    df = pd.read_csv(path)
    return(df)

def open_inputs_file(file_name, run):
    path = runs_directory_path + run + '/' + file_name
    df = pd.read_csv(path)
    return(df)



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


# "run" is the string pointing to the target directory DOLPHYN case
# Helper Function 1: Opens a specified file and removes rows with 'Total' in the 'Resource' column.
def capacity_df_wrangler(file_name, run):
    df_capacity = open_results_file(file_name, run)
    # Drop columns containing 'AnnualGeneration' in their names
    cols_to_drop = [col for col in df_capacity.columns if 'AnnualGeneration' in col]
    df_capacity = df_capacity.drop(columns=cols_to_drop)
    return df_capacity[df_capacity['Resource'] != 'Total']

# Helper Function 2: Transforms the power dataframe by various operations.
def power_df_wrangler(df_power):
    # Transpose the dataframe and set 'Resource' as the index
    df_power = df_power.set_index('Resource').T
    
    # Filter only the 'AnnualSum' column
    df_power = df_power[['AnnualSum']]
    
    # Rename the column to 'AnnualGeneration'
    df_power.rename(columns={'AnnualSum': 'AnnualGeneration'}, inplace=True)
    
    # Reset index and rename the columns appropriately
    df_power = df_power.reset_index()
    df_power.rename(columns={'index': 'Resource'}, inplace=True)

    
    return df_power

# Helper Function 3: Melts the dataframe and renames certain columns based on the provided rename dictionary.
def melt_and_rename(df, rename_dict):
    # Select the columns of interest
    variables_of_interest = ['Zone', 'EndCap', 'Resource', 'AnnualGeneration']
    df = df[variables_of_interest]
    
    # Melt the dataframe to have a long-format structure
    melted_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                        value_vars=['EndCap', 'AnnualGeneration'], 
                        var_name='Type', value_name='Value')
    
    # Rename the 'Type' column values based on the provided dictionary
    melted_df['Type'] = melted_df['Type'].replace(rename_dict)
    # Remove rows from melted_df where 'Resource' contains either 'storage' or 'battery'
    # AND the 'Type' column contains the word 'generation'.
    # This is done because we dont want to count generation discharge because that would essentially double count some generation
    melted_df = melted_df[~((melted_df['Resource'].str.contains('storage|battery', case=False)) & 
                            (melted_df['Type'].str.contains('generation', case=False)))]
    
    return melted_df

# Main Function 1: Analysis for electricity data
def electricity_analysis(run):
    # Preprocess capacity data
    df_capacity = capacity_df_wrangler('capacity.csv', run)
    
    # Transform power data
    df_power = power_df_wrangler(open_results_file('power.csv', run))
    
    # Merge the capacity and power data on 'Resource'
    df = pd.merge(df_power, df_capacity, on='Resource', how='inner')
    
    # Identify technology type for the dataframe
    df = identify_tech_type(df, bin_type="elec")
    
    
    # Melt and rename the dataframe for final result
    return melt_and_rename(df, {
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })

# Main Function 2: Analysis for H2 data
def h2_analysis(run):
    # Preprocess H2 capacity data
    df_capacity = capacity_df_wrangler('HSC_generation_storage_capacity.csv', run)
    
    # Transform H2 power data
    df_power = power_df_wrangler(open_results_file('HSC_h2_generation_discharge.csv', run))
    
    # Merge the capacity and power data on 'Resource'
    df = pd.merge(df_power, df_capacity, on='Resource', how='inner')
    
    # Identify technology type for the dataframe
    df = identify_tech_type(df, "h2")
    
    
    # Filter out rows containing 'storage' or 'battery'
    
    df = melt_and_rename(df, {
        'EndCap': 'h2_capacity_tonne_hr',
        'AnnualGeneration': 'h2_generation_tonne'
    })
    # Melt and rename the dataframe for final result
    return(df)



def main(run_path):
    
    dfs = []
    df_elec = electricity_analysis(run_path)
    df_elec['Run'] = run_path
    dfs.append(df_elec)
    df_h2 = h2_analysis(run_path)
    df_h2['Run'] = run_path
    dfs.append(df_h2)
    df = pd.concat(dfs)  # Concatenate all DataFrames in the list
    
    return(df)

def main_multiple_runs():
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










