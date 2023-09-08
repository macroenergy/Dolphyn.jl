

# Dictionary to map patterns to energy types
elec_bins = {
    'natural_gas': ['natural_gas', 'naturalgas', 'ng', 'combined_cycle', 'ocgt', 'ccgt'],
    'natural_gas_w_CCS': ['natural_gas_ccs'],
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
    'h2_storage': ['storage']}
