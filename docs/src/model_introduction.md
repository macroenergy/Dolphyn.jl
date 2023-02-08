# DOLPHYN Model Introduction

## Introduction
The DOLPHYN (short for Decision Optimization of Low-Carbon Power-Hydrogen Nexus) model allows for simultaneous co-optimization of investment and operation of bulk electricity and hydrogen infrastructure while considering a range of technologies across the supply chain of each vector and various policy and system reliability constraints.  The framework is an extension of the electricity system expansion implemented in the [GenX model](https://genxproject.github.io/GenX/dev/), by modeling the H$_2$ supply chain and simultaneously optimizing infrastructure investments and operations across both supply for the least total system (electricity and H$_2$ sectors) cost to meet the electricity and H$_2$ demands. The following key layers are included in the model for both electricity and hydrogen supply chains:


1. Capacity expansion planning (e.g., investment and retirement decisions for a full range of centralized and distributed generation, storage, and demand-side resources)
2. Hourly dispatch of generation, storage, and demand-side resources,
3. Unit commitment decisions and operational constraints for certain inflexible generators,
4. Commitment of generation, storage, and demand-side capacity to meet system reliability requirements (e.g. operating or planning reserve requirements),
5. Transmission network (including losses) and network expansion decisions, and
6. Optional policy constraints including different types of constraints related system/supply chain-level CO$_2$ emissions as well as technology share requirements (e.g. renewable energy mandates)

A key feature of the model is the representation of linkages between the electricity and hydrogen supply chains, including:
1. The ability for electricity to be used across the hydrogen supply chain, including for production, compression related to storage and transport, as well as liquefaction,
2. The ability to utilize hydrogen for power generation, 
3. The ability to trade emissions across the two sectors to meet system-wide emissions goals.

![Overview of the DOLPHYN model](assets/DOLPHYN_overview.png)
*Figure. Overview of the DOLPHYN model as of September 2022*

Depending on the dimensionality of the problem, it may not be possible to model all decision layers at the highest possible resolution of detail, so the DOLPHYN model, like the [GenX model](https://github.com/GenXProject/GenX) it is adapted from, is designed to be highly configurable, allowing the user to specify the level of detail or abstraction along each of these layers or to omit one or more layers from consideration entirely.

In that spirit, the addition of the hydrogen supply chain and its linkage with the electricity supply chain has been implemented such that the model can be run either as a coupled electricity-hydrogen infrastructure planning model or a pure electricity infrastructure model alone (i.e. GenX mode). Note that due to the need for electricity price as input to the hydrogen supply chain, the model currently CANNOT be setup purely as standalone hydrogen supply chain planning model. Future developments will allow the user to provide an electricity price series as an input to allow the model to be run to optimize the hydrogen supply chain alone.

The basic architecture of the DOLPHYN code involves the following key modules, denoted as folders in the source code directory

Modules developed:
- **GenX** module for power sector modeling including power generation from conventional and renewable sources, power transimission via lines, power storage and power consumption. Note that much of the code is similar to the code available on [GenX repository](https://github.com/GenXProject/GenX) with necessary modifications to allow for representing interactions with the hydrogen supply chain and in future, supply chain of other vectors.

Modules in development:
- **HSC** module for hydrogen supply chain modeling including hydrogen generation from fossil fuels and electrolysis, hydrogen transimission via pipelines and trucks, hydrogen demand-side flexibility and gaseous hydrogen storage.

Currently, we are developing modules to represent addtional vectors relevant for a deeply decarbonized energy system, such as CO$_2$, bioenergy as well as gaseous and liquid fuels produced from these carbon sources and their interaction with the hydrogen and electricity supply chains.


DOLPYHN also allows the user to specify several optional public policy constraints, such as CO$_2$ emissions limits for the power and hydrogen supply chains either independently or in a coupled manner, minimum energy share requirements for the power sector (such as renewable portfolio standard or clean energy standard policies), and minimum technology capacity requirements (e.g. technology deployment mandates) for the power sector.

The model is usually configured to consider a full year of operating decisions at an hourly resolution, but as this is often not tractable when considering large-scale problems with high resolution in other dimensions, DOLPHYN is also designed to model a number of subperiods -- typically multiday periods of chronologically sequential hourly operating decisions -- that can be selected via appropriate statistical clustering methods to represent a full year of operations ([De Sisternes Jimenez and Webster, 2013](https://dspace.mit.edu/handle/1721.1/102959), [De Sisternes Jimenez, 2014](https://globalchange.mit.edu/publication/15977), [Poncelet et al., 2016](https://www.sciencedirect.com/science/article/abs/pii/S0306261915013276#:~:text=However%2C%20increasing%20the%20level%20of,in%20an%20increased%20computational%20cost.&text=To%20do%20so%2C%20the%20impact,renewable%20energy%20sources%20(IRES).), [Nahmmacher et al., 2016](https://www.sciencedirect.com/science/article/abs/pii/S0360544216308556), [Blanford et al., 2016](https://ideas.repec.org/a/aen/journl/ej39-3-blanfor.html), [Merrick, 2016](https://www.osti.gov/pages/biblio/1324468), [Mallapragada et al., 2018](https://www.sciencedirect.com/science/article/abs/pii/S0360544218315238)). DOLPHYN ships with a [built-in time-domain reduction package](https://genxproject.github.io/GenX/docs/build/time_domain_reduction.html) that uses k-means or k-medoids to cluster raw time series data for load (demand) profiles and resource capacity factor profiles into representative periods during the input processing stage of the model. This method can also consider extreme points in the time series to capture noteworthy periods or periods with notably poor fits.

With appropriate configuration of the model, DOLPHYN thus allows the user to tractably consider several interlinking decision layers in a single optimization problem that would otherwise have been necessary to solve in different separated stages or models. 

The model is currently is configured to only consider a single future planning year. In this sense, the current formulation is *static* because its objective is not to determine when investments should take place over time, but rather to produce a snapshot of the minimum-cost generation capacity mix under some pre-specified future conditions. However, the current implementation of the model can be run in sequence (with outputs from one planning year used as inputs for another subsequent planning year) to represent a step-wise or myopic expansion of the electricity and hydrogen supply chain. Future updates of the model will include the option to allow simultaneous co-optimization of sequential planning decisions over multiple investment periods, where we leverage dual dynamic programming techniques to improve computational tractability.

## Uses

From a centralized planning perspective, the DOLPHYN model can help to determine the investments needed to supply future electricity and hydrogen demand at minimum cost, which can be useful for industry, regulators and other stakeholders to understand the drivers for technology adoption or the implications of various policy interventions.The model can also be used for techno-economic assessment of emerging electricity generation, storage, and demand-side resources and to enumerate the effect of parametric uncertainty (e.g., technology costs, fuel costs, demand, policy decisions) on the system-wide value or role of different resources.