function experiment1(
  customers::Int,
  generators::Int,
  periods::Int,
  folder::String,
  w::Vector{Float64},
  name::String,
)
  printstyled("Experiment 1 ($name) started.\n", color=:blue)
  gtrmmodels = gtdrdeed(customers, generators, periods)
  # soldeed = drdeed(customers, generators, periods)(; w)
  gtr_sol = gtrmmodels[:scalarized](; w)
  # drmodels = drdeed(customers, generators, periods, data = gtr_sol.data.deedData)
  # dr_sol = drmodels(; w)
  # drexcel_file = outputfilename("dr_profile"; dated = true, root = folder)
  # saveModel(dr_sol, drexcel_file)

  excel_file = outputfilename("load_profile"; dated=true, root=folder)
  saveModel(gtr_sol, excel_file)

  Demand = vec(sum(gtr_sol.data.CDemandt', dims=2))
  qsg = vec(sum(gtr_sol.solution.deedSolution.q', dims=2))
  psg = vec(sum(gtr_sol.solution.x', dims=2))
  p1 = Plots.plot(
    [Demand, qsg + psg],
    linetype=:steppre,
    label=["Initial Load Befor SGModel" "Final Load After SGModel"],
    title="Generators Load Profile Before and After SGModel",
    xlabel="Time (hour)",
    ylabel="Generator Power (MW)",
  )
  fig1_file = outputfilename("load_profile"; dated=true, root=folder, extension="svg")
  Plots.svg(p1, fig1_file)

  χ = gtr_sol.solution.deedSolution.χ
  p2 = Plots.plot(
    χ',
    linetype=:steppre,
    label=reshape((["customer $i" for i = 1:customers]), 1, customers),
    title="Optimal Power Curtailed ($name)",
    xlabel="Time (hour)",
    ylabel="Power Curtailed (MW)",
  )
  fig2_file = outputfilename("power_curtailed"; dated=true, root=folder, extension="svg")
  Plots.svg(p2, fig2_file)

  ω = gtr_sol.solution.deedSolution.ω
  p3 = Plots.plot(
    ω',
    linetype=:steppre,
    label=reshape((["customer $i incentive" for i = 1:customers]), 1, customers),
    title="Optimal Incentive ($name)",
    xlabel="Time (hour)",
    ylabel="Incentive (\$)",
  )
  fig3_file = outputfilename("incentive"; dated=true, root=folder, extension="svg")
  Plots.svg(p3, fig3_file)


  # # DR plots
  # grdp = gtr_sol.solution.deedSolution.q
  # # Dm = dr_sol.data.CDemandt
  # for g = 1:generators
  #   power = grdp[g, :]'
  #   dr_fig_file =
  #     outputfilename("generation_output_$g"; dated = true, root = folder, extension = "svg")
  #   p = Plots.plot(
  #     power',
  #     linetype = :steppre,
  #     label = ["P$g GTDR DEED"],
  #     title = "Generation output of unit $g ($name)",
  #     xlabel = "Time (hour)",
  #     ylabel = "Power (MW)",
  #   )
  #   Plots.svg(p, dr_fig_file)
  # end



  gtr_sol
end
function run_experiment_1()
  println("hi")
  scinarios = [
    ("BC", (1 / 3) * ones(3)),
    ("C2", [1.0; 0.0; 0.0]),
    ("C3", [0.0; 1.0; 0.0]),
    ("C4", [0.0; 0.0; 1.0]),
    # ("C31", [0.5; 0.5; 0.0; 0.0]),
    # ("C32", [0.5; 0.0; 0.5; 0.0]),
    # ("C33", [0.5; 0.0; 0.0; 0.5]),
    # ("C34", [0.0; 1 / 3; 1 / 3; 1 / 3]),
    # ("C5", [0.0; 0.0; 1.0; 0.0]),
    # ("C6", [0.0; 0.0; 0.0; 1.0]),
  ]

  sci1 = map(scinarios) do (factor, w)
    experiment1(5, 6, 24, "results/scenario1/$factor", w, "Scinario 1")
  end
  sci2 = map(scinarios) do (factor, w)
    experiment1(7, 10, 24, "results/scenario2/$factor", w, "Scinario 2")
  end

  if all(map(a -> isa(a, SuccessResult), sci1)) && all(map(a -> isa(a, SuccessResult), sci2))
    println("😀")
  else
    println("😥")
  end
end

# function experiment2(generators::Int, folder::String, w::Vector{Float64} = (1 / 3) * ones(3))
#   periods = 24
#   customers = 100
#   printstyled("running experiments 2 with $customers customers\n", color = :blue)
#   solutions = map(5:5:generators) do gs
#     gtrmmodels = gtdrdeed(customers, gs, periods)
#     gtr_sol = gtrmmodels[:scalarized](; w)
#     if isa(gtr_sol, SuccessResult)
#       printstyled("Saving files for $gs generators\n", color = :blue)
#       excel_file = outputfilename("load_profile"; dated = false, root = "$folder/$customers/$gs")
#       saveModel(gtr_sol, excel_file)
#     else
#       printstyled("Failed for $gs generators\n", color = :red)
#     end
#     return gtr_sol
#   end
#   solutions
# end

function getTimedScalarizedGtdrdeed(c::Int, g::Int, T::Int, w::Vector{Float64})
  gtrmmodels = gtdrdeed(c, g, T)
  gtr_times_sol = gtrmmodels[:scalarized](; w)
  gtr_times_sol
end
function experiment2(
  customers::StepRange,
  generators::StepRange,
  folder::String,
  w::Vector{Float64}=(1 / 3) * ones(3),
)
  experiment2(collect(customers), collect(generators), folder, w)
end
function experiment2(
  customers::Vector{Int},
  generators::Vector{Int},
  folder::String,
  w::Vector{Float64}=(1 / 3) * ones(3),
)
  periods = 24
  printstyled("running experiments 3 with $customers customers\n", color=:blue)
  nc = length(customers)
  ng = length(generators)
  trials = 3
  results = Matrix{Float64}(undef, trials * nc * ng, 11)
  row = 0
  for c in customers
    for g in generators
      for trial = 1:trials
        row += 1
        results[row, 1:3] = [c, g, periods]
        counter = 1
        while true
          if counter > 5
            results[row, 11] = 0.0
            break
          end
          timed_sol = @timed getTimedScalarizedGtdrdeed(c, g, periods, w)
          sol = timed_sol.value
          time = timed_sol.time
          cost = sol.solution.deedSolution.Cost
          emission = sol.solution.deedSolution.Emission
          utility = sol.solution.deedSolution.Utility
          losst = sum(sol.solution.deedSolution.Losst)
          demand = sum(sol.data.CDemandt)
          q = sum(sol.solution.deedSolution.q)
          px = sum(sol.solution.x)
          pgenerated = q + px
          if isa(sol, SuccessResult)
            printstyled(
              "Got solution (trial $trial) with $c customers and $g generators\n",
              color=:blue,
            )
            results[row, 4] = cost
            results[row, 5] = emission
            results[row, 6] = utility
            results[row, 7] = losst
            results[row, 8] = demand
            results[row, 9] = pgenerated
            results[row, 10] = time
            results[row, 11] = 1.0
            break
          else
            printstyled("Failed for $g generators\n", color=:red)
            counter += 1
          end
        end
      end

    end
  end
  names =
    [:c, :g, :T, :cost, :emission, :utility, :loss, :demand, :power_generated, :time, :success]
  df = DataFrame(results, :auto) |> x -> rename(x, names)
  excel_file = outputfilename("solutions"; dated=true, root=folder)
  XLSX.writetable("$excel_file.xlsx", "SOLUTIONS" => df, overwrite=true)
  return df
end

function readExperiment2Results(filename::String, sheet::String)
  xlsx = XLSX.readxlsx(filename)
  df = DataFrame(XLSX.eachtablerow(xlsx[sheet]))
  df
end

function pltit(
  sols,
  cs::StepRange,
  gs::StepRange,
  item::Symbol,
  xlabel::String,
  ylabel::String;
  folder::Union{Nothing,String}=nothing,
)
  filtered = map(gs) do g
    filter(r -> r.g == g, sols)
  end
  markers = [(:utriangle) (:circle) (:square) (:diamond) (:star)]
  p = plot(
    collect(cs),
    [map(x -> x[!, item], filtered)...],
    marker=markers,
    label=reshape(["$(i) generators" for i in gs], 1, length(gs)),
    xticks=collect(cs),
    xlabel=xlabel,
    ylabel=ylabel,
  )
  if !isnothing(folder)
    filename = outputfilename(String(item); dated=false, root=folder)
    savefig(p, "$(filename).png")
  end
  p
end