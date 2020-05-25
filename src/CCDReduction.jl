module CCDReduction

using Statistics
using InvertedIndices

export subtract_bias,
       subtract_bias!,
       subtract_overscan,
       subtract_overscan!,
       flat_correct,
       flat_correct!,
       trim,
       trim!

include("methods.jl")

end
