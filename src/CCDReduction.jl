module CCDReduction

using Statistics
using LazyStack
using FITSIO
using DataFrames: DataFrame

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
       fitscollection

include("methods.jl")
include("fits.jl")
include("collection.jl")

end
