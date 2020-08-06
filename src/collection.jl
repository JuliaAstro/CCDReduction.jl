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

#---------------------------------------------------------------------------------------
@doc raw"""
    fitscollection(dir; recursive=true, abspath=true, keepext=true, ext=r"fits(\.tar\.gz)?", exclude=nothing, exclude_dir=nothing, exclude_key = ("", "HISTORY"))

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
    df = DataFrame()

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
                push!(df, (path = path, name = name, hdu = index, zip(Symbol.(_keys), _values)...); cols = :union)
            end
            close(fits_data)
        end
    end
    return df
end


"""
    arrays(df::DataFrame)

Generator for arrays of images of entries in data frame.
"""
function arrays end

# generator for image arrays specified by data frames (i.e. path of file, hdu etc.)
@resumable function arrays(df::DataFrame)
    for row in eachrow(df)
        fh = FITS(row.path)
        @yield getdata(fh[row.hdu])
        close(fh)
    end
end


"""
    filenames(df::DataFrame)

Generator for filenames of entries in data frame.
"""
function filenames end

# generator for filenames specified by data frame (i.e. path of file, hdu etc.)
@resumable function filenames(df::DataFrame)
    for row in eachrow(df)
        @yield row.path
    end
end


"""
    ccds(df::DataFrame)

Generator for `CCDData`s of entries in data frame.
"""
function ccds end

# generator for CCDData specified by data frame (i.e. path of file, hdu etc.)
@resumable function ccds(df::DataFrame)
    for row in eachrow(df)
        fh = FITS(row.path)
        @yield CCDData(fh[row.hdu])
        close(fh)
    end
end
