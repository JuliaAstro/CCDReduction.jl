module CCDReduction

using Statistics
using LazyStack

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
       combine

include("methods.jl")

end
