module CCDReduction

using Statistics

export subtract_bias,
       subtract_bias!,
       subtract_overscan,
       subtract_overscan!

include("methods.jl")

end
