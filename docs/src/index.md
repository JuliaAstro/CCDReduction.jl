```@meta
CurrentModule = CCDReduction
```

# CCDReduction.jl

This package provides tools for basic reduction methods of CCD images.

[![GitHub](https://img.shields.io/badge/Code-GitHub-black.svg)](https://github.com/juliaastro/CCDReduction.jl)
[![Build Status](https://travis-ci.com/juliaastro/CCDReduction.jl.svg?branch=master)](https://travis-ci.com/juliaastro/CCDReduction.jl)
[![Codecov](https://codecov.io/gh/juliaastro/CCDReduction.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/juliaastro/CCDReduction.jl)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

From Julia enter Pkg mode

```julia
julia>]

(1.3) pkg> add CCDReduction
```

## Usage

You'll recognize most of the familiar reduction operations allow us to quickly and easily operate on data.

```@example usage
using CCDReduction

noise = randn(512, 512)
bias_frame = reshape(1:262144, 512, 512) |> collect
img = reshape(1:262144, 512, 512) .+ noise

subtract_bias(img, bias_frame) ≈ noise
```

In addition to working on array-like data, we can directly load from a `FITSIO.ImageHDU` or from a filename

```@example usage
using FITSIO

# make fits file
bias_frame = reshape(1:262144, 512, 512) |> collect
FITS("master_bias.fits", "w") do f
    write(f, bias_frame)
end
img = 10 .* randn(512, 512)
debiased = subtract_bias(img, "master_bias.fits")
nothing; # hidden
```

finally, we can use function chaining (or tools like [Underscores.jl](https://github.com/c42f/Underscores.jl)) for creating a simple processing pipeline!

```@example usage
using Underscores

img = 10 .* randn(512, 524)

@_ img |> 
    subtract_overscan(_, (:, 513:524)) |>
    trim(_, (:, 513:524)) |>
    subtract_bias(_, "master_bias.fits")
nothing; # hidden
```

## License

This work is distributed under the MIT "expat" license. See [`LICENSE`](https://github.com/juliaastro/CCDReduction.jl/blob/master/LICENSE) for more information.
