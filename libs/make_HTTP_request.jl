
@api function make_HTTP_request(url::String, endpoint::String, method::String, headers, body=nothing; query_params=Dict())
    url = "$url/$endpoint"
    
    if !isempty(query_params)
        query_string = join(["$k=$v" for (k, v) in query_params], "&")
        url = "$url?$query_string"
    end

    try
        if body !== nothing
            response = HTTP.request(method, url, headers, JSON3.write(body))
        else
            response = HTTP.request(method, url, headers)
        end
        
        if response.status >= 400
            error("API request failed with status $(response.status): $(String(response.body))")
        end
        
        isempty(response.body) && return response.status
        JSON3.read(String(response.body))
    catch e
        println("Error making request to $url: $e")
        rethrow(e)
    end
end

