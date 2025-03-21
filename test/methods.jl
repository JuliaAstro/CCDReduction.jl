using CCDReduction: axes_min_length, fits_indices, convert_value

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
    @test @inferred(subtract_overscan(ones(500, 600), "[:, 1:2]")) == zeros(500, 600)

    # testing mutating version
    frame = ones(500, 600)
    frame1 = ones(500, 600)
    @inferred subtract_overscan!(frame, (:, 540:600))
    @inferred subtract_overscan!(frame1, "[540:600, :]")
    @test frame == zeros(500, 600)
    @test frame == frame1

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
    @test trim(reshape(1:25, 5, 5), (:, 4:5)) == [1:5 6:10 11:15]
    @test trim(reshape(1:25, 5, 5), (1:2, :)) == [3:5 8:10 13:15 18:20 23:25]
    @test trim(reshape(1:25, 5, 5), "[4:5, :]") == trimview(reshape(1:25, 5, 5), (:, 4:5))
    @test trim(reshape(1:25, 5, 5), "[:, 4:5]") == trimview(reshape(1:25, 5, 5), (4:5, :))
    @test trim(reshape(1:25, 5, 5), "[1:5, 4:5]") == trimview(reshape(1:25, 5, 5), (4:5, :))
    @test trim(reshape(1:25, 5, 5), "[4:5, 1:5]") == trimview(reshape(1:25, 5, 5), (:, 4:5))

    # testing output types
    @test trimview(ones(5, 5), (:, 3:5)) isa SubArray
    @test trim(ones(5, 5), (:, 3:5)) isa Array

    # testing errors
    @test_throws ErrorException trim(ones(5, 5), (4:5, 1:4))
    @test_throws ErrorException trim(ones(5, 5), (:, :))
    @test_throws ErrorException trim(ones(5, 5), (4:6, :))
end

@testset "cropping" begin
    # testing on odd dimension array
    x = reshape(1:25, (5, 5))

    @test crop(x, (3, 3)) == [7:9 12:14 17:19]
    @test_logs (:warn, "dimension 1 changed from 4 to 5") @test crop(x, (4, 3)) == [6:10 11:15 16:20]
    @test crop(x, (4, 3), force_equal = false) == [6:9 11:14 16:19]
    @test crop(x, (1, 1)) == fill(13, (1, 1))
    @test_logs (:warn, "dimension 2 changed from 4 to 5") @test crop(x, (3, 4)) == [2:4 7:9 12:14 17:19 22:24]
    @test crop(x, (3, 4), force_equal = false) == [2:4 7:9 12:14 17:19]

    # testing on even dimension array
    x = reshape(1:16, (4, 4))

    @test cropview(x, (2, 2))  == [6:7 10:11]
    @test_logs (:warn, "dimension 1 changed from 3 to 4") @test cropview(x, (3, 2)) == [5:8 9:12]
    @test cropview(x, (3, 2), force_equal = false) == [5:7 9:11]
    @test cropview(x, (1, 1), force_equal = false) == fill(6, (1, 1))
    @test_logs (:warn, "dimension 2 changed from 3 to 4") @test cropview(x, (2, 3)) == [2:3 6:7 10:11 14:15]
    @test cropview(x, (2, 3), force_equal = false) == [2:3 6:7 10:11]

    # testing with colon
    x = reshape(1:25, (5, 5))

    @test cropview(x, (:, :)) == x
    @test cropview(x, (:, 3)) == [6:10 11:15 16:20]
    @test cropview(x, (3, :)) == [2:4 7:9 12:14 17:19 22:24]
    @test_logs (:warn, "dimension 1 changed from 2 to 3") @test cropview(x, (2, :)) == [2:4 7:9 12:14 17:19 22:24]
    @test cropview(x, (2, :), force_equal = false) == [2:3 7:8 12:13 17:18 22:23]
    @test_logs (:warn, "dimension 2 changed from 2 to 3") @test cropview(x, (:, 2)) == [6:10 11:15 16:20]
    @test cropview(x, (:, 2), force_equal = false) == [6:10 11:15]

    # testing output types
    @test cropview(ones(5, 5), (3, 3)) isa SubArray
    @test crop(ones(5, 5), (3, 3)) isa Array

    # testing error
    @test_throws BoundsError       cropview(ones(5, 5), (7, 3))
    @test_throws ErrorException    cropview(ones(5, 5), (3, -5))
    @test_throws DimensionMismatch cropview(ones(5, 5), (3, 4, 5))
end

@testset "combining" begin
    x = [reshape(1:4, (2,2)) for i = 1:10]

    @test combine(x) == [1:2 3:4]
    @test combine(x, method = sum) == [1:2 3:4] .* 10

    # testing error
    @test_throws DimensionMismatch combine(rand(5, 5), rand(6, 6))
    @test_throws MethodError combine()
end

@testset "dark subtraction" begin
    # testing non-mutating version
    @test @inferred(subtract_dark(ones(5, 5), ones(5, 5))) == zeros(5, 5)
    @test @inferred(subtract_dark(ones(5, 5), ones(5, 5), data_exposure = 1, dark_exposure = 4)) == fill(0.75, 5, 5)
    @test @inferred(subtract_dark(ones(Float32, 5, 5), ones(Float32, 5, 5), data_exposure = 13, dark_exposure = 17)) ≈ fill(Float32(4/17), 5, 5)

    # testing mutating version
    frame = ones(5, 5)
    dark_frame = ones(5, 5)
    @inferred(subtract_dark!(frame, dark_frame))
    @test frame == zeros(5, 5)

    frame = fill(5.0, 5, 5)
    dark_frame = ones(5, 5)
    @inferred(subtract_dark!(frame, dark_frame, data_exposure = 2, dark_exposure = 1))
    @test frame  == fill(3.0, 5, 5)

    frame = fill(Float32(3), 5, 5)
    dark_frame = fill(Float32(2), 5, 5)
    @inferred(subtract_dark!(frame, dark_frame, data_exposure = 11, dark_exposure = 19))
    @test frame ≈ fill(Float32(35/19), 5, 5)

    # testing error
    @test_throws DimensionMismatch subtract_dark!(ones(5,5), ones(6,6))
end

@testset "helper" begin
    # testing axes_min_length
    @test axes_min_length((:, :)) == 1
    @test axes_min_length((:, 5:10)) == 2
    @test axes_min_length((1:2, :)) == 1
    @test axes_min_length((1:2, 5:12)) == 1
    @test axes_min_length((10:100, 1:5)) == 2

    # testing fits_indices
    @test fits_indices("[1024:2048, 200:300]") == [200:300, 1024:2048]
    @test fits_indices("[:, 200:300]") == [200:300, :]
    @test fits_indices("[1024:2048, :]") == [:, 1024:2048]
    @test fits_indices("[200:300, 1024:2048]") == [1024:2048, 200:300]

    # testing convert_value
    @test convert_value(Int16, 5.4) == 5
    @test convert_value(Int32, 5.4) == 5
    @test convert_value(Int64, -5.4) == -5
    @test convert_value(Float64, -5.4) ≈ -5.4
    @test convert_value(Float32, -5.4) ≈ -5.4
    @test convert_value(Float32, -5.4) ≈ -5.4
end
