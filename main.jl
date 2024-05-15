using DRDeed
using Random, Dates, LinearAlgebra, Statistics
using TimeZones
using DataFrames
using Plots, StatsPlots
using XLSX
include("utils.jl")
include("fns.jl")

"""
 Experimen1 1
 run the following command which will produce the results and save then
 in a folders called
 "results/scenario1/" and "results/scenario2"
"""

run_experiment_1()


"""
 Experiment2 (production)
 The results will be saved in 
 "results/experiment2/yyyy_mm_dd/solustions.xlsx"
 where yyyy_mm_dd stands for the date when the results are saved.
"""
sols = experiment2(50:50:400, 4:4:20, "results/experiment2") # uncomment to run


"""
 Experiment2 (plots and tables)
 The following reads the stored data in
 "results/experiment2/yyyy_mm_dd/solustions.xlsx"

 df = readExperiment2Results(<xlsx_file>,<name_of_sheet>)
"""

df =
  readExperiment2Results("results/experiment2/2024_05_15/solutions.xlsx", "SOLUTIONS")
groupddf =
  groupby(df, [:c, :g]) |>
  d ->
    combine(
      d,
      :cost => mean => :cost_avg,
      :emission => mean => :emission_avg,
      :utility => mean => :utility_avg,
      :demand => mean => :demand_avg,
      :loss => mean => :loss_avg,
      :power_generated => mean => :power_generated_avg,
      :time => mean => :time_avg,
    ) |>
    d -> transform(
      d,
      [:demand_avg, :power_generated_avg] =>
        ByRow((r1, r2) -> 100 * (r1 - r2) / r1) => :load_reduction,
    )
plts_data = [
  (:cost_avg, "Cost (\$)"),
  (:emission_avg, "Emission (lb)"),
  (:utility_avg, "Utility"),
  (:load_reduction, "Load Reduction (MW)"),
  (:loss_avg, "Loss (MW)"),
  (:time_avg, "CPU Time (seconds)"),
]
pls = map(plts_data) do (item, ylabel)
  pltit(
    groupddf,
    50:50:400,
    4:4:20,
    item,
    "Number of customers",
    ylabel;
    folder="results/experiment2/2024_05_15",
  )
end

saveed_df = select(
  groupddf,
  :c => :Customers,
  :g => :Generators,
  :cost_avg => :Cost,
  :emission_avg => :Emission,
  :utility_avg => :Utility,
  :load_reduction => :Power_Load_Reduction,
  :loss_avg => :Loss,
)
open("results/experiment2/2024_05_15/results.tex", "w") do f
  str = show(f, MIME("text/latex"), saveed_df)
  write(f, str)
end