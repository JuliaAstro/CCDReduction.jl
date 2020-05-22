module CCDReduction

using Statistics

export bias_subtraction,
       bias_subtraction!,
       overscan_subtraction,
       overscan_subtraction!

include("methods.jl")

end
