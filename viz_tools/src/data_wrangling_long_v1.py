#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 16 14:16:47 2023

@author: lesarmstrong
"""

import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt


print(os.getcwd())

runs_directory_path = '../example_viz/Runs'



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
    run = runs_directory_path + '/' + run
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
energy_bins = {
    'natural_gas': ['natural_gas', 'naturalgas', 'ng', 'combined_cycle', 'OCGT', 'CCGT'],
    'natural_gas_w_CCS': ['natural_gas_ccs'],
    'hydroelectric': ['hydro', 'hydroelectric'],  # added 'hydroelectric' to the list for better matching
    'coal': ['coal'],
    'solar': ['solar', 'pv'],
    'wind': ['wind'],
    'nuclear': ['nuclear'],
    'battery': ['battery', 'lithium', 'storage'],
    'H2': ['H2']
}


# Function to categorize energy types based on patterns in a resource name.
def categorize_energy_type(resource_name):
    # Convert the resource name to lowercase to ensure case-insensitive matching.
    resource_name = resource_name.lower()
    
    # Check if 'H2' pattern is in the resource_name first, and if so, return 'H2' immediately to avoid CCGT and OCGT confusion
    if 'h2' in resource_name:
        return 'H2'

    # Iterate through each energy bin and its associated patterns.
    for energy_bin, patterns in energy_bins.items():
        for pattern in patterns:
            # Check if the current pattern exists in the resource name.
            if pattern in resource_name:
                # Special handling for natural gas with CCS:
                # If the energy bin is "natural_gas" and "ccs" is also in the resource name,
                # then it's categorized as "natural_gas_w_CCS".
                if energy_bin in energy_bins.items() and "ccs" in resource_name:
                    return "natural_gas_w_CCS"
                
                # Return the identified energy bin.
                return energy_bin
        
    # If no patterns matched, return the original resource_name
    return resource_name



def identify_tech_type(df, resources='', aggregate=True, dont_aggregate=''):
    # Bin Energy Groups
    
    df['Resource'] = df['Resource'].apply(categorize_energy_type)

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

    melted_df = pd.melt(df, id_vars=['Zone', 'Resource'], 
                       value_vars=['EndCap', 'Resource'], 
                       var_name='Type', value_name='Value')

    # Replace 'Type' values based on condition
    melted_df['Type'] = melted_df['Type'].replace({
        'EndCap': 'electricity_capacity_MW',
        'AnnualGeneration': 'electricity_generation_MWh'
    })
    
    return(melted_df)



# NEED TO DO FOR H2 NOW


# NEED TO DO THROUGH MULTIPLE RUNS





