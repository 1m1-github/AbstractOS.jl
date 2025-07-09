# set ENV["CLAUDE_API_KEY"]

@api const Claude_next = """
this knowledge connects to claude.ai
"""

import Pkg
Pkg.add(["HTTP", "JSON3"])
using HTTP, JSON3, Base64
# claude-sonnet-4-20250514
# claude-opus-4-20250514
function claude_chat(message::String; files=[], model="claude-sonnet-4-20250514", max_tokens=10000)
    headers = [
        "Content-Type" => "application/json",
        "x-api-key" => ENV["CLAUDE_API_KEY"],
        "anthropic-version" => "2023-06-01"
    ]
    
    # Build message content with files
    content = []
    
    # Add any files first
    for file in files
        if isa(file, String) && isfile(file)
            # Read file and encode to base64
            file_content = read(file)
            file_base64 = base64encode(file_content)
            
            # Determine media type based on extension
            ext = lowercase(splitext(file)[2])
            media_type = if ext in [".jpg", ".jpeg"]
                "image/jpeg"
            elseif ext == ".png"
                "image/png"
            elseif ext == ".gif"
                "image/gif"
            elseif ext == ".webp"
                "image/webp"
            else
                "application/octet-stream"
            end
            
            push!(content, Dict(
                "type" => "image",
                "source" => Dict(
                    "type" => "base64",
                    "media_type" => media_type,
                    "data" => file_base64
                )
            ))
        end
    end
    
    push!(content, Dict(
        "type" => "text",
        "text" => message
    ))
    
    body = JSON3.write(Dict(
        "model" => model,
        "max_tokens" => max_tokens,
        "system" => YOUR_PURPOSE,
        "messages" => [
            Dict("role" => "user", "content" => content)
        ]
    ))
    
    try
        # @show body # DEBUG
        response = HTTP.post(
            "https://api.anthropic.com/v1/messages",
            headers,
            body
        )
        
        if response.status == 200
            result = JSON3.read(String(response.body))
            result = result.content[1].text
            if startswith(result, "```julia")
                result = result[9:end-3]
            end
            result
        else
            error("API request failed with status $(response.status): $(String(response.body))")
        end
    catch e
        error("Error making API request: $e")
    end
end

@api next = claude_chat