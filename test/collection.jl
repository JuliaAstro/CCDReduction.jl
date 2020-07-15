using CCDReduction: parse_name,
                    generate_filename,
                    write_data,
                    parse_name_ext

@testset "fitscollection" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")

    # the two fits file used for testing have identical header keys
    collection = fitscollection(dir)
    relevant_keys = filter(i -> i ∉ ("", "HISTORY"), keys(read_header(M6707HH[1])))

    header_M6707HH = read_header(M6707HH[1])
    relevant_values_M6707HH = map(relevant_keys) do key
        header_M6707HH[key]
    end

    header_M35070V = read_header(M35070V[1])
    relevant_values_M35070V = map(relevant_keys) do key
        header_M35070V[key]
    end
    # testing rows columns
    # an additional 3 columns are present because of varibles path, name and hdu
    @test size(collection) == (2, length(relevant_keys) + 3)

    # testing each element in rows and columns
    @test copy(collection[1, :]) == (path = joinpath(dir, "M35070V.fits"),
                             name = "M35070V.fits", hdu = 1,
                             zip(Symbol.(relevant_keys), relevant_values_M35070V)...)
    @test copy(collection[2, :]) == (path = joinpath(dir, "M6707HH.fits"),
                             name = "M6707HH.fits", hdu = 1,
                             zip(Symbol.(relevant_keys), relevant_values_M6707HH)...)

    # testing special cases
    ## drop extension
    collection = fitscollection(dir; keepext = false)
    @test collection[1, :name] == "M35070V"
    @test collection[2, :name] == "M6707HH"

    ## exclude
    collection = fitscollection(dir; exclude = "M35070V.fits")
    @test collection[1, :name] == "M6707HH.fits"
    @test size(collection) == (1, length(relevant_keys) + 3)

    ##exclude_dir
    collection = fitscollection(dir; exclude_dir = "data")
    @test size(collection) == (0, 0)
end

@testset "array-generators" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")
    collection = fitscollection(dir)
    arr1 = arrays(collection) |> collect
    arr2 = map(eachrow(collection)) do row
        getdata(FITS(row.path)[row.hdu])
    end
    @test arr1 == arr2
end

@testset "saving-arrays" begin
    dir = joinpath(@__DIR__, "data")
    savedir = @__DIR__
    collection = fitscollection(dir)

    final = arrays(collection; save = true, path = savedir, save_prefix = "test1", save_suffix = "test2") do img
        trim(img, (:, 1040:1059))
    end

    # testing function outputs
    @test final[1] == trim(M35070V[1], (:, 1040:1059))
    @test final[2] == trim(M6707HH[1], (:, 1040:1059))

    collection1 = fitscollection(savedir; recursive = false)

    # testing saved data
    @test final[1] == getdata(FITS(collection1[1, :path])[collection1[1, :hdu]])
    @test final[2] == getdata(FITS(collection1[2, :path])[collection1[2, :hdu]])

    # testing saved filenames
    @test collection1[1, :name] == "test1_M35070V_test2.fits"
    @test collection1[2, :name] == "test1_M6707HH_test2.fits"
end

@testset "filename-generators" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")
    collection = fitscollection(dir)
    arr1 = filenames(collection) |> collect
    arr2 = map(eachrow(collection)) do row
        row.path
    end
    @test arr1 == arr2
end

@testset "saving-filename" begin
    dir = joinpath(@__DIR__, "data")
    savedir = @__DIR__
    collection = fitscollection(dir)

    final = filenames(collection; save = true, path = savedir, save_prefix = "test1", save_suffix = "test2") do img
        getdata(FITS(img)[1])
    end

    # testing function outputs
    @test final[1] == getdata(M35070V[1])
    @test final[2] == getdata(M6707HH[1])

    collection1 = fitscollection(savedir; recursive = false)

    # testing saved data
    @test final[1] == getdata(FITS(collection1[1, :path])[collection1[1, :hdu]])
    @test final[2] == getdata(FITS(collection1[2, :path])[collection1[2, :hdu]])

    # testing saved filenames
    @test collection1[1, :name] == "test1_M35070V_test2.fits"
    @test collection1[2, :name] == "test1_M6707HH_test2.fits"
