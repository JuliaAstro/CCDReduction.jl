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

!!! note
    The dimesions of `frame` and `bias_frame` should be identical.

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

# Example
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
