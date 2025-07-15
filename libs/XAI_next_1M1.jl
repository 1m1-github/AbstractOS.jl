@api const XAI_next = """
this knowledge connects to X AI. `files` in `next(input::String; files=[])::String` is currently unused (not yet implemented).
"""

import Pkg
Pkg.add(["HTTP", "JSON"])
using HTTP, JSON

@api MAX_OUTPUT_TOKENS = 10000

function callXAIAPI(api_key::String, system_prompt::String, user_prompt::String; model::String="grok-4", max_tokens::Int)::String
    url = "https://api.x.ai/v1/chat/completions"

    headers = [
        "Authorization" => "Bearer $(api_key)",
        "Content-Type" => "application/json"
    ]

    body = Dict(
        "model" => model,
        "messages" => [
            Dict("role" => "system", "content" => system_prompt),
            Dict("role" => "user", "content" => user_prompt)
        ],
        "max_tokens" => max_tokens,
        "temperature" => 0.2,
        "top_p" => 0.5,
        # "frequency_penalty" => 0.2,
        # "presence_penalty" => 0.2
    )
@info length(user_prompt)
    response = HTTP.post(url, headers, JSON.json(body))
    result = JSON.parse(String(response.body))
    result["choices"][1]["message"]["content"]
end

@api function next(input::String; files=[])::String
    global YOUR_PURPOSE, MAX_OUTPUT_TOKENS
    callXAIAPI(ENV["X_AI_API_KEY"], YOUR_PURPOSE, input, maxTokens=MAX_OUTPUT_TOKENS)
end