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

#------------------------------------------------------------------

# FITS interface for basic reduction methods

# code generated with codegen
#=
This loop has more constructors compared to the next one because for methods like
subtract_bias and flat_correct, there are two input frames (and they can be Strings and ImageHDU as well).
So there are a lot of constructors here to tackle all cases.
subtract_dark was not kept here because of the fields data_exposure and dark_exposure. These fields can also
be read from the ImageHDU and hence would have complicated the code generation
=#
for func in (:flat_correct, :subtract_bias)
    @eval $func(frame::ImageHDU, correction::AbstractArray; kwargs...) = $func(getdata(frame), correction; kwargs...)
    @eval $func(frame::AbstractArray, correction::ImageHDU; kwargs...) = $func(frame, getdata(correction); kwargs...)
    @eval $func(frame::ImageHDU, correction::ImageHDU; kwargs...) = $func(getdata(frame), correction; kwargs...)
    @eval $func(frame::String, correction; hdu = 1, kwargs...) = $func(FITS(frame)[hdu], correction; kwargs...)
    @eval $func(frame, correction::String; hdu = 1, kwargs...) = $func(frame, FITS(correction)[hdu]; kwargs...)
    @eval begin
        function $func(frame::String, correction::String; hdu = (1, 1), kwargs...)
            hdus = hdu isa Integer ? (hdu, hdu) : hdu
            return $func(FITS(frame)[hdus[1]], FITS(correction)[hdus[2]]; kwargs...)
        end
    end
end


# The mutating version of these functions only support frame as AbstractArray
for func in (:flat_correct!, :subtract_bias!)
    @eval $func(frame::AbstractArray, correction::ImageHDU; kwargs...) = $func(frame, getdata(correction); kwargs...)
    @eval $func(frame::AbstractArray, correction::String; hdu = 1, kwargs...) = $func(frame, FITS(correction)[hdu]; kwargs...)
end

# The non-mutating version returns finally an array with desired operations on frame (frame can be ImageHDU, String and AbstractArray)
for func in (:crop, :trim, :subtract_overscan)
    @eval $func(frame::ImageHDU, args...; kwargs...) = $func(getdata(frame), args...; kwargs...)
    @eval $func(filename::String, args...; hdu = 1, kwargs...) = $func(FITS(filename)[hdu], args...; kwargs...)
end

# Tackles the case when idxs is a symbol, i.e. reading trimming dimensions from header of ImageHDU
trim(frame::ImageHDU, idxs::Symbol) = trim(frame, read_header(frame)[string(idxs)])

# Tackles the case when overscan region has to be read from header of ImageHDU
subtract_overscan(frame::ImageHDU, key::Symbol; kwargs...) = subtract_overscan(frame, read_header(frame)[string(key)]; kwargs...)


# Documentation for code generated with codegen
"""
    crop(frame::FITSIO.ImageHDU, shape; force_equal = true)
    crop(filename::String, shape; hdu=1, force_equal = true)

Load a FITS file or HDU before cropping.
"""
function crop end


"""
    trim(frame::FITSIO.ImageHDU, idxs)
    trim(filename::String, idxs; hdu=1)

Load a FITS file or HDU before trimming. If `idxs` is a symbol it will be read from the FITS header with that key (case sensitive).
"""
function trim end


"""
    flat_correct(frame, flat_frame; [hdu=1], kwargs...)

Load `frame` and/or `flat_frame` from a given filename or `FITSIO.ImageHDU`. If loading from a file, you can specify the appropriate header using the `hdu` keyword,
 which can be given as an integer or a tuple (if multiple files are being loaded). All keyword arguments will be passed to the [`flat_correct!`](@ref) function after loading the data.
"""
function flat_correct end


"""
    flat_correct!(frame::AbstractArray, flat_frame::FITSIO.ImageHDU; kwargs...)
    flat_correct!(frame::AbstractArray, flat_frame::String; hdu = 1, kwargs...)

Load a FITS file or HDU for the flat frame before correcting `frame` in-place.
"""
function flat_correct! end


