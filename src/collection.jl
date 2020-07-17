# helper function
# parses the name and returns it with or without extension
parse_name(filename, ext::AbstractString, ::Val{false}) = first(rsplit(filename, ext, limit=2))

function parse_name(filename, ext::Regex, ::Val{false})
    idxs = findall(ext, filename)
    return filename[1:first(last(idxs)) - 1]
end

parse_name(filename, ext, ::Val{true}) = filename


# utility function for generating filename
function generate_filename(path, save_location, save_prefix, save_suffix, save_delim, ext)
    # get the filename
    filename = last(splitdir(path))

    # splitting name and extension
    modified_name, ext = parse_name_ext(filename, "." * ext)

    # adding prefix and suffix with delimiter
    if !isnothing(save_prefix)
        modified_name = string(save_prefix, save_delim, modified_name)
    end
    if !isnothing(save_suffix)
        modified_name = string(modified_name, save_delim, save_suffix)
    end

    # adding extension to modified_name
    if ext == ""
        file_path = joinpath(save_location, modified_name * ".fits")
    else
        file_path = joinpath(save_location, modified_name * ext)
    end
    return file_path
end


# utility function to return filename and extension separately
# returns extension including "." at the beginning
function parse_name_ext(filename, ext)
    idxs = findall(ext, filename)
    length(idxs) == 0 && return (filename, "")
    breaking_index = first(last(idxs))
    return filename[1:breaking_index - 1], filename[breaking_index:end]
end


#=
FITSIO.jl takes over memory write in by cfitsio, which writes in row-major form,
whereas when Julia gives that memory, it is assumed as column major.
Therefore all data written by `write` is transposed.
Related comment: https://github.com/JuliaAstro/CCDReduction.jl/pull/16#issuecomment-638492572
=#
"""
    write_data(file_path, data)

Writes `data` in FITS format at `file_path`.
"""
function write_data(file_path, data)
    d = ndims(data)
    transposed_data = permutedims(data, d:-1:1)
    FITS(file_path, "w") do fh
        write(fh, transposed_data)
    end
end

