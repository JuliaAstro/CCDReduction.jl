# helper function
axes_min_length(idxs) = argmin([a isa Colon ? Inf : length(a) for a in idxs])

# parses FITS indices into standard Julian indices
function fits_indices(string::String)
    str = replace(string, r"[\[\]\s]" => "")
    tokens = split(str, ',')

    idxs = map(tokens) do token
        t = split(token, ':', keepempty=false)
        length(t) == 0 ? Colon() : parse(Int, t[1]):parse(Int, t[2])
    end
    return reverse(idxs)
end

# Convert using `round` for integers
convert_value(S::Type{<:Integer}, x) = round(S, x)
convert_value(S, x) = convert(S, x)

#-------------------------------------------------------------------------------
"""
    subtract_bias!(frame, bias_frame; [hdu = 1])

In-place version of [`subtract_bias`](@ref)

# See Also
[`subtract_bias`](@ref)
"""
function subtract_bias!(frame::AbstractArray, bias_frame::AbstractArray)
    frame .-= bias_frame
    return frame
end


"""
    subtract_bias(frame, bias_frame; [hdu = 1])

Subtract the `bias_frame` from `frame`.

If either are strings, they will be loaded into [`CCDData`](@ref) first. The HDU loaded can be specified by `hdu` as either an integer or a tuple corresponding to each file.

# Examples
```jldoctest
julia> frame = [1.0 2.2 3.3 4.5];

julia> bias = [0.0 0.2 0.3 0.5];

julia> subtract_bias(frame, bias)
1×4 Matrix{Float64}:
 1.0  2.0  3.0  4.0

```

# See Also
[`subtract_bias!`](@ref)
"""
subtract_bias(frame::AbstractArray, bias_frame::AbstractArray) = subtract_bias!(deepcopy(frame), bias_frame)


"""
    subtract_overscan!(frame, idxs; dims = axes_min_length(idxs))

In-place version of [`subtract_overscan`](@ref)

# See Also
[`subtract_overscan`](@ref)
"""
function subtract_overscan!(frame::AbstractArray{T}, idxs; dims = axes_min_length(idxs)) where T
    overscan_region = @view frame[idxs...]
    overscan_value = convert_value.(T, median(overscan_region, dims = dims))
    frame .-= overscan_value
    return frame
end

subtract_overscan!(frame::AbstractArray, idxs::String; kwargs...) = subtract_overscan!(frame, fits_indices(idxs); kwargs...)


"""
    subtract_overscan(frame, idxs; dims = axes_min_length(idxs), [hdu = 1])

Subtract the overscan frame from image.

`dims` is the dimension along which `overscan_frame` is combined. The default value
of `dims` is the axis with smaller length in overscan region. If `idxs` is a string it will be parsed as FITS-style indices.

If `frame` is a string, it will be loaded into [`CCDData`](@ref) first. The HDU loaded can be specified by `hdu` which by default is 1.

# Examples
```jldoctest
julia> frame = [4.0 2.0 3.0 1.0 1.0];

julia> subtract_overscan(frame, (:, 4:5), dims = 2)
1×5 Matrix{Float64}:
 3.0  1.0  2.0  0.0  0.0

julia> subtract_overscan(frame, "[4:5, 1:1]", dims = 2)
1×5 Matrix{Float64}:
 3.0  1.0  2.0  0.0  0.0

```

# See Also
[`subtract_overscan!`](@ref)
"""
subtract_overscan(frame, idxs; kwargs...) = subtract_overscan!(deepcopy(frame), idxs; kwargs...)


"""
    flat_correct!(frame, flat_frame; norm_value = mean(flat_frame), [hdu = 1])

In-place version of [`flat_correct`](@ref)

# See Also
[`flat_correct`](@ref)
"""
function flat_correct!(frame::AbstractArray, flat_frame::AbstractArray; norm_value = mean(flat_frame))
    norm_value <= 0 && error("norm_value must be positive")
    frame ./= (flat_frame ./ norm_value)
    return frame
end


