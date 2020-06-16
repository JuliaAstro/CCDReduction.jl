using CCDReduction: getdata

@testset "bias subtraction(FITS)" begin
    # setting initial data
    hdu_frame = M6707HH[1]
    hdu_bias_frame = M6707HH[1]
    array_frame = read(hdu_frame)'
    array_bias_frame = read(hdu_bias_frame)'
    string_bias_frame = test_file_path_M6707HH
    string_frame = test_file_path_M6707HH

    # non-mutating version
    @test subtract_bias(array_frame, array_bias_frame) == zeros(1059, 1059) # Testing Array Array case
    @test subtract_bias(hdu_frame, hdu_bias_frame) == zeros(1059, 1059) # testing ImageHDU ImageHDU case
    @test subtract_bias(array_frame, hdu_bias_frame) == zeros(1059, 1059) # testing Array ImageHDU case
    @test subtract_bias(hdu_frame, array_bias_frame) == zeros(1059, 1059) # testing ImageHDU Array case
    @test subtract_bias(string_frame, array_bias_frame) == zeros(1059, 1059) # testing String Array case
    @test subtract_bias(array_frame, string_bias_frame) == zeros(1059, 1059) # testing Array String case
    @test subtract_bias(string_frame, hdu_bias_frame) == zeros(1059, 1059) # testing String ImageHDU case
    @test subtract_bias(hdu_frame, string_bias_frame) == zeros(1059, 1059) # testing ImageHDU String case
    @test subtract_bias(string_frame, string_bias_frame) == zeros(1059, 1059) # testing String String case

    # mutating version
    frame = read(hdu_frame)'
    @inferred subtract_bias!(frame, string_bias_frame)
    @test frame == zeros(1059, 1059) # testing Array String case

    frame = read(hdu_frame)'
    @inferred subtract_bias!(frame, hdu_bias_frame)
    @test frame == zeros(1059, 1059) # testing Array ImageHDU case
end

@testset "overscan subtraction(FITS)" begin
    # setting initial data
    hdu = M6707HH[1]
    data = read(hdu)'

    # testing non-mutating version
    @test subtract_overscan(data, (:, 1050:1059)) == subtract_overscan(test_file_path_M6707HH, (:, 1050:1059))
    @test subtract_overscan(data, (:, 1050:1059)) == subtract_overscan(test_file_path_M6707HH, "1050:1059, 1:1059")
    @test subtract_overscan(data, (:, 1050:1059)) == subtract_overscan(hdu, "1050:1059, 1:1059")
    @test subtract_overscan(data, (1050:1059, :)) == subtract_overscan(hdu, "1:1059, 1050:1059")

end