#---------------------------------------------------------------------------------------
@doc raw"""
    fitscollection(dir;
                   recursive=true,
                   abspath=true,
                   keepext=true,
                   ext=r"fits(\.tar\.gz)?",
                   exclude=nothing,
                   exclude_dir=nothing,
                   exclude_key=("", "HISTORY"))

Walk through `dir` collecting FITS files, scanning their headers, and culminating into a `DataFrame` that can be used with the generators for iterating over many files and processing them. If `recursive` is false, no subdirectories will be walked through.

The table returned will contain the path to the file, the name of the file, and index of the corresponding hdu, and each FITS header column and value. If two FITS files have distinct columns, they will both appear in the table with `missing` in the appropriate rows.

If `abspath` is true, the path in the table will be absolute. If `keepext` is true, the name in the table will include the file extension, given by `ext`. `ext` will be used with `endswith` to filter for fits files compatible with `FITSIO.FITS`. `exclude` is a pattern that can be used with `occursin` to exclude certain filenames. For example, to exclude any files containing "sky",
```julia
fitscollection(...; exclude="sky")
```
to exclude exact filenames, [regex strings](https://docs.julialang.org/en/v1/manual/strings/#Regular-Expressions-1) will prove powerful
```julia
fitscollection(...; exclude=r"^tek001\d")
```
finally, using external tools like [Glob.jl](https://github.com/vtjnash/Glob.jl) allows further customization
```julia
using Glob
fitscollection(...; exclude=fn"tek001*.fits") # same as regex match above
```
Similarly, `exclude_dir` allows excluding entire folders using pattern matching (e.g. skipping a backup folder `exclude_dir="backup"`).
`exclude_key` allows excluding certain entries in the header unit of `ImageHDU` in FITS files (e.g. skipping `"HISTORY"` and `""` `exclude_key = ("HISTORY", "")`).

For more information about the file matching and path deconstruction, see the extended help (`??fitscollection`)
# Extended Help

## Parts of a path

Let's look at some file paths starting from `"/data"`. Here are examples of how they would be parsed

```
 root  dir   base   ext
[----][---][------][---]
/data/test/tek0001.fits

 root    dir     base   ext
[----][-------][------][---]
/data/test/sci/tek0001.fits
```

If `keepext` is `true`, `name=base * ext`, otherwise it is just `base`. If `abspath` is `true`, the path will be `root * dir * base * ext`, otherwise it will be `dir * base * ext`. These options allow flexility in creating a table that can be easily saved and loaded to avoid having to manually filter files. Especially consider how `abspath` can allow keeping tables that will transfer easily between computers or between data sources with common structures.
"""
function fitscollection(basedir::String;
                        recursive = true,
                        abspath = true,
                        keepext = true,
                        ext = r"fits(\.tar\.gz)?"i,
                        exclude = nothing,
                        exclude_dir = nothing,
                        exclude_key = ("", "HISTORY"))
    collection = DataFrame()

    for (root, dirs, files) in walkdir(basedir)
        # recursive searching functionality
        recursive || root == basedir || continue
        # To exclude certain directories
        if exclude_dir !== nothing
            occursin(exclude_dir, root) && continue
        end
        for filename in files
            # accept file if .fits or .fits.tar.gz
            endswith(filename, ext) || continue
            # excluding the files specified by user
            if exclude !== nothing
                occursin(exclude, filename) && continue
            end
            location = joinpath(root, filename)
            fits_data = FITS(location)

            for (index, hdu) in enumerate(fits_data)
                hdu isa ImageHDU || continue
                header_data = read_header(hdu)
                path = abspath ? Base.abspath(location) : location
                name = parse_name(filename, "." * ext, Val(keepext))

                # filtering out comment columns
                _keys = filter(k -> k ∉ exclude_key, keys(header_data))
                _values = (header_data[k] for k in _keys)
                push!(collection, (path = path, name = name, hdu = index, zip(Symbol.(_keys), _values)...); cols = :union)
            end
            close(fits_data)
        end
    end
    return collection
end


"""
    arrays(collection::DataFrame)

Generator for arrays of images of entries in data frame.

Iterative version of `arrays`, returns data loaded by `FITSIO` using `CCDReduction.get_data` into an `Array`.
It utilizes the `path` and `hdu` from the `collection`.

This version can be used as
```julia
collection = fitscollection("~/data/tekdata")
image_arrays = arrays(collection) |> collect
```
this returns all image arrays present in `collection`. This can also be used via a for-loop
```julia
collection = fitscollection("~/data/tekdata")
processed_images = Vector{Array}(undef, first(size(collection)))
for (i, arr) in enumerate(arrays(collection))
    processed_images[i] = trim(arr, (:, 1040, 1059))
end
```

This version involving for-loop (i.e. iterative version) does not support saving functionality.
"""
function arrays end

# generator for image arrays specified by data frames (i.e. path of file, hdu etc.)
@resumable function arrays(collection::DataFrame)
    for row in eachrow(collection)
        fh = FITS(row.path)
        @yield getdata(fh[row.hdu])
        close(fh)
    end
end


"""
    filenames(collection::DataFrame)

Generator for filenames of entries in data frame.

Iterative version of `filenames`, returns file paths from data frame `collection`. It utilizes the `path` from the `collection`.

This version can be used as
```julia
collection = fitscollection("~/data/tekdata")
processed_images = Vector{Array}(undef, first(size(collection)))
for (i, path) in enumerate(filenames(collection))
    fh = FITS(path)
    processed_images[i] = subtract_overscan(fh[1], :BIASSEC) # assuming 1-hdu is an image
    close(fh)
end
```

This version involving for-loop (i.e. iterative version) does not support saving functionality.
"""
function filenames end