"""
    flat_correct(frame, flat_frame; norm_value = mean(flat_frame), [hdu = 1])

Correct `frame` for non-uniformity using the calibrated `flat_frame`.

By default, the `flat_frame` is normalized by its mean, but this can be changed by providing a custom `norm_value`.

If either are strings, they will be loaded into [`CCDData`](@ref) first. The HDU loaded can be specified by `hdu` as either an integer or a tuple corresponding to each file.

!!! note
    This function may introduce non-finite values if `flat_frame` contains values very close to `0` due to dividing by zero.
    The default behavior will return `Inf` if the frame value is non-zero, and `Nan` if the frame value is `0`.

# Examples
```jldoctest
julia> frame = ones(3, 3);

julia> flat = fill(2.0, (3, 3));

julia> flat_correct(frame, flat, norm_value = 1.0)
3×3 Matrix{Float64}:
 0.5  0.5  0.5
 0.5  0.5  0.5
 0.5  0.5  0.5

julia> flat_correct(frame, flat)
3×3 Matrix{Float64}:
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0

```

# See Also
[`flat_correct!`](@ref)
"""
function flat_correct(frame::AbstractArray{T}, flat_frame::AbstractArray{S}; kwargs...) where {T, S}
    V = float(promote_type(T, S))
    return flat_correct!(V.(frame), flat_frame; kwargs...)
end


"""
    trim(frame, idxs; [hdu = 1])

Trims the `frame` to remove the region specified by idxs.

This function trims the array in a manner such that final array should be rectangular.
The indices follow standard Julia convention, so `(:, 45:60)` trims all columns from 45 to 60 and `(1:20, :)` trims all the rows from 1 to 20.
The function also supports FITS-style indices.

If `frame` is a string, it will be loaded into [`CCDData`](@ref) first. The HDU loaded can be specified by `hdu` which by default is 1.

# Examples
```jldoctest
julia> frame = ones(5, 5);

julia> trim(frame, (:, 2:5))
5×1 Matrix{Float64}:
 1.0
 1.0
 1.0
 1.0
 1.0

julia> trim(frame, "[2:5, 1:5]")
5×1 Matrix{Float64}:
 1.0
 1.0
 1.0
 1.0
 1.0

```

# See Also
[`trimview`](@ref)
"""
trim(frame, idxs) = copy(trimview(frame, idxs))


"""
    trimview(frame, idxs)

Trims the `frame` to remove the region specified by idxs.

This function is same as the [`trim`](@ref) function but returns a view of the frame.

!!! note
    This function returns a view of the frame, so any modification to output
    array will result in modification of frame.

# See Also
[`trim`](@ref)
"""
function trimview(frame::AbstractArray, idxs)
    # this adds the support for input indices of the form (1:size(frame, 1), ...) or (..., 1:size(frame, 2))
    # It converts 1:size(frame, 1) to : and then the same subroutine follows.
    processed_idxs = map(axes(frame), idxs) do a1, a2
        (a2 isa Colon || a1 == a2) ? Colon() : a2
    end

    # can switch to using `only` for Julia v1.4+
    ds = findall(x -> !isa(x, Colon), processed_idxs)
    length(ds) == 1 || error("Invalid trim indices $idxs")

    d = ds[1]
    full_idxs = axes(frame, d)
    # checking bounds error
    processed_idxs[d] ⊆ full_idxs || error("Trim indices $(idxs[d]) out of bounds for frame dimension $d $(full_idxs)")

    # finding the complement indices
    complement_idxs = setdiff(full_idxs, processed_idxs[d])

    return selectdim(frame, d, complement_idxs)
end

trimview(frame::AbstractArray, idxs::String) = trimview(frame, fits_indices(idxs))


"""
    crop(frame, shape; force_equal = true, [hdu = 1])

Crops `frame` to the size specified by `shape` anchored by the frame center.

This will remove rows/cols of the `frame` equally on each side. When there is an uneven difference in sizes (e.g. size 9 -> 6 can't be removed equally) the default is to
increase the output size (e.g. 6 -> 7) so there is equal removal on each side. To disable this, set `force_equal=false`, which will remove the extra slice from the end of the axis.

If `frame` is a string, it will be loaded into [`CCDData`](@ref) first. The HDU loaded can be specified by `hdu` which by default is 1.

# Examples
```jldoctest
julia> frame = reshape(1:25, (5, 5));

julia> crop(frame, (3, 3))
3×3 Matrix{Int64}:
 7  12  17
 8  13  18
 9  14  19

julia> crop(frame, (4, 3), force_equal = false)
4×3 Matrix{Int64}:
 6  11  16
 7  12  17
 8  13  18
 9  14  19

```

# See Also
[`cropview`](@ref)
"""
crop(frame, shape; kwargs...) = copy(cropview(frame, shape; kwargs...))


