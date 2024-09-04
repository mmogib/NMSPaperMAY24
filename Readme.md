# Tables of Results
Data and details results can be found in the document [TABLES.pdf]("./TABLE.pdf").

# Paper Experiments
> Integrated Game-Theoretic and Multi-objective Models for Dynamic Economic Emission Dispatch in Multi-Period Smart Grid Demand Response
>
> Authors:
> - Norah Almuraysil, 
> - Mohammed Alshahrani, 
> - Slim Belhaiza

This repository contains the code and instructions for running experiments using the `DRDeed` package. The experiments focus on optimizing energy management in smart grids by integrating demand response strategies.

## Requirements

To run the experiments, you need to install the following Julia packages:

- `DRDeed`
- `Random`
- `Dates`
- `LinearAlgebra`
- `Statistics`
- `TimeZones`
- `DataFrames`
- `Plots`
- `StatsPlots`
- `XLSX`

You can install these packages using Julia's package manager:

```julia
using Pkg
Pkg.add("https://github.com/mmogib/DRDeed.jl")
Pkg.add("TimeZones")
Pkg.add("DataFrames")
Pkg.add("Plots")
Pkg.add("StatsPlots")
Pkg.add("XLSX")
```

## Setup

Make sure to include the necessary utility files before running the experiments:

```julia
include("utils.jl")
include("fns.jl")
```

## Experiment 1

To run Experiment 1, execute the following command. The results will be saved in the folders `results/scenario1/` and `results/scenario2/`.

```julia
run_experiment_1()
```

## Experiment 2 (Production)

To run Experiment 2 and save the results, use the following command. The results will be saved in `results/experiment2/yyyy_mm_dd/solutions.xlsx`, where `yyyy_mm_dd` stands for the date when the results are saved.

```julia
sols = experiment2(50:50:400, 4:4:20, "results/experiment2")  # Uncomment to run
```

## Experiment 2 (Plots and Tables)

The provided Julia code performs several steps to read data from an Excel file, process it, and generate plots. Here's a detailed explanation of each part:

1. **Reading Data from Excel:**
   ```julia
   df = readExperiment2Results("results/experiment2/2024_05_15/solutions.xlsx", "SOLUTIONS")
   ```
   This line reads the data from the specified Excel file (`solutions.xlsx`) and sheet (`SOLUTIONS`) into a DataFrame `df`. The `readExperiment2Results` function is assumed to be a custom function defined elsewhere in the code.

2. **Grouping and Aggregating Data:**
   ```julia
   groupddf = groupby(df, [:c, :g]) |>
     d -> combine(d,
                  :cost => mean => :cost_avg,
                  :emission => mean => :emission_avg,
                  :utility => mean => :utility_avg,
                  :demand => mean => :demand_avg,
                  :loss => mean => :loss_avg,
                  :power_generated => mean => :power_generated_avg,
                  :time => mean => :time_avg) |>
     d -> transform(d,
                    [:demand_avg, :power_generated_avg] =>
                    ByRow((r1, r2) -> 100 * (r1 - r2) / r1) => :load_reduction)
   ```
   - **Grouping:** `groupby(df, [:c, :g])` groups the DataFrame `df` by the columns `:c` (representing the number of customers) and `:g` (representing the number of generators).
   - **Aggregating:** For each group, the `combine` function calculates the mean of several columns (`:cost`, `:emission`, `:utility`, `:demand`, `:loss`, `:power_generated`, `:time`) and creates new columns with the suffix `_avg` (e.g., `:cost_avg`, `:emission_avg`).
   - **Calculating Load Reduction:** The `transform` function adds a new column `:load_reduction` that calculates the percentage reduction in load using the formula `100 * (demand_avg - power_generated_avg) / demand_avg`.

3. **Plot Data Definitions:**
   ```julia
   plts_data = [
     (:cost_avg, "Cost (\$)"),
     (:emission_avg, "Emission (lb)"),
     (:utility_avg, "Utility"),
     (:load_reduction, "Load Reduction (MW)"),
     (:loss_avg, "Loss (MW)"),
     (:time_avg, "CPU Time (seconds)"),
   ]
   ```
   This array defines the columns to be plotted along with their corresponding y-axis labels. Each tuple contains the column name and its label.

4. **Generating Plots:**
   ```julia
   pls = map(plts_data) do (item, ylabel)
     pltit(groupddf, 50:50:400, 4:4:20, item, "Number of customers", ylabel; folder="results/experiment2/2024_05_12")
   end
   ```
