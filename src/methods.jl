# helper function
axes_min_length(idxs) = argmin([a isa Colon ? Inf : length(a) for a in idxs])

#-------------------------------------------------------------------------------
"""
    subtract_bias!(frame::AbstractArray, bias_frame::AbstractArray)

In-place version of [`subtract_bias`](@ref)
"""
function subtract_bias!(frame::AbstractArray, bias_frame::AbstractArray)
    frame .-= bias_frame
    return frame
end


"""
    subtract_bias(frame::AbstractArray, bias_frame::AbstractArray)

Subtract the bias frame from image.

# Examples
```jldoctest
julia> frame = [1.0 2.2 3.3 4.5];

julia> bias = [0.0 0.2 0.3 0.5];

julia> subtract_bias(frame, bias)
1×4 Array{Float64,2}:
 1.0  2.0  3.0  4.0

```

# See Also
* [`subtract_bias!`](@ref)
"""
subtract_bias(frame::AbstractArray, bias_frame::AbstractArray) = subtract_bias!(deepcopy(frame), bias_frame)


"""
    subtract_overscan(frame::AbstractArray, idxs; dims = axes_min_length(idxs))

In-place version of [`subtract_overscan`](@ref)
"""
function subtract_overscan!(frame::AbstractArray, idxs; dims = axes_min_length(idxs))
    overscan_region = @view frame[idxs...]
    overscan_value = median(overscan_region, dims = dims)
    frame .-= overscan_value
    return frame
end


"""
    subtract_overscan!(frame::AbstractArray, idxs; dims = axes_min_length(idxs))

Subtract the overscan frame from image.

`dims` is the dimension along which `overscan_frame` is combined. The default value
of `dims` is the axis with smaller length in overscan region.

# Examples
```jldoctest
julia> frame = [4.0 2.0 3.0 1.0 1.0];

julia> subtract_overscan(frame, (:, 4:5), dims = 2)
1×5 Array{Float64,2}:
 3.0  1.0  2.0  0.0  0.0

```

# See Also
* [`subtract_overscan!`](@ref)
"""
subtract_overscan(frame::AbstractArray, idxs; dims = axes_min_length(idxs)) = subtract_overscan!(deepcopy(frame), idxs, dims = dims)


"""
    flat_correct!(frame::AbstractArray, flat_frame::AbstractArray; norm_value = mean(flat_frame))

In-place version of [`flat_correct`](@ref)
"""
function flat_correct!(frame::AbstractArray, flat_frame::AbstractArray; norm_value = mean(flat_frame))
    norm_value <= 0 && error("norm_value must be positive")
    frame ./= (flat_frame ./ norm_value)
    return frame
end


"""
    flat_correct(frame::AbstractArray, flat_frame::AbstractArray; norm_value = mean(flat_frame))

Correct `frame` for non-uniformity using the calibrated `flat_frame`.

By default, the `flat_frame` is normalized by its mean, but this can be changed by providing a custom `norm_value`.

!!! note
    This function may introduce non-finite values if `flat_frame` contains values very close to `0` due to dividing by zero.
    The default behavior will return `Inf` if the frame value is non-zero, and `Nan` if the frame value is `0`.

# Examples
```jldoctest
julia> frame = ones(3, 3);

julia> flat = fill(2.0, (3, 3));

julia> flat_correct(frame, flat, norm_value = 1.0)
3×3 Array{Float64,2}:
 0.5  0.5  0.5
 0.5  0.5  0.5
 0.5  0.5  0.5

julia> flat_correct(frame, flat)
3×3 Array{Float64,2}:
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0

```

# See Also
* [`flat_correct!`](@ref)
"""
flat_correct(frame::AbstractArray, flat_frame::AbstractArray; kwargs...) = flat_correct!(deepcopy(frame), flat_frame; kwargs...)


"""
    trim(frame::AbstractArray, idxs)

Trims the frame to remove the region specified by idxs.

This function trims the array in a manner such that final array should be rectangular.
The indices follow standard Julia convention, so `(:, 45:60)` trims all columns from 45 to 60 and `(1:20, :)` trims all the rows from 1 to 20.

# Examples
```jldoctest
julia> frame = ones(5, 5);

julia> trim(frame, (:, 2:5))
5×1 Array{Float64,2}:
 1.0
 1.0
 1.0
 1.0
 1.0

```

# See Also
* [`trimview`](@ref)
"""
trim(frame::AbstractArray, idxs) = copy(trimview(frame, idxs))


"""
    trimview(frame::AbstractArray, idxs)

Trims the frame to remove the region specified by idxs.

This function is same as the [`trim`](@ref) function but returns a view of the frame.

!!! note
    This function returns a view of the frame, so any modification to output
    array will result in modification of frame.

# See Also
* [`trim`](@ref)
"""
function trimview(frame::AbstractArray, idxs)
    # can switch to using `only` for Julia v1.4+
    ds = findall(x -> !isa(x, Colon), idxs)
    length(ds) == 1 || error("Invalid trim indices $idxs")

    d = ds[1]
    full_idxs = axes(frame, d)
    # checking bounds error
    idxs[d] ⊆ full_idxs || error("Trim indices $(idxs[d]) out of bounds for frame dimension $d $(full_idxs)")

    # finding the complement indices
    complement_idxs = setdiff(full_idxs, idxs[d])

    return selectdim(frame, d, complement_idxs)
end


"""
    crop(frame::AbstractArray, shape; force_equal = true)

Crops the image to the shape specified asumming center as the anchor.

Shape speficies the size of the cropped array, force_equal when set to true forces the cropped rows and columns to be equal on both sides
otherwise the cropped frame contains one extra column on left and one extra row on top if necessary.

# Examples
```jldoctest
julia> frame = reshape(1:25, (5, 5));

julia> crop(frame, (3, 3))
3×3 Array{Int64,2}:
 7  12  17
 8  13  18
 9  14  19

```

# See Also
* [`cropview`](@ref)
"""
crop(frame::AbstractArray, shape; kwargs...) = copy(cropview(frame, shape; kwargs...))


"""
    cropview(frame::AbstractArray, shape; force_equal = true)

Crops the image to the shape specified asumming center as the anchor.

This function is same as the [`crop`](@ref) function but returns a view of the frame.

!!! note
    This function returns a view of the frame, so any modification to output
    array will result in modification of frame.

# See Also
* [`crop`](@ref)
"""
function cropview(frame::AbstractArray, shape; force_equal = true)
    shape_diff = size(frame) .- shape

    # testing error
    any(s -> s < 0, shape_diff) && error("crop size ($shape) can't be larger than frame size ($(size(frame)))")
    any(s -> s < 0, shape) && error("crop size ($shape) cant't be negative")

    # calculating range of cropped frame
    range = []
    for i = 1:2
        strip = size(frame, i)
        if iseven(shape_diff[i])
            push!(range, 1 + shape_diff[i] ÷ 2 : strip - shape_diff[i] ÷ 2)
        else
            if force_equal
                @warn "Shape was increased to keep equal trim size"
                push!(range, 1 + (shape_diff[i] - 1) ÷ 2 : strip - (shape_diff[i] - 1) ÷ 2)
            else
                push!(range, 1 + (shape_diff[i] - 1) ÷ 2 : strip - (shape_diff[i] + 1) ÷ 2)
            end
        end
    end

    # returning the view
    return @view frame[range[1], range[2]]
end
