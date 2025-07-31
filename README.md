# AAAI2026-SM
This repository contains supplementary material for the paper "Learning to Mitigate Adversarial Threats in Mixed-Motive Societies"

## Hardware

Data collection was run on a Linux machine with an RTX 3080 GPU, 64GB RAM, and 1TB Memory. This code may run on lesser specs, however there is no guarentee.

## Software

All dart code was run using Flutter 3.29.0. Flutter packages required are specified in `simulation/pubspec.yaml`.

All python code was run using Python 3.9.12. Packages used include: pandas, tqdm, seaborn, matplotlib, and numpy

## Data

Due to repository size constraints, we omit complete data and instead opt for summaries. In the `data` folder, `results_summary` 1-4 includes data on the last generation of all of the training simulations. `evaluation_summary` 1-4 includes data for the evaluation games that were run after the agents completed training. The `analysis_generator.ipynb` file contains all code for processing the data and generating graphs. 

## Simulation

The `simulation` folder contains all code for training and evaluation the agents. Configurations on what type of agents to run can be changed in the `run_` scripts, and executing these scripts from within the `simulation` folder will start the simulations. Hyperparameters can be tuned in the `simulator_` and `evaluator` Dart files. 

## Agents

For reference, the `agent` folder contains all logic that is used by the agents. 