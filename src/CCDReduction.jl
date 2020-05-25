module CCDReduction

using Statistics

export subtract_bias,
       subtract_bias!,
       subtract_overscan,
       subtract_overscan!,
       flat_correct,
       flat_correct!

include("methods.jl")

end
