using CCDReduction: axes_min_length

@testset "bias subtraction" begin
    # testing non-mutating version
    @test @inferred(subtract_bias(ones(500, 500), ones(500, 500))) == zeros(500, 500)

    # testing mutating version
    frame = ones(500, 500)
    bias = ones(500, 500)
    @inferred subtract_bias!(frame, bias)
    @test frame == zeros(500, 500)

    # testing error
    @test_throws DimensionMismatch subtract_bias(ones(500, 1), ones(500, 500))
end

@testset "overscan subtraction" begin
    # testing non-mutating version
    @test @inferred(subtract_overscan(ones(500, 600), (1:2, :))) == zeros(500, 600)

    # testing mutating version
    frame = ones(500, 600)
    @inferred subtract_overscan!(frame, (:, 540:600))
    @test frame == zeros(500, 600)

    # testing error
    @test_throws BoundsError subtract_overscan(ones(500, 600), (500:600, :))
end

@testset "flat correction" begin
    #testing non-mutating version
    frame = ones(5, 5)
    flat = fill(2.0, (5, 5))
    @test @inferred(flat_correct(frame, flat)) == ones(5, 5)
    @test @inferred(flat_correct(frame, flat, norm_value = 4.0)) == fill(2.0, (5, 5))

    #testing mutating version
    frame = ones(5, 5)
    flat = rand(5, 5)
    reduced_flat = flat ./ mean(flat)
    reduced_frame = frame ./ reduced_flat

    @inferred flat_correct!(frame, flat)
    @test reduced_frame == frame

    #testing error
    @test_throws DimensionMismatch flat_correct(ones(5, 5), ones(5, 6))
    @test_throws ErrorException flat_correct(ones(5, 5), ones(5, 5), norm_value = -2)
end

@testset "trim" begin
    @test trim(reshape(1:25, 5, 5), (:, 4:5)) == trimview(reshape(1:25, 5, 5), (:, 4:5))
    @test trim(reshape(1:25, 5, 5), (4:5, :)) == trimview(reshape(1:25, 5, 5), (4:5, :))

    # testing output types
    @test trimview(ones(5, 5), (:, 3:5)) isa SubArray
    @test trim(ones(5, 5), (:, 3:5)) isa Array

    # testing errors
    @test_throws ErrorException trim(ones(5, 5), (4:5, 1:4))
    @test_throws ErrorException trim(ones(5, 5), (:, :))
    @test_throws ErrorException trim(ones(5, 5), (4:6, :))
end

@testset "helper" begin
    # testing axes_min_length
    @test axes_min_length((:, :)) == 1
    @test axes_min_length((:, 5:10)) == 2
    @test axes_min_length((1:2, :)) == 1
    @test axes_min_length((1:2, 5:12)) == 1
    @test axes_min_length((10:100, 1:5)) == 2
end
