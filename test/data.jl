using Downloads
# This part is used for loading the data for testing purpose
const test_file_url_M6707HH = "https://www.cfa.harvard.edu/~dfabricant/huchra/ay16/fits/M6707HH.fits"
const test_file_path_M6707HH = joinpath(@__DIR__, "data", "M6707HH.fits")
if !isfile(test_file_path_M6707HH)
    mkpath(dirname(test_file_path_M6707HH))
    Downloads.download(test_file_url_M6707HH, test_file_path_M6707HH)
end
const M6707HH =  FITS(test_file_path_M6707HH)

const test_file_url_M35070V = "https://www.cfa.harvard.edu/~dfabricant/huchra/ay16/fits/M35070V.fits"
const test_file_path_M35070V = joinpath(@__DIR__, "data", "M35070V.fits")
if !isfile(test_file_path_M35070V)
    mkpath(dirname(test_file_path_M35070V))
    Downloads.download(test_file_url_M35070V, test_file_path_M35070V)
end
const M35070V =  FITS(test_file_path_M35070V)