"""
    subtract_overscan(frame::FITSIO.ImageHDU, idxs; [dims])
    subtract_overscan(filename::String, idxs; hdu=1, [dims])

Load a FITS file or HDU before subtracting the overscan region. If `idxs` is a symbol it will be read from the FITS header with that key (case sensitive).
"""
function subtract_overscan end


"""
    subtract_bias(frame, bias_frame; [hdu = 1])

Load `frame` and/or `bias_frame` from a given filename or `FITSIO.ImageHDU`. If loading from a file, you can specify the appropriate header using the `hdu` keyword,
 which can be given as an integer or a tuple (if multiple files are being loaded). All keyword arguments will be passed to the [`subtract_bias!`](@ref) function after loading the data.
"""
function subtract_bias end


"""
    subtract_bias!(frame::AbstractArray, bias_frame::FITSIO.ImageHDU)
    subtract_bias!(frame::AbstractArray, bias_frame::String; hdu = 1)

Load a FITS file or HDU for the bias frame before subtracting from `frame` in-place.
"""
function subtract_bias! end


# Code generated without codegen for FITS interface
"""
    subtract_dark(frame, dark_frame; [hdu = 1], data_exposure = 1, dark_exposure = 1)

Subtract the dark frame from `frame`. If either arguments are `FITSIO.ImageHDU` they will be loaded into memory.
If either arguments are strings we will attempt to locate a FITS file and open it before loading the data from the given `hdu`.
If loading multiple files, you can specify the HDU numbers separately (`hdu=(1, 2)`) or simultanesously (`hdu=1`).
If `data_exposure` or `dark_exposure` is a symbol it will be read from the FITS header with that key (case sensitive).
"""
function subtract_dark(frame::ImageHDU, dark_frame::AbstractArray; data_exposure = 1, kwargs...)
    data_exposure = data_exposure isa Symbol ? read_header(frame)[string(data_exposure)] : data_exposure
    return subtract_dark(getdata(frame), dark_frame; data_exposure = data_exposure, kwargs...)
end

function subtract_dark(frame::AbstractArray, dark_frame::ImageHDU; dark_exposure = 1, kwargs...)
    dark_exposure = dark_exposure isa Symbol ? read_header(dark_frame)[string(dark_exposure)] : dark_exposure
    return subtract_dark(frame, getdata(dark_frame); dark_exposure = dark_exposure, kwargs...)
end

function subtract_dark(frame::ImageHDU, dark_frame::ImageHDU; data_exposure = 1, kwargs...)
    data_exposure = data_exposure isa Symbol ? read_header(frame)[string(data_exposure)] : data_exposure
    return subtract_dark(getdata(frame), dark_frame; data_exposure = data_exposure, kwargs...)
end

subtract_dark(frame::String, dark_frame; hdu = 1, kwargs...) = subtract_dark(FITS(frame)[hdu], dark_frame; kwargs...)
subtract_dark(frame, dark_frame::String; hdu = 1, kwargs...) = subtract_dark(frame, FITS(dark_frame)[hdu]; kwargs...)

function subtract_dark(frame::String, dark_frame::String; hdu = (1, 1), kwargs...)
    hdus = hdu isa Integer ? (hdu, hdu) : hdu
    return subtract_dark(FITS(frame)[hdus[1]], FITS(frame)[hdus[2]]; kwargs...)
end


"""
    subtract_dark!(frame::AbstractArray, dark_frame::FITSIO.ImageHDU; data_exposure = 1, dark_exposure = 1)
    subtract_dark!(frame::AbstractArray, dark_frame::String; hdu = 1, data_exposure = 1, dark_exposure = 1)

Load a FITS file or HDU for the dark frame before subtracting from `frame` in-place. If `dark_exposure` is a symbol it will be parsed from the FITS header (case sensitive).
"""
function subtract_dark!(frame::AbstractArray, dark_frame::ImageHDU; dark_exposure = 1, kwargs...)
    dark_exposure = dark_exposure isa Symbol ? read_header(dark_frame)[string(dark_exposure)] : dark_exposure
    return subtract_dark!(frame, getdata(dark_frame); dark_exposure = dark_exposure, kwargs...)
end

subtract_dark!(frame::AbstractArray, dark_frame::String; hdu = 1, kwargs...) = subtract_dark!(frame, FITS(dark_frame)[hdu]; kwargs...)
