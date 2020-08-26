module CCDReduction

using Statistics
using LazyStack
using FITSIO
using DataFrames: DataFrame
using ResumableFunctions

export subtract_bias,
       subtract_bias!,
       subtract_overscan,
       subtract_overscan!,
       flat_correct,
       flat_correct!,
       trim,
       trimview,
       crop,
       cropview,
       combine,
       subtract_dark,
       subtract_dark!,
       fitscollection,
       arrays,
       filenames,
       ccds,
       CCDData,
       data,
       hdr

include("ccddata.jl")
include("methods.jl")
include("fits.jl")
include("collection.jl")

end