end

@testset "image-generators" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")
    collection = fitscollection(dir)
    arr1 = images(collection) |> collect
    arr2 = map(eachrow(collection)) do row
        FITS(row.path)[row.hdu]
    end

    for (hdu1, hdu2) in zip(arr1, arr2)
        @test getdata(hdu1) == getdata(hdu2)
        header1 = read_header(hdu1)
        header2 = read_header(hdu2)
        @test keys(header1) == keys(header2)
        for (k1, k2) in zip(keys(header1), keys(header2))
            @test header1[k1] == header2[k2]
        end
    end
end

@testset "saving-image" begin
    dir = joinpath(@__DIR__, "data")
    savedir = @__DIR__
    collection = fitscollection(dir)

    final = images(collection; save = true, path = savedir, save_prefix = "test1", save_suffix = "test2") do img
        trim(img, (:, 1040:1059))
    end

    # testing function outputs
    @test final[1] == trim(M35070V[1], (:, 1040:1059))
    @test final[2] == trim(M6707HH[1], (:, 1040:1059))

    collection1 = fitscollection(savedir; recursive = false)

    # testing saved data
    @test final[1] == getdata(FITS(collection1[1, :path])[collection1[1, :hdu]])
    @test final[2] == getdata(FITS(collection1[2, :path])[collection1[2, :hdu]])

    # testing saved filenames
    @test collection1[1, :name] == "test1_M35070V_test2.fits"
    @test collection1[2, :name] == "test1_M6707HH_test2.fits"
end

@testset "helper" begin
    # testing parse_name
    @test parse_name("abc.fits", "."*"fits", Val(true)) == "abc.fits"
    @test parse_name("abc.fits.tar.gz", "."*"fits.tar.gz", Val(false)) == "abc"
    @test parse_name("foo.fits.fits", "."*"fits", Val(false)) == "foo.fits"
    @test parse_name("foo.fits.fits", "."*r"fits(\.tar\.gz)?"i, Val(false)) == "foo.fits"
    @test parse_name("foo.fits", "."*r"fits(\.tar\.gz)?"i, Val(false)) == "foo"

    # testing generate_filename
    @test generate_filename("home/abcd.fits", @__DIR__, "test1", "test2", "_", r"fits(\.tar\.gz)?"i) == joinpath(@__DIR__, "test1_abcd_test2.fits")
    @test generate_filename("home/tek/abcd.fits", @__DIR__, nothing, "test2", "_", r"fits(\.tar\.gz)?"i) == joinpath(@__DIR__, "abcd_test2.fits")
    @test generate_filename("home/downloads/abcd.fits", @__DIR__, "test1", nothing, "_", r"fits(\.tar\.gz)?"i) == joinpath(@__DIR__, "test1_abcd.fits")
    @test generate_filename("home/hello/abcd.fits", @__DIR__, nothing, nothing, "_", r"fits(\.tar\.gz)?"i) == joinpath(@__DIR__, "abcd.fits")
    @test generate_filename("~/.julia/abcd.fits", @__DIR__, "test1", nothing, "__", r"fits(\.tar\.gz)?"i) == joinpath(@__DIR__, "test1__abcd.fits")

    # testing write_data
    filename = joinpath(@__DIR__, "test1_M6707HH_test2.fits")
    sample_data = rand(5, 10)
    write_data(filename, sample_data)
    image_array = getdata(FITS(filename)[1])
    @test image_array == sample_data

    # testing parse_filename_ext
    parse_name_ext("11.12.20_HD106754.fits.tar.gz", "." * r"fits(\.tar\.gz)?"i) == ("11.12.20_HD106754", ".fits.tar.gz")
    parse_name_ext("abcd", "." * r"fits(\.tar\.gz)?"i) ==  ("abcd", "")
    parse_name_ext("11.12.20_HD106754.fits", "." * "fits") == ("11.12.20_HD106754", ".fits")
    parse_name_ext("abcd.fits", "." * "fits") == ("abcd", ".fits")
    parse_name_ext("11.12.20_HD106754.Fits.Tar.gz", "." * r"fits(\.tar\.gz)?"i) == ("11.12.20_HD106754", ".Fits.Tar.gz")
end