# generator for filenames specified by data frame (i.e. path of file, hdu etc.)
@resumable function filenames(collection::DataFrame)
    for row in eachrow(collection)
        @yield row.path
    end
end


"""
    images(collection::DataFrame)

Generator for `ImageHDU`s of entries in data frame.

Iterative version of `images`, returns data loaded by `FITSIO` using `FITSIO.FITS` into an `ImageHDU`.
It utilizes the `path` and `hdu` from the `collection`.

This version can be used as
```julia
collection = fitscollection("~/data/tekdata")
processed_images = Vector{Array}(undef, first(size(collection)))
for (i, hdu) in enumerate(images(collection))
    processed_images[i] = subtract_overscan(hdu, :BIASSEC)
end
```

The code below will not work, since all FITS files are closed after iteration.
```julia
collection = fitscollection("~/data/tekdata")
image_hdus = images(collection) |> collect
data = getdata(first(image_hdus)) # raises error because the FITS file has already been closed after iteration
```

This version involving for-loop (i.e. iterative version) does not support saving functionality.
"""
function images end

# generator for ImageHDU specified by data frame (i.e. path of file, hdu etc.)
@resumable function images(collection::DataFrame)
    files = Vector{FITS}(undef, first(size(collection)))

    for (i,row) in enumerate(eachrow(collection))
        fh = FITS(row.path)
        files[i] = fh
        @yield fh[row.hdu]
    end

    # closing all files
    close.(files)
end


"""
    images(f, collection::DataFrame; save = false, path = nothing, save_prefix = nothing, save_suffix = nothing, save_delim = "_", ext = r"fits(\\.tar\\.gz)?"i, kwargs...)

Iterates over the ImageHDUs of the collection applying function `f` at each step.

It returns an array of output values of function `f` applied on ImageHDUs. If `save = true`, it enables programmatical saving of returned value of the function `f` using `CCDReduction.write_fits`. File is saved at `path` specified by the user.
Suffix and prefix can be added to filename of newly created files by modifying `save_suffix` and `save_prefix`, `save_delim` is used as delimiter.
`ext` is the extension of files in collection, by default it is set to `r"fits(\\.tar\\.gz)?"i`.

Mapping version can be used as
```julia
collection = fitscollection("~/data/tekdata")
processed_images = map(images(collection)) do img
    trim(img, (:, 1040:1059))
end
```
The above generates `processed_images` which consists of trimmed versions of images present in `collection`.
For saving the `processed_images` simultaneously with the operations performed
```julia
processed_images = map(images(collection; save = true, path = "~/data/tekdata", save_prefix = "trimmed")) do img
    trim(img, (:, 1040:1059))
end
```
the trimmed images are saved as `trimmed_(original_name)` (FITS files) at `path = "~/data/tekdata"` as specified by the user.

Mapping version of `images` function is interfaced on iterative version of `images`, any valid parameter can be passed into iterative version as `kwargs`.
"""
function images(f, collection::DataFrame; save = false, path = nothing, save_prefix = nothing, save_suffix = nothing, save_delim = "_", ext = r"fits(\.tar\.gz)?"i, kwargs...)
    image_iterator = images(collection; kwargs...)
    locations = collection.path

    processed_images = map(zip(locations, image_iterator)) do (location, output)
        processed_image = f(output)
        if save
            save_path = generate_filename(location, path, save_prefix, save_suffix, save_delim, ext)
            write_data(save_path, processed_image)
        end
        processed_image
    end

    return processed_images
end


