using CCDReduction: axes_min_length

@testset "bias subtraction" begin
    # testing non-mutating version
    @test @inferred(bias_subtraction(ones(500, 500), ones(500, 500))) == zeros(500, 500)

    # testing mutating version
    frame = ones(500, 500)
    bias = ones(500, 500)
    @inferred bias_subtraction!(frame, bias)
    @test frame == zeros(500, 500)

    # testing error
    @test_throws ErrorException bias_subtraction(ones(500, 1), ones(500, 500))
end

@testset "overscan subtraction" begin
    # testing non-mutating version
    @test @inferred(overscan_subtraction(ones(500, 600), (1:2, :))) == zeros(500, 600)

    # testing mutating version
    frame = ones(500, 600)
    @inferred overscan_subtraction!(frame, (:, 540:600))
    @test frame == zeros(500, 600)
end

@testset "helper" begin
    # testing axes_min_length
    @test axes_min_length((:, :)) == 1
    @test axes_min_length((:, 5:10)) == 2
    @test axes_min_length((1:2, :)) == 1
    @test axes_min_length((1:2, 5:12)) == 1
    @test axes_min_length((10:100, 1:5)) == 2
end
