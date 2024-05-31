#!/usr/bin/env bash

## This script is run when you want to know the whole time taken for running an example case including model scaling.
## If only the time taken without model scaling is needed, disable model scaling flag in the global model setting file.
## To run this script, simply run it: ./run_model_scaling.sh from the command line.
## A log file will get created following the script run. If Log flag is enabled in the global setting file, another log
## will get generated as well. The log output has the content included in the log the script generated but with better format.
##
d=$(date)

##Provide the path that the example case is located
example_full_path="/Example_Systems/SmallNewEngland/OneZone" ##Here can be modified to use any example name
example_run_file="Run.jl" ##May modify to the name of the run file if it is not Run.jl

name_after="Example_Systems" ##Need it here to extract the case name
rest_name="${example_full_path#*$name_after/}" ##Get name after Example_Systems

example_name=$(echo "$rest_name" | sed "s|/|-|") ##Replace slash with hyphen

current_dir=$(cd .. && pwd) ##Since this script is under scripts folder
run_example=$current_dir/$example_full_path/$example_run_file

##Will not log debugging output 
export JULIA_DEBUG=0

##Save the complete process output to a file
{
    echo "Running $example_name at: $d"
    julia --project="$current_dir" "$run_example"
} > $example_name.txt 2>&1
