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
    shure_device = filter(d->startswith(lowercase(d.name), "macbook air microphone"),PortAudio.devices())[1]

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
    sout = SampleBuf(Float32, 16000, round(Int, length(buf)*(16000/samplerate(buf))), nchannels(buf))
    write(SampleBufSink(sout), SampleBufSource(buf))  # Resample
    transcribe("base.en", sout.data)
end

#####

function ask_chatgpt(prompt)
    # secret_key = "PAST_YOUR_SECRETE_KEY_HERE"
    # model = "davinci"
    model = "gpt-3.5-turbo"
    r = create_chat(
        secret_key, 
        model,
        [
            Dict("role" => "system", "content"=> "You are a julia coder. Only send back code, with a docstring and no explanations. Do not add using statements."),
            Dict("role" => "user", "content"=> prompt)
        ]
    )
    r.response[:choices][begin][:message][:content]
end

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