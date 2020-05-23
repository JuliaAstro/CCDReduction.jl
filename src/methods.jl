"""
    bias_subtraction!(frame::AbstractArray, bias_frame::AbstractArray)

In place version of [`bias_subtraction`](@ref)
"""
function bias_subtraction!(frame::AbstractArray, bias_frame::AbstractArray)
    if size(frame) != size(bias_frame)
        error("size of frame and bias_frame are not same")
    end
    for i in eachindex(frame)
        @inbounds frame[i] = frame[i] - bias_frame[i]
    end
    return frame
end


"""
    bias_subtraction(frame::AbstractArray, bias_frame::AbstractArray)

Subtract the bias frame from image.

!!! note
    The dimesions of `frame` and `bias_frame` should be identical.

# Examples
```jldoctest
julia> frame = [1.0 2.2 3.3 4.5];

julia> bias = [0.0 0.2 0.3 0.5];

julia> bias_subtraction(frame, bias)
1×4 Array{Float64,2}:
 1.0  2.0  3.0  4.0

```

# See Also
* [`bias_subtraction!`](@ref)
"""
bias_subtraction(frame::AbstractArray, bias_frame::AbstractArray) = bias_subtraction!(deepcopy(frame), bias_frame)


#=
***Note to future developer***
The code for overscan_subtraction is not type-stable because of splat operation.
Modern day ccds are of the dimension 4096 x 4096, so performance would not be an
issue with this code even without type-stability
=#
"""
    overscan_subtraction(frame::AbstractArray, idxs; dims = Colon())

In place version of [`overscan_subtraction`](@ref)
"""
function overscan_subtraction!(frame::AbstractArray, idxs; dims = Colon())
    overscan_region = @view frame[idxs...]
    overscan_value = median(overscan_region, dims = dims)
    return frame .-= overscan_value
end


"""
    overscan_subtraction!(frame::AbstractArray, idxs; dims = Colon())

Subtract the overscan frame from image.

`dims` is the dimension along which `overscan_frame` is combined.

# Example
```jldoctest
julia> frame = [4.0 2.0 3.0 1.0 1.0];

julia> overscan_subtraction(frame, (:, 4:5), dims = 2)
1×5 Array{Float64,2}:
 3.0  1.0  2.0  0.0  0.0

```

# See Also
* [`overscan_subtraction!`](@ref)
"""
overscan_subtraction(frame::AbstractArray, idxs; dims = Colon()) = overscan_subtraction!(deepcopy(frame), idxs, dims = dims)
