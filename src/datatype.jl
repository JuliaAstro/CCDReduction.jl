# custom data type to hold ImageHDU
abstract type AbstractCCDData{T} <: AbstractMatrix{T} end

struct CCDData{T,M<:AbstractMatrix{T}} <: AbstractCCDData{T}
    data::M
    hdr::FITSHeader
end

CCDData(hdu::ImageHDU) = CCDData(getdata(hdu), read_header(hdu))

# extending the AbstractMatrix interface
Base.size(ccd::CCDData) = size(ccd.data)
Base.getindex(ccd::CCDData, inds...) = getindex(ccd.data, inds...) # default fallback for operations on Array
Base.setindex!(ccd::CCDData, v, inds...) = setindex!(ccd.data, v, inds...) # default fallback for operations on Array

# broadcast mechanics
Base.BroadcastStyle(::Type{<:CCDData}) = Broadcast.ArrayStyle{CCDData}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{CCDData}}, ::Type{T}) where T
    ccd = find_ccd(bc)
    CCDData(similar(ccd.data, T, axes(bc)))
end
"`A = find_ccd(As)` returns the first CCDData among the arguments."
find_ccd(bc::Base.Broadcast.Broadcasted) = find_ccd(bc.args)
find_ccd(args::Tuple) = find_ccd(find_ccd(args[1]), Base.tail(args))
find_ccd(x) = x
find_ccd(::Tuple{}) = nothing
find_ccd(a::CCDData, rest) = a
find_ccd(::Any, rest) = find_ccd(rest)
