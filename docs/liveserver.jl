#!/usr/bin/env julia

# Repository root 
const repo_root = dirname(@__DIR__)

# Make sure docs environment is active and instantiated
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

# Communicate with docs/make.jl that we are running in live mode
push!(ARGS, "liveserver")

# Configure LiveServer with respective folders
import LiveServer
LiveServer.servedocs(;
    # Documentation root 
    foldername = joinpath(repo_root, "docs"),
    include_dirs = [
        # Watch the src folder so docstrings can be Revise'd
        joinpath(repo_root, "src")
    ],
        # Exclude project environment files
    exclude = [
        joinpath(repo_root, "docs/Project.toml"),
	joinpath(repo_root, "docs/Manifest.toml")
    ]
)
