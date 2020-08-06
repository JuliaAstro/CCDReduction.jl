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

#---------------------------------------------------------------------------------------
# Code generation with codegen to support path of FITS files
for func in (:flat_correct, :subtract_bias, :subtract_dark)
    @eval $func(frame::String, correction; hdu = 1, kwargs...) = $func(CCDData(frame; hdu = hdu), correction; kwargs...)
    @eval $func(frame, correction::String; hdu = 1, kwargs...) = $func(frame, CCDData(correction; hdu = hdu); kwargs...)
    @eval begin
        function $func(frame::String, correction::String; hdu = (1, 1), kwargs...)
            hdus = hdu isa Integer ? (hdu, hdu) : hdu
            return $func(CCDData(frame; hdu = hdus[1]), CCDData(frame; hdu = hdus[2]); kwargs...)
        end
    end
end

for func in (:flat_correct!, :subtract_bias!, :subtract_dark!)
    @eval $func(frame::AbstractArray, correction::String; hdu = 1, kwargs...) = $func(frame, CCDData(correction; hdu = hdu); kwargs...)
end


for func in (:crop, :trim, :subtract_overscan)
    @eval $func(frame::AbstractString, args...; hdu = 1, kwargs...) = $func(CCDData(frame; hdu = hdu), args...; kwargs...)
end

# separate function for combine involving CCDData because of custom header copying
function combine(frames::Vararg{<:CCDData{<:Number}}; header_hdu = 1, kwargs...)
    data_arrays = map(frame -> frame.data, frames)
    processed_frame = combine(data_arrays...; kwargs...)
    return CCDData(processed_frame, deepcopy(frames[header_hdu].hdr))
end

# String supporting version of combine
function combine(frames::Vararg{AbstractString, N}; hdu = ntuple(one, N), kwargs...) where N
    ccddata_frames = map(zip(frames, hdu)) do (frame, hdu_idx)
        CCDData(frame; hdu = hdu_idx)
    end
    return combine(ccddata_frames...; kwargs...)
end
