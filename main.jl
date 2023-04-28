import LibSndFile
using PortAudio
using SampledSignals: s
using FileIO
using PortAudio
using Whisper, LibSndFile, FileIO, SampledSignals
using OpenAI

function save_audio_from_mic(duration)
    shure_device = filter(d->startswith(lowercase(d.name), "shure"),PortAudio.devices())[1]

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
    model = "gpt-3.5-turbo"
    r = create_chat(
        secret_key, 
        model,
        [
            Dict("role" => "system", "content"=> "You are a julia coder. Only send back code, with a docstring and no explanations"),
            Dict("role" => "user", "content"=> prompt)
        ]
    )
    r.response[:choices][begin][:message][:content]
end

####

function ask(duration)
    audio = save_audio_from_mic(duration)
    text = audio_buffer_to_text(audio)
    print(text)
    response = ask_chatgpt(text)
    print(response)
    response
end

@time response = ask(10s);

# updated_response = replace(response, "add_four_numbers" => "add_four_numbers_2")
code = updated_response[10:end-3]
eval(Meta.parse(code))