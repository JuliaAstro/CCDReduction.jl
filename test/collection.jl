using CCDReduction: parse_name

@testset "fitscollection" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")

    # the two fits file used for testing have identical header keys
    df = fitscollection(dir)
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
    @test size(df) == (2, length(relevant_keys) + 3)

    # testing each element in rows and columns
    @test copy(df[1, :]) == (path = joinpath(dir, "M35070V.fits"),
                             name = "M35070V.fits", hdu = 1,
                             zip(Symbol.(relevant_keys), relevant_values_M35070V)...)
    @test copy(df[2, :]) == (path = joinpath(dir, "M6707HH.fits"),
                             name = "M6707HH.fits", hdu = 1,
                             zip(Symbol.(relevant_keys), relevant_values_M6707HH)...)

    # testing special cases
    ## drop extension
    df = fitscollection(dir; keepext = false)
    @test df[1, :name] == "M35070V"
    @test df[2, :name] == "M6707HH"

    ## exclude
    df = fitscollection(dir; exclude = "M35070V.fits")
    @test df[1, :name] == "M6707HH.fits"
    @test size(df) == (1, length(relevant_keys) + 3)

    ##exclude_dir
    df = fitscollection(dir; exclude_dir = "data")
    @test size(df) == (0, 0)
end

@testset "array-generators" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")
    df = fitscollection(dir)
    arr1 = arrays(df) |> collect
    arr2 = map(eachrow(df)) do row
        getdata(FITS(row.path)[row.hdu])
    end
    @test arr1 == arr2
end

@testset "filename-generators" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")
    df = fitscollection(dir)
    arr1 = filenames(df) |> collect
    arr2 = map(eachrow(df)) do row
        row.path
    end
    @test arr1 == arr2
end

@testset "image-generators" begin
    # setting initial data
    dir = joinpath(@__DIR__, "data")
    df = fitscollection(dir)
    arr1 = ccds(df) |> collect
    arr2 = map(eachrow(df)) do row
        CCDData(FITS(row.path)[row.hdu])
    end

    for (hdu1, hdu2) in zip(arr1, arr2)
        @test hdu1.data == hdu2.data
        test_header(hdu1, hdu2)
    end
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
    @test generate_filename("~/.julia/abcd.abcd", @__DIR__, "test1", nothing, "__", r"fits(\.tar\.gz)?"i) == joinpath(@__DIR__, "test1__abcd.abcd") # case when extension does not match

    # testing parse_filename_ext
    parse_name_ext("11.12.20_HD106754.fits.tar.gz", "." * r"fits(\.tar\.gz)?"i) == ("11.12.20_HD106754", ".fits.tar.gz")
    parse_name_ext("abcd", "." * r"fits(\.tar\.gz)?"i) ==  ("abcd", "")
    parse_name_ext("11.12.20_HD106754.fits", "." * "fits") == ("11.12.20_HD106754", ".fits")
    parse_name_ext("abcd.fits", "." * "fits") == ("abcd", ".fits")
    parse_name_ext("11.12.20_HD106754.Fits.Tar.gz", "." * r"fits(\.tar\.gz)?"i) == ("11.12.20_HD106754", ".Fits.Tar.gz")
end
