```@meta
CurrentModule = CCDReduction
```

# CCDReduction.jl

This package provides tools for basic reduction methods of CCD images.

[![GitHub](https://img.shields.io/badge/Code-GitHub-black.svg)](https://github.com/juliaastro/CCDReduction.jl)
[![Build Status](https://travis-ci.com/juliaastro/CCDReduction.jl.svg?branch=master)](https://travis-ci.com/juliaastro/CCDReduction.jl)
[![PkgEval(https://juliaci.github.io/NanosoldierReports/pkgeval_badges/C/CCDReduction.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html)
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

subtract_bias(img, bias_frame)
nothing; # hide
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
nothing; # hide
```

Finally, we can use function chaining (or tools like [Underscores.jl](https://github.com/c42f/Underscores.jl)) for creating a simple processing pipeline!

```@example usage
using Underscores

# 5 science frames
imgs = (10 .* randn(512, 524) for _ in 1:5)

# create pipeline using Underscores.jl
pipeline(img) = @_ img |>
    subtract_overscan(__, (:, 513:524)) |>
    trim(__, (:, 513:524)) |>
    subtract_bias(__, "master_bias.fits")

# apply pipeline to images using broadcast syntax
calib_imgs = pipeline.(imgs)
nothing; # hide
```

## License

This work is distributed under the MIT "expat" license. See [`LICENSE`](https://github.com/juliaastro/CCDReduction.jl/blob/master/LICENSE) for more information.
