using AbstractOS

AbstractOS.init()

xAIAPIKey = "xai-VGMPUem10kJW5f2wg0kGRKAsRzR4FKEVkWFrgN9ZuXm1ZDA9MkNlQOZQgfTCabkZA5JkZgE6y3wguoxC"

curl https://api.x.ai/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer xai-VGMPUem10kJW5f2wg0kGRKAsRzR4FKEVkWFrgN9ZuXm1ZDA9MkNlQOZQgfTCabkZA5JkZgE6y3wguoxC" -d '{
  "messages": [
    {
      "role": "system",
      "content": "You are a test assistant."
    },
    {
      "role": "user",
      "content": "Testing. Just say hi and hello world and nothing else."
    }
  ],
  "model": "grok-2-latest",
  "stream": false,
  "temperature": 0
}'
{"id":"05e89da4-cb0a-4efd-9569-06aa372f7ff5","object":"chat.completion","created":1742164258,"model":"grok-2-1212","choices":[{"index":0,"message":{"role":"assistant","content":"Hi\nHello world","refusal":null},"finish_reason":"stop"}],"usage":{"prompt_tokens":28,"completion_tokens":5,"reasoning_tokens":0,"total_tokens":33,"prompt_tokens_details":{"text_tokens":28,"audio_tokens":0,"image_tokens":0,"cached_tokens":0}},"system_fingerprint":"fp_fe9e7ef66e"}%    

curl https://api.x.ai/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer xai-VGMPUem10kJW5f2wg0kGRKAsRzR4FKEVkWFrgN9ZuXm1ZDA9MkNlQOZQgfTCabkZA5JkZgE6y3wguoxC" -d '{
  "messages": [
    {
      "role": "system",
      "content": "You are a julia coder.output julia code only, nothing else."
    },
    {
      "role": "user",
      "content": "write a function to calculate the sum of the squares of all integers upto n."
    }
  ],
  "model": "grok-2-latest",
  "stream": false,
  "temperature": 0
}'
"```julia\nfunction sum_of_squares(n)\n    return sum(i^2 for i in 1:n)\nend\n```"
n=5
sum(i^2 for i in 1:n)