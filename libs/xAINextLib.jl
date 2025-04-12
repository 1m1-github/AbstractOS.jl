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
function next(inputs)
    # Replace with your actual xAI API key
    api_key = "xai-VGMPUem10kJW5f2wg0kGRKAsRzR4FKEVkWFrgN9ZuXm1ZDA9MkNlQOZQgfTCabkZA5JkZgE6y3wguoxC"
    
    # Define your prompt
    # prompt = "Explain the significance of Julia in scientific computing."
    
    # Call the API
    systemPrompt = "your purpose: $SYSTEM_PROMPT"
    state = "state: $(inputs[1])"
    nextHistory = "nextHistory: $(inputs[2])"
    # deviceOutput = "deviceOutput: $(inputs[3])"
    deviceOutput = inputs[3]
    systemPrompt = join([systemPrompt, state, nextHistory], '.')
    call_xai_api(api_key, systemPrompt, deviceOutput, max_tokens=1000)
    
    # Print the response
    # if response !== nothing
    #     println("Response from xAI API:\n$response")
    # else
    #     println("Failed to get a response from the API.")
    # end
end

# Run the example
# main()