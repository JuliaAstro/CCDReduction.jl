using CCDReduction
using Test
using Statistics
using FITSIO

include("data.jl")

@testset "basic methods" begin
    include("methods.jl")
end

@testset "FITS interface" begin
    include("fits.jl")
end

@testset "collection" begin
    include("collection.jl")
end
