using CCDReduction
using Test
using Statistics
using FITSIO

include("data.jl")

function test_header(ccd1::CCDData, ccd2::CCDData)
    header1 = ccd1.hdr
    header2 = ccd2.hdr
    @test keys(header1) == keys(header2)
    for (k1, k2) in zip(keys(header1), keys(header2))
        @test header1[k1] == header2[k2]
    end
end

@testset "basic methods" begin include("methods.jl") end
@testset "FITS interface" begin include("fits.jl") end
@testset "collection" begin include("collection.jl") end
