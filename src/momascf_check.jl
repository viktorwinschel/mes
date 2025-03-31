using CSV
using DataFrames

s0 = CSV.read("src/momascf_originale_data.csv", DataFrame)
s1 = CSV.read("src/momascf_v01_data.csv", DataFrame)
s2 = CSV.read("src/momascf_v02_data.csv", DataFrame)
s2en = CSV.read("src/momascf_v02_en_data.csv", DataFrame)

println("s0==s1 ", s0 == s1)
println("s0==s2 ", s0 == s2)
println("s0==s2en ", s0 == s2en)