@testset "flat correction(FITS)" begin
    # setting initial data
    hdu_frame = M6707HH[1]
    hdu_flat_frame = M6707HH[1]
    array_frame = read(hdu_frame)'
    array_flat_frame = read(hdu_flat_frame)'
    string_flat_frame = test_file_path_M6707HH
    string_frame = test_file_path_M6707HH
    mean_flat_frame = mean(array_flat_frame)

    # testing non mutating version
    @test flat_correct(array_frame, array_flat_frame) ≈ fill(mean_flat_frame, 1059, 1059) # Testing Array Array case
    @test flat_correct(hdu_frame, hdu_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing ImageHDU ImageHDU case
    @test flat_correct(array_frame, hdu_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing Array ImageHDU case
    @test flat_correct(hdu_frame, array_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing ImageHDU Array case
    @test flat_correct(string_frame, array_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing String Array case
    @test flat_correct(array_frame, string_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing Array String case
    @test flat_correct(string_frame, hdu_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing String ImageHDU case
    @test flat_correct(hdu_frame, string_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing ImageHDU String case
    @test flat_correct(string_frame, string_flat_frame; norm_value = 1) ≈ ones(1059, 1059) # testing String String case

    # testing mutating version
    frame = read(hdu_frame)'
    @test_throws InexactError flat_correct!(frame, string_flat_frame) # errors due to type mutation

    frame = read(hdu_frame)'
    @test_throws InexactError flat_correct!(frame, hdu_flat_frame) # errors due to type mutation
end


@testset "trim(FITS)" begin
    # setting initial data
    hdu = M6707HH[1]
    data = read(hdu)'

    # testing non-mutating version
    @test trim(data, (:, 1050:1059)) == trim(test_file_path_M6707HH, (:, 1050:1059))
    @test trim(data, (:, 1050:1059)) == trim(test_file_path_M6707HH, "1050:1059, 1:1059")
    @test trim(data, (:, 1050:1059)) == trim(hdu, "1050:1059, 1:1059")
    @test trim(data, (1050:1059, :)) == trim(hdu, "1:1059, 1050:1059")
end

@testset "cropping(FITS)" begin
    # setting initial data
    hdu = M6707HH[1]
    data = read(hdu)'

    # testing non-mutating version
    @test crop(data, (:, 5)) == crop(hdu, (:, 5))
    @test crop(data, (1000, 5); force_equal = false) == crop(hdu, (1000, 5); force_equal = false)
    @test_logs (:warn, "dimension 1 changed from 348 to 349") (:warn, "dimension 2 changed from 226 to 227") (:warn, "dimension 1 changed from 348 to 349") (:warn, "dimension 2 changed from 226 to 227") @test crop(data, (348, 226)) == crop(test_file_path_M6707HH, (348, 226))
    @test crop(data, (348, 226); force_equal = false) == crop(test_file_path_M6707HH, (348, 226); force_equal = false)
end


@testset "combine(FITS)" begin
    # setting initial data
    frame = M6707HH[1] |> getdata
    vector_hdu = [M6707HH[1] for i in 1:3]
    vector_frames = [frame for i in 1:3]
    vector_frames_dir = [test_file_path_M6707HH for i in 1:3]

    # testing the vector version
    @test combine(vector_hdu) == combine(vector_frames)
    @test combine(vector_frames_dir) == combine(vector_frames)

    # testing the varargs version
    @test combine(M6707HH[1], M6707HH[1], M6707HH[1]) == combine(vector_frames)
    @test combine(test_file_path_M6707HH, test_file_path_M6707HH, test_file_path_M6707HH) == combine(vector_frames)
end


@testset "dark subtraction(FITS)" begin
    # setting initial data
    hdu_frame = M6707HH[1]
    hdu_bias_frame = M6707HH[1]
    array_frame = read(hdu_frame)'
    array_bias_frame = read(hdu_bias_frame)'
    string_bias_frame = test_file_path_M6707HH
    string_frame = test_file_path_M6707HH

    # testing non-mutating version
    @test subtract_dark(array_frame, array_bias_frame; dark_exposure = 0.5) == (-1).* array_frame # testing Array Array case
    @test subtract_dark(array_frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing Array ImageHDU case
    @test subtract_dark(hdu_frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing ImageHDU ImageHDU case
    @test subtract_dark(hdu_frame, array_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing ImageHDU Array case
    @test subtract_dark(array_frame, string_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing Array String case
    @test subtract_dark(string_frame, array_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing String Array case
    @test subtract_dark(string_frame, string_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testsing String String case
    @test subtract_dark(string_frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing String ImageHDU case
    @test subtract_dark(hdu_frame, string_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing ImageHDU String case

    # testing with Symbols
    @test subtract_dark(hdu_frame, hdu_bias_frame; data_exposure = :EXPOSURE, dark_exposure = :EXPOSURE) == zeros(1059, 1059)
    @test subtract_dark(string_frame, string_bias_frame; data_exposure = :EXPOSURE, dark_exposure = :EXPOSURE) == zeros(1059, 1059)
    @test subtract_dark(array_frame, hdu_bias_frame; dark_exposure = :EXPOSURE) ≈ (49 / 50) .* array_frame

    #testing mutating version
    frame = read(hdu_frame)'
    subtract_dark!(frame, string_bias_frame; hdu = 1, data_exposure = 1, dark_exposure = 1)
    @test frame == zeros(1059, 1059) # testing Array String Case

    frame = read(hdu_frame)'
    subtract_dark!(frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2)
    @test frame == zeros(1059, 1059)
end

@testset "helper(FITS)" begin
    # testing getdata
    hdu = M6707HH[1]
    data = read(hdu)'
    @test data == getdata(hdu)
end
