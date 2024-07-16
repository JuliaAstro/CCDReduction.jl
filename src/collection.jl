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
    filename = basename(path)

    # splitting name and extension
    modified_name, extension = parse_name_ext(filename, "." * ext)

    # adding prefix and suffix with delimiter
    if !isnothing(save_prefix)
        modified_name = string(save_prefix, save_delim, modified_name)
    end
    if !isnothing(save_suffix)
        modified_name = string(modified_name, save_delim, save_suffix)
    end

    # adding extension to modified_name
    file_path = joinpath(save_location, modified_name * extension)
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


"""
    CCDReduction.writefits(file_path, data; header = nothing)
    CCDReduction.writefits(file_path, ccd::CCDData)

Writes `data`/`ccd` in FITS format at `file_path`.

`FITSIO` takes over memory write in by `cfitsio`, which writes in row-major
form, whereas when Julia gives that memory, it is assumed as column major.
Therefore all data written by
[`FITSIO.write`](https://juliaastro.org/FITSIO.jl/stable/api/#Base.write-Tuple{FITS,%20Dict{String}})
is transposed. This function allows the user to write the data in a consistent
    way to FITS file by transposing before writing.
"""
function writefits(file_path, data; header = nothing)
    d = ndims(data)
    transposed_data = permutedims(data, d:-1:1)
    FITS(file_path, "w") do fh
        write(fh, transposed_data; header = header)
    end
end

writefits(file_path, ccd::CCDData) = writefits(file_path, ccd.data; header = ccd.hdr)

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

Walk through `dir` collecting FITS files, scanning their headers, and
culminating into a `DataFrame` that can be used with the generators for
iterating over many files and processing them. If `recursive` is false, no
subdirectories will be walked through.

The table returned will contain the path to the file, the name of the file, and
index of the corresponding HDU, and each FITS header column and value. If two
FITS files have distinct columns, they will both appear in the table with
`missing` in the appropriate rows.

!!! note "Duplicate Keys"
    In certain cases, there are multiple FITS headers with the same key, e.g.,
    `COMMENT`. In these cases, only the first instance of the key-value pair
    will be stored.

