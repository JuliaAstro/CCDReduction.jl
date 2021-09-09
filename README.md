# CCDReduction.jl

[![Build Status](https://github.com/juliaastro/CCDReduction.jl/workflows/CI/badge.svg?branch=main)](https://github.com/juliaastro/CCDReduction.jl/actions)
[![PkgEval](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/C/CCDReduction.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html)
[![Codecov](https://codecov.io/gh/juliaastro/CCDReduction.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/juliaastro/CCDReduction.jl)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaastro.github.io/CCDReduction.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaastro.github.io/CCDReduction.jl/dev)

A package for performing CCD data reduction and processing.



## Usage

For in-depth API infromation and usage examples, please see the [documentation](https://juliaastro.github.io/CCDReduction.jl/dev). You'll recognize most of the familiar reduction operations allow us to quickly and easily operate on data.

```julia
using CCDReduction

noise = randn(512, 512)
bias_frame = reshape(1:262144, 512, 512) |> collect
img = reshape(1:262144, 512, 512) .+ noise

subtract_bias(img, bias_frame)
```

In addition to working on array-like data, we can directly load from a `FITSIO.ImageHDU` or from a filename

```julia
using FITSIO

# make fits file
bias_frame = reshape(1:262144, 512, 512) |> collect
FITS("master_bias.fits", "w") do f
    write(f, bias_frame)
end
img = 10 .* randn(512, 512)
debiased = subtract_bias(img, "master_bias.fits")
```

Finally, we can use function chaining (or tools like [Underscores.jl](https://github.com/c42f/Underscores.jl)) for creating a simple processing pipeline!

```julia
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
```

## License

This work is distributed under the MIT license. See [LICENSE](LICENSE) for more information.
