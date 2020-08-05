# abstract data type for CCDData
"""
    AbstractCCDData{T}

Supertype for `CCDData` based on `AbstractMatrix` interface.

Every subtype of this type should have methods `data` and `hdr` defined.
"""
abstract type AbstractCCDData{T} <: AbstractMatrix{T} end

# extending the AbstractMatrix interface
Base.size(ccd::AbstractCCDData) = size(data(ccd))
Base.getindex(ccd::AbstractCCDData, inds...) = getindex(data(ccd), inds...) # default fallback for operations on Array
Base.setindex!(ccd::AbstractCCDData, v, inds...) = setindex!(data(ccd), v, inds...) # default fallback for operations on Array
Base.getindex(ccd::AbstractCCDData, inds::AbstractString...) = getindex(hdr(ccd), inds...) # accesing header using strings
Base.setindex!(ccd::AbstractCCDData, v, inds::AbstractString...) = setindex!(hdr(ccd), v, inds...) # modifying header using strings
Base.getindex(ccd::AbstractCCDData, inds::Symbol...) = getindex(ccd, string.(inds)...) # accessing header using symbol
Base.setindex!(ccd::AbstractCCDData, v, inds::Symbol...) = setindex!(ccd, v, string.(inds)...) # modifying header using Symbol
Base.promote_rule(::Type{AbstractCCDData{T}}, ::Type{AbstractCCDData{V}}) where {T,V} = AbstractCCDData{promote_type{T,V}}

# custom data type to hold ImageHDU
"""
    CCDData(data::AbstractMatrix, [hdr::FITSHeader])

Struct to store `ImageHDU`, derived from [`AbstractCCDData`](@ref).

`CCDData` acts like a matrix with a header associated.

```julia
ccd = CCDData(zeros(4, 4))

ccd[1]
```
This accesses the 1st element in matrix associated with `ccd`.

```
ccd["SIMPLE"]
```
One can also access the header directly from `ccd`, the key can be `Symbol` as well.

```
ccd[:SIMPLE] = false
```
Header values can be directly modified from `ccd`.

One can perform arithmetic operations on it as well:

```julia
ccd1 = CCDData(zeros(4, 4))

ccd2 = CCDData(ones(4, 4))

sum_ccd1 = ccd1 + ccd2

sum_ccd2 = ccd2 + ccd1
```

`sum_ccd1` has the header of `ccd1` whereas `sum_ccd2` has the header `ccd2`.

If header is not provided in the `CCDData` constructor, `default_header` is used to generate the header.
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

CCDData(data) = CCDData(data, get_default_header(data))

"""
    CCDData(path::AbstractString; hdu = 1)

Loads HDU from `hdu` index in `FITS` file at `path` as `CCDData`.
"""
CCDData(path::AbstractString; hdu = 1) = FITS(f -> CCDData(f[hdu]), path)

CCDData{T}(data, hdr) where {T<:Number} = CCDData(T.(data), hdr)
data(ccd::CCDData) = ccd.data
hdr(ccd::CCDData) = ccd.hdr
Base.copy(ccd::CCDData) = CCDData(copy(data(ccd)), deepcopy(hdr(ccd)))
Base.convert(::Type{CCDData{T}}, ccd::CCDData{V}) where {T,V} = CCDData{T}(data(ccd), hdr(ccd))
Base.view(ccd::CCDData, inds...) = CCDData(view(data(ccd), inds...), hdr(ccd))
Base.selectdim(ccd::CCDData, d::Integer, idxs) = CCDData(selectdim(data(ccd), d, idxs), hdr(ccd))
# broadcast mechanics
Base.BroadcastStyle(::Type{<:CCDData}) = Broadcast.ArrayStyle{CCDData}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{CCDData}}, ::Type{T}) where T
    ccd = find_ccd(bc)
    CCDData(similar(data(ccd), T, axes(bc)), hdr(ccd))
end
"`A = find_ccd(As)` returns the first CCDData among the arguments."
find_ccd(bc::Base.Broadcast.Broadcasted) = find_ccd(bc.args)
find_ccd(args::Tuple) = find_ccd(find_ccd(args[1]), Base.tail(args))
find_ccd(x) = x
find_ccd(::Tuple{}) = nothing
find_ccd(a::CCDData, rest) = a
find_ccd(::Any, rest) = find_ccd(rest)
