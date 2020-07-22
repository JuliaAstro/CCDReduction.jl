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
