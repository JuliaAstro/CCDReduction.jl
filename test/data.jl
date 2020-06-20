# This part is used for loading the data for testing purpose
const test_file_url_M6707HH = "https://www.cfa.harvard.edu/~dfabricant/huchra/ay16/fits/M6707HH.fits"
const test_file_path_M6707HH = joinpath(@__DIR__, "data", "M6707HH.fits")
if !isfile(test_file_path_M6707HH)
    mkpath(dirname(test_file_path_M6707HH))
    download(test_file_url_M6707HH, test_file_path_M6707HH)
end
const M6707HH =  FITS(test_file_path_M6707HH)