If `abspath` is true, the path in the table will be absolute. If `keepext` is
true, the name in the table will include the file extension, given by `ext`.
`ext` will be used with `endswith` to filter for fits files compatible with
`FITSIO.FITS`. `exclude` is a pattern that can be used with `occursin` to
exclude certain filenames. For example, to exclude any files containing "sky",
```julia
fitscollection(...; exclude="sky")
```
to exclude exact filenames,
[regex strings](https://docs.julialang.org/en/v1/manual/strings/#Regular-Expressions-1)
will prove powerful
```julia
fitscollection(...; exclude=r"^tek001\d")
```
finally, using external tools like [Glob.jl](https://github.com/vtjnash/Glob.jl)
allows further customization
```julia
using Glob
fitscollection(...; exclude=fn"tek001*.fits") # same as regex match above
```
Similarly, `exclude_dir` allows excluding entire folders using pattern matching
(e.g. skipping a backup folder `exclude_dir="backup"`).
`exclude_key` allows excluding certain entries in the header unit of `ImageHDU`
in FITS files (e.g. skipping `"HISTORY"` and `""` `exclude_key = ("HISTORY", "")`).

For more information about the file matching and path deconstruction, see the
extended help (`??fitscollection`)
# Extended Help

## Parts of a path

Let's look at some file paths starting from `"/data"`. Here are examples of how
they would be parsed

```plain
 root  dir   base   ext
[----][---][------][---]
/data/test/tek0001.fits

 root    dir     base   ext
[----][-------][------][---]
/data/test/sci/tek0001.fits
```

If `keepext` is `true`, `name=base * ext`, otherwise it is just `base`. If
`abspath` is `true`, the path will be `root * dir * base * ext`, otherwise it
will be `dir * base * ext`. These options allow flexility in creating a table
that can be easily saved and loaded to avoid having to manually filter files.
Especially consider how `abspath` can allow keeping tables that will transfer
easily between computers or between data sources with common structures.
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

                # filtering out excluded columns
                _keys = filter(k -> k ∉ exclude_key, keys(header_data))
                # if there are duplicate keys (usually COMMENT) only use first
                unique_inds = unique(idx -> _keys[idx], eachindex(_keys))
                unique_keys = _keys[unique_inds]
                # create generator for values from the keys
                _values = (header_data[k] for k in unique_keys)

                key_val_itr = zip(Symbol.(unique_keys), _values)

                push!(collection, (path = path, name = name, hdu = index, key_val_itr...); cols = :union)
            end
            close(fits_data)
        end
    end
    return collection
end

"""
    arrays(collection)

Generator for arrays of images of entries in data frame.

Iterates over `collection` using each `path` and `hdu` to load data into an `Array`.

# Examples
```julia
collection = fitscollection("~/data/tekdata")
data = arrays(collection) |> collect
```
This returns all image arrays present in `collection`.
This can also be used via a for-loop
```julia
collection = fitscollection("~/data/tekdata")
for arr in arrays(collection)
    @assert arr isa Array
    println(size(arr))
end

# output
(1048, 1068)
(1048, 1068)
...
```
"""
function arrays end

# generator for image arrays specified by data frames (i.e. path of file, hdu etc.)
@resumable function arrays(collection)
    for row in eachrow(collection)
        fh = FITS(row.path)
        @yield getdata(fh[row.hdu])
        close(fh)
    end
end


"""
    filenames(collection)

Generator for filenames of entries in data frame.

Iterates over `collection` using each `path`.

# Examples
```julia
collection = fitscollection("~/data/tekdata")
for path in filenames(collection)
    @assert path isa String
    println(path)
end

# output
"~/data/tekdata/tek001.fits"
"~/data/tekdata/tek002.fits"
...
```
"""
function filenames end

# generator for filenames specified by data frame (i.e. path of file, hdu etc.)
@resumable function filenames(collection)
    for row in eachrow(collection)
        @yield row.path
    end
end


"""
    ccds(collection)

Generator for `CCDData`s of entries in data frame.

Iterates over `collection` using each `path` and `hdu` to load data into a
[`CCDData`](@ref).

# Examples
```julia
collection = fitscollection("~/data/tekdata")
for hdu in ccds(collection)
    @assert hdu isa CCDData
end
```
"""
function ccds end

# generator for CCDData specified by data frame (i.e. path of file, hdu etc.)
@resumable function ccds(collection)
    for row in eachrow(collection)
        @yield CCDData(row.path; hdu = row.hdu)
    end
end


"""
    ccds(f,
         collection;
         path = nothing,
         save_prefix = nothing,
         save_suffix = nothing,
         save = any(!isnothing, (save_prefix, path, save_suffix)),
         save_delim = "_",
         ext = r"fits(\\.tar\\.gz)?"i,
         kwargs...)

Iterates over the `CCDData`s of the collection applying function `f` at each step.

The output from `f` can be saved using the appropriate keyword arguments. The
`save_prefix` argument will add a prefix to each filename delimited by
`save_delim`. `save_suffix` will add a suffix prior to the extension, which can
be manually provided via `ext`, similar to [`fitscollection`](@ref). Files will
be saved in the directory they are stored unless `path` is given. Finally,
`save` will default to `true` if any of the previous arguments are set, but can
be manually overridden (useful for testing). Files will be saved using
[`CCDReduction.writefits`](@ref).

# Example
```julia
collection = fitscollection("~/data/tekdata")
processed_images = map(ccds(collection)) do img
    trim(img, (:, 1040:1059))
end
```
The above generates `processed_images` which consists of trimmed versions of
images present in `collection`.

For saving the `processed_images` simultaneously with the operations performed
```julia
processed_images = map(ccds(collection; path = "~/data/tekdata", save_prefix = "trimmed")) do img
    trim(img, (:, 1040:1059))
end
```
The trimmed images are saved as `trimmed_(original_name)` (FITS files) at
`path = "~/data/tekdata"` as specified by the user.
"""
function ccds(f,
              collection;
              path = nothing,
              save_prefix = nothing,
              save_suffix = nothing,
              save = any(!isnothing, (save_prefix, path, save_suffix)),
              save_delim = "_",
              ext = r"fits(\.tar\.gz)?"i,
              kwargs...)
    image_iterator = ccds(collection; kwargs...)
    locations = collection.path

    processed_images = map(zip(locations, image_iterator)) do (location, output)
        processed_image = f(output)
        if save
            # if path is nothing and still the file is being saved, the location of input file is used
            if path isa Nothing
                path = dirname(location)
            end
            save_path = generate_filename(location, path, save_prefix, save_suffix, save_delim, ext)
            writefits(save_path, processed_image)
        end
        processed_image
    end

    return processed_images
end


"""
    filenames(f,
              collection;
              path = nothing,
              save_prefix = nothing,
              save_suffix = nothing,
              save = any(!isnothing, (save_prefix, path, save_suffix)),
              save_delim = "_",
              ext = r"fits(\\.tar\\.gz)?"i,
              kwargs...)

Iterates over the file paths of the collection applying function `f` at each step.

The output from `f` can be saved using the appropriate keyword arguments. The
`save_prefix` argument will add a prefix to each filename delimited by
`save_delim`. `save_suffix` will add a suffix prior to the extension, which can
be manually provided via `ext`, similar to [`fitscollection`](@ref). Files will
be saved in the directory they are stored unless `path` is given. Finally,
`save` will default to `true` if any of the previous arguments are set, but can
be manually overridden (useful for testing). Files will be saved using
[`CCDReduction.writefits`](@ref).

# Examples
```julia
collection = fitscollection("~/data/tekdata")
data = map(filenames(collection)) do path
    fh = FITS(path)
    data = getdata(fh[1]) # assuming all 1-hdu are ImageHDUs
    close(fh)
    data
end
```
The above generates `data` which consists of image arrays corresponding to 1st
hdu of FITS file paths present in `collection`.
For saving the `data` simultaneously with the operations performed
```julia
data = map(filenames(collection; path = "~/data/tekdata", save_prefix = "retrieved_from_filename")) do img
    fh = FITS(path)
    data = getdata(fh[1]) # assuming all 1-hdu are ImageHDUs
    close(fh)
    data
end
```
The retrieved data is saved as `retrieved_from_filename_(original_name)`
(FITS files) at `path = "~/data/tekdata"` as specified by the user.
"""
function filenames(f,
                   collection;
                   path = nothing,
                   save_prefix = nothing,
                   save_suffix = nothing,
                   save = any(!isnothing, (save_prefix, path, save_suffix)),
                   save_delim = "_",
                   ext = r"fits(\.tar\.gz)?"i,
                   kwargs...)
    path_iterator = filenames(collection; kwargs...)
    locations = collection.path

    processed_images = map(zip(locations, path_iterator)) do (location, output)
        processed_image = f(output)
        if save
            # if path is nothing and still the file is being saved, the location of input file is used
            if path isa Nothing
                path = dirname(location)
            end
            save_path = generate_filename(location, path, save_prefix, save_suffix, save_delim, ext)
            writefits(save_path, processed_image)
        end
        processed_image
    end

    return processed_images
end


"""
    arrays(f,
           collection;
           path = nothing,
           save_prefix = nothing,
           save_suffix = nothing,
           save = any(!isnothing, (save_prefix, path, save_suffix)),
           save_delim = "_",
           ext = r"fits(\\.tar\\.gz)?"i,
           kwargs...)

Iterates over the image arrays of the collection applying function `f` at each step.

The output from `f` can be saved using the appropriate keyword arguments.
The `save_prefix` argument will add a prefix to each filename delimited by
`save_delim`. `save_suffix` will add a suffix prior to the extension, which can
be manually provided via `ext`, similar to [`fitscollection`](@ref). Files will
be saved in the directory they are stored unless `path` is given. Finally,
`save` will default to `true` if any of the previous arguments are set, but can
be manually overridden (useful for testing). Files will be saved using
[`CCDReduction.writefits`](@ref).

# Examples
```julia
collection = fitscollection("~/data/tekdata")
processed_images = map(arrays(collection)) do arr
    trim(arr, (:, 1040:1059))
end
```
The above generates `processed_images` which consists of trimmed versions of
image arrays present in `collection`.
For saving the `processed_images` simultaneously with the operations performed
```julia
processed_images = map(arrays(collection; path = "~/data/tekdata", save_prefix = "trimmed")) do img
    trim(img, (:, 1040:1059))
end
```
The trimmed image arrays are saved as `trimmed_(original_name)` (FITS files)
at `path = "~/data/tekdata"` as specified by the user.
"""
function arrays(f,
                collection;
                path = nothing,
                save_prefix = nothing,
                save_suffix = nothing,
                save = any(!isnothing, (save_prefix, path, save_suffix)),
                save_delim = "_",
                ext = r"fits(\.tar\.gz)?"i,
                kwargs...)
    array_iterator = arrays(collection; kwargs...)
    locations = collection.path

    processed_images = map(zip(locations, array_iterator)) do (location, output)
        processed_image = f(output)
        if save
            # if path is nothing and still the file is being saved, the location of input file is used
            if path isa Nothing
                path = dirname(location)
            end
            save_path = generate_filename(location, path, save_prefix, save_suffix, save_delim, ext)
            writefits(save_path, processed_image)
        end
        processed_image
    end

    return processed_images
end
