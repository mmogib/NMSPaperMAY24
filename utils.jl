function outputfolder(root::String; dated::Bool=true)
  zdt = now(tz"Asia/Riyadh")
  dayfolder = Dates.format(zdt, "yyyy_mm_dd")
  # hourfolder = Dates.format(zdt, "HH")
  root_dir = dated ? mkpath("$root/$dayfolder") : mkpath("$root")
  return root_dir
end

function outputfilename(
  name::String;
  extension::Union{Nothing,String}=nothing,
  root::String=".",
  suffix::Union{Nothing,String}=nothing,
  dated::Bool=true,
)
  root_dir = outputfolder(root; dated)
  filename = if isnothing(suffix)
    "$root_dir/$name"
  else
    "$root_dir/$(name)_$suffix"
  end
  isnothing(extension) ? filename : "$filename.$extension"
end

function getConvexWieghts(n::Int)
  u = rand(n)
  x = [u[i] / sum(u) for i = 1:n]
  x
end