"""
    filenames(f, collection::DataFrame; save = false, path = nothing, save_prefix = nothing, save_suffix = nothing, save_delim = "_", ext = r"fits(\\.tar\\.gz)?"i, kwargs...)

Iterates over the file paths of the collection applying function `f` at each step.

It returns an array of output values of function `f` applied on file paths. If `save = true`, it enables programmatical saving of returned value of the function `f` using `CCDReduction.write_fits`. File is saved at `path` specified by the user.
Suffix and prefix can be added to filename of newly created files by modifying `save_suffix` and `save_prefix`, `save_delim` is used as delimiter.
`ext` is the extension of files in collection, by default it is set to `r"fits(\\.tar\\.gz)?"i`.

Mapping version can be used as
```julia
collection = fitscollection("~/data/tekdata")
processed_images = map(filenames(collection)) do path
    fh = FITS(path)
    data = getdata(fh[1]) # assuming all 1-hdu are ImageHDUs
    close(fh)
    data
end
```
The above generates `loaded_images` which consists of image arrays corresponding to 1st hdu of FITS file paths present in `collection`.
For saving the `loaded_images` simultaneously with the operations performed
```julia
loaded_images = map(filenames(collection; save = true, path = "~/data/tekdata", save_prefix = "retrieved_from_filename")) do img
    fh = FITS(path)
    data = getdata(fh[1]) # assuming all 1-hdu are ImageHDUs
    close(fh)
    data
end
```
the retrieved data is saved as `retrieved_from_filename_(original_name)` (FITS files) at `path = "~/data/tekdata"` as specified by the user.

Mapping version of `filenames` function is interfaced on iterative version of `filenames`, any valid parameter can be passed into iterative version as `kwargs`.
"""
function filenames(f, collection::DataFrame; save = false, path = nothing, save_prefix = nothing, save_suffix = nothing, save_delim = "_", ext = r"fits(\.tar\.gz)?"i, kwargs...)
    path_iterator = filenames(collection; kwargs...)
    locations = collection.path

    processed_images = map(zip(locations, path_iterator)) do (location, output)
        processed_image = f(output)
        if save
            save_path = generate_filename(location, path, save_prefix, save_suffix, save_delim, ext)
            write_data(save_path, processed_image)
        end
        processed_image
    end

    return processed_images
end


"""
    arrays(f, collection::DataFrame; save = false, path = nothing, save_prefix = nothing, save_suffix = nothing, save_delim = "_", ext = r"fits(\\.tar\\.gz)?"i, kwargs...)

Iterates over the image arrays of the collection applying function `f` at each step.

It returns an array of output values of function `f` applied on image arrays. If `save = true`, it enables programmatical saving of returned value of the function `f` using `CCDReduction.write_fits`. File is saved at `path` specified by the user.
Suffix and prefix can be added to filename of newly created files by modifying `save_suffix` and `save_prefix`, `save_delim` is used as delimiter.
`ext` is the extension of files in collection, by default it is set to `r"fits(\\.tar\\.gz)?"i`.

Mapping version can be used as
```julia
collection = fitscollection("~/data/tekdata")
processed_images = map(arrays(collection)) do arr
    trim(arr, (:, 1040:1059))
end
```
The above generates `processed_images` which consists of trimmed versions of image arrays present in `collection`.
For saving the `processed_images` simultaneously with the operations performed
```julia
processed_images = map(arrays(collection; save = true, path = "~/data/tekdata", save_prefix = "trimmed")) do img
    trim(img, (:, 1040:1059))
end
```
the trimmed image arrays are saved as `trimmed_(original_name)` (FITS files) at `path = "~/data/tekdata"` as specified by the user.

Mapping version of `arrays` function is interfaced on iterative version of `arrays`, any valid parameter can be passed into iterative version as `kwargs`.
"""
function arrays(f, collection::DataFrame; save = false, path = nothing, save_prefix = nothing, save_suffix = nothing, save_delim = "_", ext = r"fits(\.tar\.gz)?"i, kwargs...)
    array_iterator = arrays(collection; kwargs...)
    locations = collection.path

    processed_images = map(zip(locations, array_iterator)) do (location, output)
        processed_image = f(output)
        if save
            save_path = generate_filename(location, path, save_prefix, save_suffix, save_delim, ext)
            write_data(save_path, processed_image)
        end
        processed_image
    end

    return processed_images
end
