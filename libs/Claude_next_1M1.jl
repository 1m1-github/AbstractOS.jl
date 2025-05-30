@api const Claude_next = """
this knowledge connects to claude.ai
"""

import Pkg
Pkg.add(["HTTP", "JSON3"])
using HTTP, JSON3

@api function next(input::String)::String
    # set your actual Claude API key globally
    claude_chat(input)
end

function claude_chat(message::String, model="claude-opus-4-20250514", max_tokens=10000)
    headers = [
        "Content-Type" => "application/json",
        "x-api-key" => ClaudeAPIKey,
        "anthropic-version" => "2023-06-01"
    ]
    
    body = JSON3.write(Dict(
        "model" => model,
        "max_tokens" => max_tokens,
        "system" => YOUR_PURPOSE,
        "messages" => [
            Dict("role" => "user", "content" => message)
        ]
    ))
    
    try
        response = HTTP.post(
            "https://api.anthropic.com/v1/messages",
            headers,
            body
        )
        
        if response.status == 200
            result = JSON3.read(String(response.body))
            result = result.content[1].text
            if startswith(result, """```julia""")
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