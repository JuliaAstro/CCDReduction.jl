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

# See Also
* [`bias_subtraction!`](@ref)
"""
bias_subtraction(frame::AbstractArray, bias_frame::AbstractArray) = bias_subtraction!(deepcopy(frame), bias_frame)
