# AbstractOS
# you run this operating system
# only return julia code (without setting it to output or anything, your code will be run verbatim)
# you can manipulate context
# you can `put!(outputDevice, value)`

while !eof(stdin)
  input = readline(stdin)
  if !isempty(input)
      println("You entered: $input")
  end
end

# channels = map(channel, inputDevices)
# tasks = [@async channel_listener(channel) for channel in channels]

# put!(inputTerminalChannel, "do you understand your job?")
# put!(inputTerminalChannel, "hi. my name is imi")
# put!(inputTerminalChannel, "what is my name?")







# o="""
# "\"\"\"\nput!(channel(outputDevices[1]), \"I understand my job. I am operating within AbstractOS, and my purpose is to provide Julia code that can manipulate the system when evaluated with `eval(Meta.parse(code))`. I can communicate with the user by using `put!` on the channel of an output device. I can also update the context dictionary to store information for future prompts. If you have any specific tasks or requests, I'm ready to assist.\")\n\"\"\"
# """
# eval(Meta.parse(o))
# """
# put!(channel(outputDevices[1]), "I understand my job. I am operating within AbstractOS, and my purpose is to provide Julia code that can manipulate the system when evaluated with `eval(Meta.parse(code))`. I can communicate with the user by using `put!` on the channel of an output device. I can also update the context dictionary to store information for future prompts. If you have any specific tasks or requests, I'm ready to assist.")
# """
# put!(channel(outputDevices[1]), "I understand my job. I am operating within AbstractOS, and my purpose is to provide Julia code that can manipulate the system when evaluated with `eval(Meta.parse(code))`. I can communicate with the user by using `put!` on the channel of an output device. I can also update the context dictionary to store information for future prompts. If you have any specific tasks or requests, I'm ready to assist.")




# AbstractOS.init()

# xAIAPIKey = "xai-VGMPUem10kJW5f2wg0kGRKAsRzR4FKEVkWFrgN9ZuXm1ZDA9MkNlQOZQgfTCabkZA5JkZgE6y3wguoxC"

# curl https://api.x.ai/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer xai-VGMPUem10kJW5f2wg0kGRKAsRzR4FKEVkWFrgN9ZuXm1ZDA9MkNlQOZQgfTCabkZA5JkZgE6y3wguoxC" -d '{
#   "messages": [
#     {
#       "role": "system",
#       "content": "You are a test assistant."
#     },
#     {
#       "role": "user",
#       "content": "Testing. Just say hi and hello world and nothing else."
#     }
#   ],
#   "model": "grok-2-latest",
#   "stream": false,
#   "temperature": 0
# }'
# {"id":"05e89da4-cb0a-4efd-9569-06aa372f7ff5","object":"chat.completion","created":1742164258,"model":"grok-2-1212","choices":[{"index":0,"message":{"role":"assistant","content":"Hi\nHello world","refusal":null},"finish_reason":"stop"}],"usage":{"prompt_tokens":28,"completion_tokens":5,"reasoning_tokens":0,"total_tokens":33,"prompt_tokens_details":{"text_tokens":28,"audio_tokens":0,"image_tokens":0,"cached_tokens":0}},"system_fingerprint":"fp_fe9e7ef66e"}%    

# curl https://api.x.ai/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer xai-VGMPUem10kJW5f2wg0kGRKAsRzR4FKEVkWFrgN9ZuXm1ZDA9MkNlQOZQgfTCabkZA5JkZgE6y3wguoxC" -d '{
#   "messages": [
#     {
#       "role": "system",
#       "content": "You are a julia coder.output julia code only, nothing else."
#     },
#     {
#       "role": "user",
#       "content": "write a function to calculate the sum of the squares of all integers upto n."
#     }
#   ],
#   "model": "grok-2-latest",
#   "stream": false,
#   "temperature": 0
# }'
# "```julia\nfunction sum_of_squares(n)\n    return sum(i^2 for i in 1:n)\nend\n```"
# n=5
# sum(i^2 for i in 1:n)