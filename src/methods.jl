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
