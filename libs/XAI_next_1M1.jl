@api const XAI_next = """
this knowledge connects to X AI
"""

import Pkg
Pkg.add(["HTTP", "JSON"])
using HTTP, JSON

@api MAX_OUTPUT_TOKENS = 10000

function callXAIAPI(apiKey::String, systemPrompt::String, userPrompt::String; model::String="grok-3", maxTokens::Int)::String
    url = "https://api.x.ai/v1/chat/completions"
    
    headers = [
        "Authorization" => "Bearer $apiKey",
        "Content-Type" => "application/json"
    ]
    
    body = Dict(
        "model" => model,
        "messages" => [
            Dict("role" => "system", "content" => systemPrompt),
            Dict("role" => "user", "content" => userPrompt)
        ],
        "max_tokens" => maxTokens,
        "temperature" => 0.9
    )

    response = HTTP.post(url, headers, JSON.json(body))
    result = JSON.parse(String(response.body))
    result["choices"][1]["message"]["content"]
end

@api function next(input::String)::String
    callXAIAPI(ENV["X_AI_API_KEY"], YOUR_PURPOSE, input, maxTokens=MAX_OUTPUT_TOKENS)
end