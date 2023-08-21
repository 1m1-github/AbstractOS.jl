# add LibSndFile PortAudio SampledSignals FileIO Whisper OpenAI
import LibSndFile
using PortAudio
using SampledSignals: s
using FileIO
using PortAudio
using Whisper, LibSndFile, FileIO, SampledSignals
using OpenAI

function save_audio_from_mic(duration)
    # shure_device = filter(d->startswith(lowercase(d.name), "shure"),PortAudio.devices())[1]
    shure_device = filter(d -> startswith(lowercase(d.name), "macbook air microphone"), PortAudio.devices())[1]

    stream = PortAudioStream(shure_device, 1, 0)

    buf = read(stream, duration)

    close(stream)

    # save("test.ogg", buf)
    buf
end

#####

function audio_buffer_to_text(buf)
    # buf2 = load("test.ogg")  
    # typeof(buf2)
    # typeof(buf)

    # Whisper expects 16kHz sample rate and Float32 data
    sout = SampleBuf(Float32, 16000, round(Int, length(buf) * (16000 / samplerate(buf))), nchannels(buf))
    write(SampleBufSink(sout), SampleBufSource(buf))  # Resample
    transcribe("base.en", sout.data)
end

#####

function ask_chatgpt(user_prompts::Vector, system_prompt="")
    # secret_key = "PAST_YOUR_SECRET_KEY_HERE"
    # model = "davinci"
    model = "gpt-4"
    # model = "gpt-3.5-turbo"
    
    system_message = Dict("role" => "system", "content" => system_prompt)
    prompt2msg(p) = Dict("role" => "user", "content" => p)
    user_messages = map(prompt2msg, user_prompts)
    messages = !isempty(system_prompt) ? [system_message; user_messages...] : user_messages
    
    r = create_chat(
        secret_key,
        model,
        messages,
        top_p=0.1
    )
    r.response[:choices][begin][:message][:content]
end
ask_learner = ask_chatgpt
ask_learner_to_code_julia(prompts) = ask_learner(prompts, "You are a julia coder. Only send back code, with a docstring and no explanations. Do not add using statements.")
ask_learner_to_remember(prompts) = ask_learner(prompts, "Remeber these facts about me. Just respond with 'got it'.")

SYSTEM_PROMPT = 
"""
you are a julia coder.
dissect my request into 
if my request is telling you to learn, you are in learn mode.
in learn mode, set the variable called request_type to :learn.
if you are not in learn mode, you are in run mode.
in run mode, set the variable called request_type to :run.
extract from my request a single function. find an appropriate name for this function in human descriptive language and set the variable function_name to this name.
write the function code and set the variable named f.
write a consise docstring for this function and assign it to the variable named d.
output only code, nothing else.
infer an appropriate name for the input for this function, if any, and assign this to a variable called input_name.
infer an approritate type for the input and assign this to the variable called input_type.
"""

SYSTEM_PROMPT_1 = 
"""
you are a julia coder.
if my request is telling you to learn, set the variable called request_type to :learn;
else set the variable called request_type to :run.
infer from my request a single function to represent the requested action. find an appropriate name for this function in human descriptive language and set the variable function_name to this name.
write the function signature for this function and assign that to the variable called function_signature, which should include types for the inputs and the output.
write the code for this function without the surrounding "function" and "end" keywords and assign the code as a string to the variable called function_code.
write a consise docstring for this function and assign it to the variable named docstring.
infer an appropriate name for the input for this function, if any, and assign this to a variable called input_name.
infer an approritate type for the input and assign this to the variable called input_type.
output only code, nothing else.
make sure the the variables are set in the following order: request_type, function_signature, function_code, docstring, input_name, input_type.
"""

SYSTEM_PROMPT_2 = 
"""
struct Request
    request_type::Symbol
    function_signature::String
    function_code::String
    input_name::String
    input_type::Type
    output_name::String
    output_type::Type
end
you are a julia coder.
from my request in human language, infer each field for an object of type Request, as defined above.
if my request is telling you to learn, set the request_type field to :learn;
else set the the request_type field to :run.
all variable names should be in descriptive human language.
the most important part is the function that represents the action of my request itself.
if it makes sense, generalize the function to take an input; otherwise the function can be without input.
the function_signature field should have the full function signature with typed inputs and an output type.
the function_code field should contain the code of the function as a string and without the surrounding "function" and "end" keywords.
the docstring field should contain as concise as possible explanation of the function.
if the function has an input, infer an appropriate input name in descriptive human language and set it to the input_name field, else if there is no input, set the input_field to the empty string.
if the function has an input, infer an appropriate input type and set it to the input_type field, else if there is no input, set the input_type to the value Any.
from my request, infer the likely name of the output of this function and set it to the field output_name.
from my request, infer the likely type of the output of this function and set it to the field output_type.
be mindful of the types of each field in the object as defined in the struct.
make sure the function_signature field contains the full signature of the function including types for the inputs and an output type.
make sure the function_code does not contain the surrounding function and end keywords.
output only code, nothing else. your response should be a single expression creating an object of type Request.
"""

