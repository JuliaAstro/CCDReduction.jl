module CCDReduction

using Statistics
using LazyStack
using FITSIO
using DataFrames: DataFrame
using ResumableFunctions
using CFITSIO: bitpix_from_type

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
       images,
       CCDData

include("methods.jl")
include("fits.jl")
include("collection.jl")
include("ccddata.jl")

end
