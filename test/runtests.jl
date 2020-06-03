using CCDReduction
using Test
using Statistics
using FITSIO

const test_file_url_M6707HH = "https://www.cfa.harvard.edu/~dfabricant/huchra/ay16/fits/M6707HH.fits"
const test_file_path_M6707HH = joinpath(@__DIR__, "MH6707HH.fits")
!isfile(test_file_path_M6707HH) && download(test_file_url_M6707HH, test_file_path_M6707HH)
const M6707HH =  FITS(test_file_path_M6707HH)

include("methods.jl")
