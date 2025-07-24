@api const XAI_next = """
this knowledge connects to X AI. `files` in `next(input::String; files=[])::String` now supports image file paths (jpg/png) by encoding them as base64 data URLs for vision capabilities.
"""

import Pkg
Pkg.add(["HTTP", "JSON", "Base64"])
using HTTP, JSON, Base64

@api MAX_OUTPUT_TOKENS = 10000

function callXAIAPI(api_key::String, messages::Vector{Dict{String, Any}}; model::String="grok-4", max_tokens::Int)::String
    url = "https://api.x.ai/v1/chat/completions"

    headers = [
        "Authorization" => "Bearer $(api_key)",
        "Content-Type" => "application/json"
    ]

    body = Dict(
        "model" => model,
        "messages" => messages,
        "max_tokens" => max_tokens,
        "temperature" => 0.2,
        "top_p" => 0.5,
    )

    @debug length(JSON.json(body))

    response = HTTP.post(url, headers, JSON.json(body))
    result = JSON.parse(String(response.body))
    result["choices"][1]["message"]["content"]
end

@api function next(input::String; files::Vector{String}=String[])::String
    global YOUR_PURPOSE, MAX_OUTPUT_TOKENS
    
    messages = [
        Dict("role" => "system", "content" => YOUR_PURPOSE)
    ]
    
    user_content = Any[Dict("type" => "text", "text" => input)]
    
    for file in files
        if !isfile(file)
            error("File not found: $file")
        end
        ext = lowercase(splitext(file)[2])
        if ext ∉ [".jpg", ".jpeg", ".png"]
            error("Unsupported file type: $ext. Only jpg/jpeg/png supported.")
        end
        mime = ext == ".png" ? "image/png" : "image/jpeg"
        data = read(file)
        base64_data = base64encode(data)
        push!(user_content, Dict(
            "type" => "image_url",
            "image_url" => Dict("url" => "data:$mime;base64,$base64_data")
        ))
    end
    
    push!(messages, Dict("role" => "user", "content" => user_content))
    
    callXAIAPI(ENV["X_AI_API_KEY"], messages; max_tokens=MAX_OUTPUT_TOKENS)
end