@testset "bias subtraction" begin
    # testing non-mutating version
    @test @inferred bias_subtraction(ones(500, 500), ones(500, 500)) == zeros(500, 500)

    # testing mutating version
    frame = ones(500, 500)
    bias = ones(500, 500)
    @inferred bias_subtraction!(frame, bias)
    @test frame == zeros(500, 500)

    # testing error
    @test_throws ErrorException bias_subtraction(ones(500, 1), ones(500, 500))
end
