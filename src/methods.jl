# helper function
axes_min_length(idxs) = argmin([a isa Colon ? Inf : length(a) for a in idxs])

#-------------------------------------------------------------------------------
"""
    subtract_bias!(frame::AbstractArray, bias_frame::AbstractArray)

In place version of [`subtract_bias`](@ref)
"""
function subtract_bias!(frame::AbstractArray, bias_frame::AbstractArray)
    size(frame) != size(bias_frame) && error("size of frame and bias_frame are not same")
    for i in eachindex(frame)
        @inbounds frame[i] = frame[i] - bias_frame[i]
    end
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

In place version of [`subtract_overscan`](@ref)
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
    flat_correct!(frame::AbstractArray, flat_frame::AbstractArray; min_value = nothing, norm_value = nothing)

In place version of [`flat_correct`](@ref)
"""
function flat_correct!(frame::AbstractArray, flat_frame::AbstractArray; min_value = nothing, norm_value = nothing)
    size(frame) != size(flat_frame) && error("size of frame and flat frame are not same")
    !(norm_value === nothing) && norm_value < 0 && error("norm_value must be greater than 0")

    !(min_value === nothing) && @. flat_frame[flat_frame < min_value] = min_value

    if !(norm_value === nothing)
        flat_frame ./= norm_value
    else
        flat_frame ./= mean(flat_frame)
    end

    frame ./= flat_frame
    return frame
end


"""
    flat_correct(frame::AbstractArray, flat_frame::AbstractArray; min_value = nothing, norm_value = nothing)

Correct `frame` for non-uniformity using the calibrated `flat_frame`.

`min_value` is minimum value of `flat_frame`, an entry less than `min_value` is converted to `min_value` in `flat_frame`.
`norm_value` is normalising constant for `flat_frame`, if set to `nothing` then `mean` of `flat_frame` is used for normalising.

!!! note
    The function [`flat_correct`](@ref) has a division step of `frame` by `flat_frame`, if `flat_frame` has a zero entry then
    the returned value is either `Inf` (dividend `frame` element is non-zero) or `NaN` (dividend `frame` element is zero).

# Examples
```jldoctest
julia> frame = ones(3, 3);

julia> flat = fill(2.0, (3, 3));

julia> flat_correct(frame, flat, min_value = 3.0, norm_value = 6.0)
3×3 Array{Float64,2}:
 2.0  2.0  2.0
 2.0  2.0  2.0
 2.0  2.0  2.0

julia> flat_correct(frame, flat)
3×3 Array{Float64,2}:
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0

```

# See Also
* [`flat_correct!`](@ref)
"""
flat_correct(frame::AbstractArray, flat_frame::AbstractArray; min_value = nothing, norm_value = nothing) = flat_correct!(deepcopy(frame), flat_frame, min_value = min_value, norm_value = norm_value)
