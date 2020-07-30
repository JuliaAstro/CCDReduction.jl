# abstract data type for CCDData
"""
    AbstractCCDData{T}

Supertype for `CCDData` based on `AbstractMatrix` interface.
"""
abstract type AbstractCCDData{T} <: AbstractMatrix{T} end

# custom data type to hold ImageHDU
"""
    CCDData(data::AbstractMatrix, hdr::FITSHeader)

Struct to store `ImageHDU`, derived from [`AbstractCCDData`](@ref).
"""
struct CCDData{T,M<:AbstractMatrix{T}} <: AbstractCCDData{T}
    data::M
    hdr::FITSHeader
end

"""
    CCDData(hdu::ImageHDU)

Loads `ImageHDU` as `CCDData`.
"""
CCDData(hdu::ImageHDU) = CCDData(getdata(hdu), read_header(hdu))

"""
    CCDData(data::AbstractArray)

Creates `CCDData` from an `Array`.
"""
CCDData(data) = CCDData(data, get_default_header(data))

"""
    CCDData(path::String, hdu)

Loads HDU from `hdu` index in `FITS` file at `path` as `CCDData`.
"""
function CCDData(path::String, hdu)
    fh = FITS(path)
    ccd = CCDData(fh[hdu])
    close(fh)
    return ccd
end
CCDData{T}(data, hdr) where {T<:Number} = CCDData(T.(data), hdr)

# extending the AbstractMatrix interface
Base.size(ccd::CCDData) = size(ccd.data)
Base.getindex(ccd::CCDData, inds...) = getindex(ccd.data, inds...) # default fallback for operations on Array
Base.setindex!(ccd::CCDData, v, inds...) = setindex!(ccd.data, v, inds...) # default fallback for operations on Array
Base.promote_rule(::Type{CCDData{T}}, ::Type{CCDData{V}}) where {T,V} = CCDData{promote_type{T,V}}
Base.convert(::Type{CCDData{T}}, ccd::CCDData{V}) where {T,V} = CCDData{T}(ccd.data, ccd.hdr)
Base.view(ccd::CCDData, inds...) = CCDData(view(ccd.data, inds...), ccd.hdr)
Base.selectdim(ccd::CCDData, d::Integer, idxs) = CCDData(selectdim(ccd.data, d, idxs), ccd.hdr)
Base.copy(ccd::CCDData) = CCDData(copy(ccd.data), deepcopy(ccd.hdr))

# broadcast mechanics
Base.BroadcastStyle(::Type{<:CCDData}) = Broadcast.ArrayStyle{CCDData}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{CCDData}}, ::Type{T}) where T
    ccd = find_ccd(bc)
    CCDData(similar(ccd.data, T, axes(bc)), ccd.hdr)
end
"`A = find_ccd(As)` returns the first CCDData among the arguments."
find_ccd(bc::Base.Broadcast.Broadcasted) = find_ccd(bc.args)
find_ccd(args::Tuple) = find_ccd(find_ccd(args[1]), Base.tail(args))
find_ccd(x) = x
find_ccd(::Tuple{}) = nothing
find_ccd(a::CCDData, rest) = a
find_ccd(::Any, rest) = find_ccd(rest)