SYSTEM_PROMPT_3 = 
"""
struct Request3
    request_type::Symbol
    function_signature::String
    input_name::String
    input_type::Type
    output_name::String
    output_type::Type
end
you are a julia coder.
from my request in human language, infer each field for an object of type Request3, as defined above.
if my request is telling you to learn, set the request_type field to :learn;
else set the the request_type field to :run.
all variable names should be in descriptive human language.
from my request, infer a function that represents the action that my request is asking for; from here on, when I write function, I am referring to this very function.
if it makes sense, generalize the function to take an input; otherwise the function can be without input.
the function_signature field should have the full function signature with typed inputs and an output type.
the docstring field should contain as concise as possible explanation of the function.
if the function has an input, infer an appropriate input name in descriptive human language and set it to the input_name field, else if there is no input, set the input_field to the empty string.
if the function has an input, infer an appropriate input type and set it to the input_type field, else if there is no input, set the input_type to the value Any.
from my request, infer the likely name of the output of this function and set it to the field output_name.
from my request, infer the likely type of the output of this function and set it to the field output_type.
output only code, nothing else. your response should be a single expression creating an object of type Request3.
"""

SYSTEM_PROMPT_4 = """
you are a julia coder.
from my command, create a function signature that represents that command as written in the julia language.
this function signature should be contain types for each input and the output type.
the function name should be in descriptive human language.
the function inputs, if any, should also be named in descriptive human language.
respond with only the function signature, nothing else.
"""

SYSTEM_PROMPT_5 = """
you are a julia coder.
write code given my command and the function signature provided.
respond only with code, nothing else. the code should be fully functional.
"""

struct Request3
    request_type::Symbol
    function_signature::String
    input_name::String
    input_type::Type
    output_name::String
    output_type::Type
end

struct Request
    request_type::Symbol
    function_signature::String
    function_code::String
    input_name::String
    input_type::Type
    output_name::String
    output_type::Type
end

SYSTEM_PROMPT_6 = """
struct Request6
    request_type::Symbol
    code::String
    input_name::String
    output_name::String
end
you are a julia coder. you will translate my command into julia code, a single function with typed inputs and an output type defined in the function signature.
output only code, nothing else. your response should be a single expression creating an object of type Request6.
if my command is telling you to learn, set the request_type field to :learn;
else set the the request_type field to :run.
set the code field of the Request6 object to the actual julia code of the function.
wrapped in a function with a fully typed signature.
the function code should be written into the code field of the Request6 object.
set the input_name field of the Request6 object as your best guess for the name of the input of the function, if any, else set it to the empty string.
set the output_name field of the Request6 object as your best guess for a good name for the output of the function.
"""

struct Request6
    request_type::Symbol
    code::String
    input_name::String
    output_name::String
end

prompts = ["how old is the newest file in the current directory?"]
prompts = ["how old is the newest file in the current directory?", "get_newest_file_age() :: Int"]

response = ask_chatgpt(prompts, SYSTEM_PROMPT_1)
response = ask_chatgpt(prompts, SYSTEM_PROMPT_5)
response = ask_chatgpt(prompts, SYSTEM_PROMPT_6)
write_string_to_file("response.jl", response)

names(Main)
methods(ask_chatgpt)

response
expr = Meta.parse(response)
eval(expr)
last_response = ans
@show last_response
last_response.code

pattern_bases = ["request_type", "function_name", "function_signature", "function_code", "docstring", "input_name", "input_type"]
patterns = map(x -> Regex("$(x).*(\$|\n)"), pattern_bases)

function get_expression_for_pattern(pattern, string)
    m = match(pattern, string)
    Meta.parse(m.match)
end
expressions = map(x -> get_expression_for_pattern(x, response), patterns)


####
response = ""
code = ""
function ask(duration)
    audio = save_audio_from_mic(duration)

    text = lowercase(audio_buffer_to_text(audio))
    print(text)

    m = match(r"\s*command", text)
    if m ≠ nothing
        @show "command", m
        text = text[m.offset+length("command"):end]
        @show text
        print("command: ", text)
        return eval(Meta.parse(text))
    end

    @show "not command"
    global response = ask_chatgpt(text)
    global code = response[10:end-3]
    print(response)
    response
end

function run()
    @show "run code? y/*", code
    answer = readline()
    answer ≠ "y" && return
    # TODO a better (reliable) way to get code
    eval(Meta.parse(code))
end

# convenience
a(duration) = @time ask(duration)
r = run

#####

# teach the coder ML

# Base.run(`openai tools fine_tunes.prepare_data -f finetune.csv`)

# Base.run(`openai api fine_tunes.create -t finetune.jsonl -m davinci`)
# Base.run(`export OPENAI_API_KEY=a`)
# Base.run(`echo $OPENAI_API_KEY`)

function write_string_to_file(filename::String, content::String)
    open(filename, "w") do io
        write(io, content)
    end
end



