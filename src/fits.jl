# helper functions

#=
FITSIO.jl takes over memory read in by cfitsio, which reads in row-major form,
whereas when Julia takes that memory, it is assumed as column major.
Therefore all data read by `read` is transposed.
Related comment: https://github.com/JuliaAstro/CCDReduction.jl/pull/16#issuecomment-638492572
=#
function getdata(hdu::ImageHDU)
    data = read(hdu)
    d = ndims(data)
    return permutedims(data, d:-1:1)
end

# documentation for functions interface with CCDData
"""
    subtract_bias(frame, bias_frame)

Load HDU for the `frame` or `bias_frame` as `CCDData` before subtracting from `frame`.

```julia
framefits = FITS(...) # loads FITS file
biasfits = FITS(...) # loads FITS file

frame = CCDData(framefits[1]) # loads ImageHDU of framefits as CCDData
bias = CCDData(biasfits[1]) # loads ImageHDU of biasfits as CCDData

processed_frame = subtract_bias(frame, bias) # outputs bias subtracted frame
```

Output of the function inherits the type of first parameter and header file of output (if applicable) is same as of the first parameter.
The parameters can also be of mixed type, e.g. `frame` is an `Array` and `bias_frame` is `CCDData` or vice versa.
"""
function subtract_bias end


"""
    subtract_bias!(frame, bias_frame)

Load HDU for the `frame` or `bias_frame` as `CCDData` before subtracting from `frame` in-place.
"""
function subtract_bias! end
