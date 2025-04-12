using HTTP
using JSON

# Function to call xAI API
function call_xai_api(api_key::String, systemPrompt::String, userPrompt::String; model::String="grok-3", max_tokens::Int=100)
    # API endpoint
    url = "https://api.x.ai/v1/chat/completions"
    
    # Headers
    headers = [
        "Authorization" => "Bearer $api_key",
        "Content-Type" => "application/json"
    ]
    
    # Request body
    body = Dict(
        "model" => model,
        "messages" => [
            Dict("role" => "system", "content" => systemPrompt),
            Dict("role" => "user", "content" => userPrompt)
        ],
        "max_tokens" => max_tokens,
        "temperature" => 0.9
    )
# @show "about to HTTP.post",userPrompt
    try
        # Make POST request
        response = HTTP.post(url, headers, JSON.json(body))
# @show response
# @show "======="
        # Parse response
        if response.status == 200
            result = JSON.parse(String(response.body))
            return result["choices"][1]["message"]["content"]
        else
            println("Error: HTTP status $(response.status)")
            return nothing
        end
    catch e
        println("Error occurred: $e")
        return nothing
    end
end

# Example usage
function next(state, nextHistory, deviceOutput)
    # Replace with your actual xAI API key
    xAIAPIKey = ""
    
    # Call the API
    systemPrompt = "yourPurpose: $SYSTEM_PROMPT"
    state = "state: $state"
    nextHistory = "yourPastResponses: $nextHistory"
    currentPrompt = "currentPrompt: $deviceOutput"
    systemPrompt *= "\n$state"
    deviceOutput = "$nextHistory\n$currentPrompt"
    call_xai_api(xAIAPIKey, systemPrompt, deviceOutput, max_tokens=1000)
    
    # Print the response
    # if response !== nothing
    #     println("Response from xAI API:\n$response")
    # else
    #     println("Failed to get a response from the API.")
    # end
end