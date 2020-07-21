# custom data type to hold ImageHDU
abstract type AbstractCCDData{T} <: AbstractMatrix{T} end

struct CCDData{T,M<:AbstractMatrix{T}} <: AbstractCCDData{T}
    data::M
    hdr::FITSHeader
end

# extending the AbstractMatrix interface
Base.size(ccd::CCDData) = size(A.data)
Base.getindex(ccd::CCDData, inds...) = getindex(ccd.data, inds...) # default fallback for operations on Array
Base.setindex!(ccd::CCDData, v, inds...) = setindex!(ccd.data, v, inds...) # default fallback for operations on Array
Base.eachindex(ccd::CCDData) = eachindex(ccd.data)
Base.iterate(ccd::CCDData) = iterate(ccd.data)
Base.iterate(ccd::CCDData, state) = iterate(ccd.data, state)
Base.length(ccd::CCDData) = length(ccd.data)
Base.axes(ccd::CCDData) = axes(ccd.data)
Base.IndexStyle(::CCDData) = IndexCartesian()

CCDData(hdu::ImageHDU) = CCDData(getdata(hdu), read_header(hdu))