"""
    cropview(frame, shape; force_equal = true)

Crops `frame` to the size specified by `shape` anchored by the frame center.

This function is same as the [`crop`](@ref) function but returns a view of the frame.

!!! note
    This function returns a view of the frame, so any modification to output
    array will result in modification of frame.

# See Also
[`crop`](@ref)
"""
function cropview(frame::AbstractArray, shape; force_equal = true)
    # testing error
    ndims(frame) == length(shape) || error("Dimension mismatch between frame and shape")
    any(s -> !isa(s, Colon) && s < 1, shape) && error("crop size $shape cant't be less than 1")

    # generating idxs for cropped frame
    idxs = map(enumerate(size(frame)), shape) do (d, s1), s2
                diff = s2 isa Colon ? 0 : s1 - s2
                lower = iseven(diff) ? diff ÷ 2 : (diff - 1) ÷ 2
                upper = if isodd(diff) && force_equal
                            @warn "dimension $d changed from $s2 to $(s2 + 1)"
                            (diff - 1) ÷ 2
                        elseif isodd(diff)
                            (diff + 1) ÷ 2
                        else
                            diff ÷ 2
                        end
                1 + lower:s1 - upper
            end

    # returning the view
    return @view frame[idxs...]
end


"""
    combine(frames...; method = median, [hdu = 1], [header_hdu = 1])
    combine(frames; method = median, [hdu = 1], [header_hdu = 1])

Combine multiple frames using `method`. Multiple frames can also be passed in a vector or as generators for combining.

To pass a custom method, it must have a signature like `method(::AbstractArray; dims)`.

If `frames` are strings, they will be loaded into [`CCDData`](@ref)s first. The HDU indices can be specified with `hdu` as either an integer or a tuple corresponding to each file.

Header of output file (if applicable) is specified by `header_hdu` which by default is 1.

# Examples
```jldoctest
julia> frame = [reshape(1.0:4.0, (2, 2)) for i = 1:4];

julia> combine(frame)
2×2 Matrix{Float64}:
 1.0  3.0
 2.0  4.0

julia> combine(frame, method = sum)
2×2 Matrix{Float64}:
 4.0  12.0
 8.0  16.0

```
"""
function combine(frames::Vararg{<:AbstractArray{<:Number}}; method = median)
    firstframe = first(frames)
    dim = ndims(firstframe) + 1
    shape = size(firstframe)
    return reshape(method(LazyStack.stack(frames...), dims = dim), shape)
end

combine(frames; kwargs...) = combine(frames...; kwargs...)


"""
    subtract_dark!(frame, dark_frame; data_exposure = 1, dark_exposure = 1, [hdu = 1])

In-place version of [`subtract_dark`](@ref)

# See Also
[`subtract_dark`](@ref)
"""
function subtract_dark!(frame::AbstractArray, dark_frame::AbstractArray; data_exposure = 1, dark_exposure = 1)
    factor = data_exposure / dark_exposure
    @. frame -= (dark_frame * factor)
    return frame
end


"""
    subtract_dark(frame, dark_frame; data_exposure = 1, dark_exposure = 1, [hdu = 1])

Subtract the `dark_frame` from `frame`.

If either are strings, they will be loaded into [`CCDData`](@ref) first. The HDU loaded can be specified by `hdu` as either an integer or a tuple corresponding to each file.

# Examples
```jldoctest
julia> frame = ones(3, 3);

julia> dark_frame = ones(3, 3);

julia> subtract_dark(frame, dark_frame)
3×3 Matrix{Float64}:
 0.0  0.0  0.0
 0.0  0.0  0.0
 0.0  0.0  0.0

julia> subtract_dark(frame, dark_frame, data_exposure = 1, dark_exposure = 4)
3×3 Matrix{Float64}:
 0.75  0.75  0.75
 0.75  0.75  0.75
 0.75  0.75  0.75

```

# See Also
[`subtract_dark!`](@ref)
"""
function subtract_dark(frame::AbstractArray{T}, dark_frame::AbstractArray{S}; kwargs...) where {T, S}
    V = float(promote_type(T, S))
    return subtract_dark!(V.(frame), dark_frame; kwargs...)
end
