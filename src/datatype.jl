# custom data tyoe to hold ImageHDU
struct CCDData{T,M<:AbstractMatrix{T}} <: AbstractMatrix{T}
    data::M
    hdr::FITSHeader
end

# extending the AbstractMatrix interface
Base.size(A::CCDData) = size(A.data)
Base.getindex(A::CCDData, i) = getindex(A.data, i)
Base.setindex!(A::CCDData, v, i) = setindex!(A.data, v, i)
Base.eachindex(A::CCDData) = eachindex(A.data)
Base.iterate(A::CCDData) = iterate(A.data, state=(eachindex(A),))
Base.length(A::CCDData) = length(A.data)
Base.axes(A::CCDData) = axes(A.data)
Base.IndexStyle(::CCDData) = IndexCartesian()

read_hdu(hdu::ImageHDU) = CCDData(getdata(hdu), read_header(hdu))


# defining basic functions on CCDData
# subtract_bias
function subtract_bias!(frame::CCDData, bias_frame::CCDData)
    subtract_bias!(frame.data, bias.data)
    return frame
end

subtract_bias(frame::CCDData, bias_frame::CCDData) = subtract_bias!(deepcopy(frame), bias_frame)


# subtract_overscan
function subtract_overscan!(frame::CCDData, idxs; kwargs...)
    subtract_overscan!(frame.data, idxs; kwargs...)
    return frame
end
subtract_overscan!(frame::CCDData, key::Symbol; kwargs...) = subtract_overscan!(frame, frame.header[string(key)]; kwargs...)
subtract_overscan(frame::CCDData, idxs; kwargs...) = subtract_overscan!(deepcopy(frame), idxs; kwargs...)
