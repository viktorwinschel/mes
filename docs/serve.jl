using HTTP
using Sockets

const DOCS_DIR = joinpath(@__DIR__, "build")

function handler(req::HTTP.Request)
    path = HTTP.URIs.splitpath(req.target)
    file_path = joinpath(DOCS_DIR, path...)

    if isfile(file_path)
        return HTTP.Response(200, read(file_path))
    elseif isdir(file_path)
        index_path = joinpath(file_path, "index.html")
        if isfile(index_path)
            return HTTP.Response(200, read(index_path))
        end
    end

    return HTTP.Response(404, "Not Found")
end

const host = "127.0.0.1"
const port = 8000

println("Starting documentation server at http://$host:$port")
println("Press Ctrl+C to stop the server")

# Use HTTP.serve directly
HTTP.serve(handler, host, port)