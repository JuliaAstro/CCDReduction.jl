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
    @test overscan_subtraction(ones(500, 600), (1:2, 600), dims = 1) == zeros(500, 600)

    # testing mutating version
    frame = ones(500, 600)
    overscan_subtraction!(frame, (:, 540:600), dims = 2)
    @test frame == zeros(500, 600)
end
