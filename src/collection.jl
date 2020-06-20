raw"""
    filecollection(dir; walk=true, abspath=true, keepext=true, ext=r"fits(\.tar\.gz)?", exclude=nothing, dir_exclude=nothing)

Walk through `dir` collecting FITS files, scanning their headers, and culminating into a `DataFrame` that can be used with the [generators](@ref gens) for iterating over many files and processing them. If `walk` is false, no subdirectories will be walked through.

The table returned will contain the path to the file, the name of the file, and index of the corresponding hdu, and each FITS header column and value. If two FITS files have distinct columns, they will both appear in the table with `missing` in the appropriate rows.

If `abspath` is true, the path in the table will be absolute compared to `dir`. If `keepext` is true, the name in the table will include the file extension, given by `ext`. `ext` will be used with `endswith` to filter for fits files compatible with `FITSIO.FITS`. `exclude` is a pattern that can be used with `occursin` to exclude certain filenames. For example, to exclude any files containing "sky",
```julia
filecollection(...; exclude="sky")
```
to exclude exact filenames, [regex strings](https://docs.julialang.org/en/v1/manual/strings/#Regular-Expressions-1) will prove powerful
```julia
filecollection(...; exclude=r"^tek001\d")
```
finally, using external tools like [Glob.jl](https://github.com/vtjnash/Glob.jl) allows further customization
```julia
using Glob
filecollection(...; exclude=fn"tek001*.fits") # same as regex match above
```
Similarly, `dir_exclude` allows excluding entire folders using pattern matching (e.g. skipping a backup folder `dir_exclude="backup"`).

For more information about the file matching and path deconstruction, see the extended help (`??filecollection`)
# Extended Help

## Parts of a path

Here is an example of a file path and how it would be parsed

```
     root         dir   base   ext
[---------------][----][-----][----]
\Users\miles\data\test\tek0001.fits

     root          dir     base    ext
[---------------][--------][-----][----]
\Users\miles\data\test\sci\tek0001.fits
```

If `keepext` is `true`, `name=base * ext`, otherwise it is just `base`. If `abspath` is `true`, the path will be `root * dir * base * ext`, otherwise it will be `dir * base * ext`. These options allow flexility in creating a table that can be easily saved and loaded to avoid having to manually filter files. Especially consider how `abspath` can allow keeping tables that will transfer easily between computers or between data sources with common structures.
"""
function fitscollection(basedir::String; abspath = true, keepext = true, ext = r"fits(\.tar\.gz)?"i, exclude = nothing, dir_exclude = nothing, walk = true)
    df = DataFrame()

    for (root, dirs, files) in walkdir(basedir)
        # To exclude certain directories
        if dir_exclude !== nothing
            occursin(dir_exclude, root) && continue
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
                path = abspath ? abspath(location) : location
                name = keepext ? filename : first(split(filename, "." * ext))
                push!(df, (path=path, name=name, hdu = index, zip(Symbol.(keys(header_data)), values(header_data))...); cols = :union)
            end
            close(fits_data)
        end
    end
    return df
end
