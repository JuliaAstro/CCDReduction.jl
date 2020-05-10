# CCDReduction.jl

[![Build Status](https://travis-ci.com/siddharthlal25/CCDReduction.jl.svg?branch=master)](https://travis-ci.com/siddharthlal25/CCDReduction.jl)
[![Codecov](https://codecov.io/gh/siddharthlal25/CCDReduction.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/siddharthlal25/CCDReduction.jl)

A package for performing CCD data reduction and processing.

## Roadmap

### Data Structures

* `Collection` (name TBD?) type

Some kind of container for holding the different images. I think a good idea would be to have something that can be given data directly as arrays, or can be given as filenames, or can even be given by directories/globs. The data should be accessed lazily (unless loaded in directly).

This will be what is passed to the high-level routines for reduction

* `Pipeline` (name TBD) type

Having some way of storing/serializing a processing pipeline. This should be something that can be created independently of data and then run on a `Collection`

### Algorithms

* Statistical: lots of image statistics will need to be calculated. For now those may already exist, or might be in a different package, might need to be added here, or might need to be added somewhere like `AstroBase.jl`
* Cosmic-Ray Detection
* Background Subtraction
* Flat-Fielding
* Bias Subtraction
* Non-linearity correction
* Image Registration (not in here, should make a separate package)
* Stacking
* Overscan subtraction
* Morphological changes (trim, pad, ... probably already in Images.jl)

### Other

* Offer many ways to output
* Full integration with Unitful
* Variance calculations
* Good mix of low-level, high granularity functions and high-level methods for chaining processing together. I would love to see something where you can denote `bias |> dark |> register |> median_stack` or seomthing where it sees `bias` and will automatically debias the darks and the science frames, without specifying for each type.
