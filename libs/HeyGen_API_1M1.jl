using HTTP
using JSON3

"""
Simple HeyGen API client for Julia

HeyGen API allows you to create AI-powered avatar videos, streaming avatars,
video translations, and photo avatars programmatically.

Based on HeyGen's official API documentation.
"""

function heygen_make_request(method::String, endpoint::String, body=nothing)
    headers = [
        "X-Api-Key" => ENV["HEYGEN_API_KEY"],
        "Content-Type" => "application/json",
        "Accept" => "application/json"
    ]
    make_HTTP_request("https://api.heygen.com/v1", endpoint, method, headers, body, query_params=Dict())
end

# ===== AVATAR AND VOICE ENDPOINTS =====

"""List all available avatars"""
@api function list_avatars()
    return heygen_make_request("GET", "v1/avatar.list")
end

"""List all available voices"""
@api function list_voices()
    return heygen_make_request("GET", "v1/voice.list")
end

"""Get avatar groups (categorized avatars)"""
@api function get_avatar_groups()
    return heygen_make_request("GET", "v1/avatar_group.list")
end

# ===== VIDEO GENERATION ENDPOINTS (V2) =====

"""
Create an avatar video using the v2 API

Parameters:
- video_inputs: Array of video input objects containing character, voice, and optional background
- dimension: Video dimensions (width, height)
- callback_id: Optional callback ID for webhooks
- test: Set to true for test mode (optional)
"""
@api function create_video_v2(video_inputs::Vector, dimension::Dict; 
                        callback_id=nothing, test=false)
    
    body = Dict(
        "video_inputs" => video_inputs,
        "dimension" => dimension
    )
    
    if callback_id !== nothing
        body["callback_id"] = callback_id
    end
    
    if test
        body["test"] = true
    end
    
    return heygen_make_request("POST", "v2/video/generate", body)
end

"""
Create a simple avatar video with text

Parameters:
- avatar_id: ID of the avatar to use
- voice_id: ID of the voice to use
- text: Text for the avatar to speak (max 1500 characters)
- background_color: Optional background color (hex format, e.g., "#008000")
- dimension: Optional video dimensions (defaults to 1280x720)
- voice_speed: Optional voice speed (default 1.0)
"""
@api function create_simple_video(avatar_id::String, voice_id::String, text::String;
                           background_color="#FFFFFF", dimension=Dict("width" => 1280, "height" => 720),
                           voice_speed=1.0, test=false)
    
    video_input = Dict(
        "character" => Dict(
            "type" => "avatar",
            "avatar_id" => avatar_id,
            "avatar_style" => "normal"
        ),
        "voice" => Dict(
            "type" => "text",
            "input_text" => text,
            "voice_id" => voice_id,
            "speed" => voice_speed
        ),
        "background" => Dict(
            "type" => "color",
            "value" => background_color
        )
    )
    
    return create_video_v2(config, [video_input], dimension, test=test)
end

"""
Create avatar video with audio file

Parameters:
- avatar_id: ID of the avatar to use
- audio_url: Public URL of the audio file
- background_color: Optional background color
- dimension: Optional video dimensions
"""
@api function create_video_with_audio(avatar_id::String, audio_url::String;
                                background_color="#FFFFFF", dimension=Dict("width" => 1280, "height" => 720),
                                test=false)
    
    video_input = Dict(
        "character" => Dict(
            "type" => "avatar",
            "avatar_id" => avatar_id,
            "avatar_style" => "normal"
        ),
        "voice" => Dict(
            "type" => "audio",
            "input_audio" => audio_url
        ),
        "background" => Dict(
            "type" => "color",
            "value" => background_color
        )
    )
    
    return create_video_v2(config, [video_input], dimension, test=test)
end

# ===== VIDEO STATUS AND MANAGEMENT =====

"""
Get video generation status

Parameters:
- video_id: ID of the video to check
"""
@api function get_video_status(video_id::String)
    query_params = Dict("video_id" => video_id)
    return heygen_make_request("GET", "v1/video_status.get", nothing, query_params=query_params)
end

"""
Wait for video completion and return the result

Parameters:
- video_id: ID of the video to wait for
- max_wait_time: Maximum time to wait in seconds (default 300)
- poll_interval: How often to check status in seconds (default 10)
"""
@api function wait_for_video_completion(video_id::String; 
                                 max_wait_time=300, poll_interval=10)
    
    start_time = time()
    
    while (time() - start_time) < max_wait_time
        status_response = get_video_status(config, video_id)
        status = status_response.data.status
        
        println("Video status: $status")
        
        if status == "completed"
            println("✅ Video completed successfully!")
            return status_response
        elseif status == "failed"
            error("❌ Video generation failed: $(status_response.data.error)")
        elseif status in ["processing", "pending"]
            println("⏳ Video still processing, waiting $poll_interval seconds...")
            sleep(poll_interval)
        else
            println("⚠️  Unknown status: $status")
            sleep(poll_interval)
        end
    end
    
    error("⏰ Timeout: Video did not complete within $max_wait_time seconds")
end

"""Download video file to local path"""
@api function download_video(video_url::String, local_path::String)
    try
        response = HTTP.get(video_url)
        open(local_path, "w") do file
            write(file, response.body)
        end
        println("✅ Video downloaded to: $local_path")
        return true
    catch e
        println("❌ Failed to download video: $e")
        return false
    end
end

# ===== TEMPLATE ENDPOINTS (V2) =====

"""List all available templates"""
@api function list_templates()
    return heygen_make_request("GET", "v2/templates")
end

"""
Get template details and variables

Parameters:
- template_id: ID of the template
"""
@api function get_template(template_id::String)
    return heygen_make_request("GET", "v2/template/$template_id")
end

"""
Generate video from template

Parameters:
- template_id: ID of the template to use
- variables: Dictionary of template variables to replace
- test: Set to true for test mode
"""
@api function generate_from_template(template_id::String, variables::Dict; test=false)
    body = Dict(
        "template_id" => template_id,
        "variables" => variables
    )
    
    if test
        body["test"] = true
    end
    
    return heygen_make_request("POST", "v2/template/generate", body)
end

# ===== PHOTO AVATAR ENDPOINTS =====

"""
Create a photo avatar from an image

Parameters:
- name: Name for the photo avatar
- image_url: Public URL of the person's photo
- gender: "male" or "female"
"""
@api function create_photo_avatar(name::String, image_url::String, gender::String)
    body = Dict(
        "name" => name,
        "image_url" => image_url,
        "gender" => gender
    )
    
    return heygen_make_request("POST", "v1/photo_avatar.generate", body)
end

"""
Get photo avatar status and details

Parameters:
- photo_avatar_id: ID of the photo avatar
"""
@api function get_photo_avatar(photo_avatar_id::String)
    query_params = Dict("photo_avatar_id" => photo_avatar_id)
    return heygen_make_request("GET", "v1/photo_avatar.get", nothing, query_params=query_params)
end

"""
Create video with photo avatar

Parameters:
- photo_avatar_id: ID of the photo avatar
- voice_id: ID of the voice to use
- text: Text for the avatar to speak
"""
@api function create_photo_avatar_video(photo_avatar_id::String, voice_id::String, text::String;
                                 background_color="#FFFFFF", dimension=Dict("width" => 1280, "height" => 720))
    
    video_input = Dict(
        "character" => Dict(
            "type" => "photo_avatar",
            "photo_avatar_id" => photo_avatar_id
        ),
        "voice" => Dict(
            "type" => "text",
            "input_text" => text,
            "voice_id" => voice_id
        ),
        "background" => Dict(
            "type" => "color",
            "value" => background_color
        )
    )
    
    return create_video_v2(config, [video_input], dimension)
end

# ===== VIDEO TRANSLATION ENDPOINTS =====

"""
Translate a video to another language

Parameters:
- video_url: Public URL of the video to translate
- target_language: Target language code (e.g., "es", "fr", "de")
- voice_id: Optional voice ID for the target language
"""
@api function translate_video(video_url::String, target_language::String; voice_id=nothing)
    body = Dict(
        "video_url" => video_url,
        "target_language" => target_language
    )
    
    if voice_id !== nothing
        body["voice_id"] = voice_id
    end
    
    return heygen_make_request("POST", "v1/video_translate", body)
end

"""
Get video translation status

Parameters:
- translate_id: ID of the translation job
"""
@api function get_translation_status(translate_id::String)
    query_params = Dict("translate_id" => translate_id)
    return heygen_make_request("GET", "v1/video_translate.get", nothing, query_params=query_params)
end

# ===== STREAMING API ENDPOINTS =====

"""
Create a new streaming session

Parameters:
- avatar_id: ID of the avatar for streaming
- quality: Video quality ("low", "medium", "high")
"""
@api function create_streaming_session(avatar_id::String; quality="medium")
    body = Dict(
        "version" => "v2",
        "avatar_id" => avatar_id,
        "quality" => quality
    )
    
    return heygen_make_request("POST", "v1/streaming.new", body)
end

"""
Start streaming session

Parameters:
- session_id: ID of the streaming session
"""
@api function start_streaming(session_id::String)
    body = Dict("session_id" => session_id)
    return heygen_make_request("POST", "v1/streaming.start", body)
end

"""
Send text to streaming avatar

Parameters:
- session_id: ID of the streaming session
- text: Text for the avatar to speak
"""
@api function speak_in_stream(session_id::String, text::String)
    body = Dict(
        "session_id" => session_id,
        "text" => text
    )
    
    return heygen_make_request("POST", "v1/streaming.speak", body)
end

"""
Close streaming session

Parameters:
- session_id: ID of the streaming session
"""
@api function close_streaming_session(session_id::String)
    body = Dict("session_id" => session_id)
    return heygen_make_request("POST", "v1/streaming.stop", body)
end

# ===== WEBHOOK ENDPOINTS =====

"""List all webhook endpoints"""
@api function list_webhooks()
    return heygen_make_request("GET", "v1/webhook.list")
end

"""
Create a webhook endpoint

Parameters:
- url: Your webhook URL
- events: Array of event types to subscribe to
"""
@api function create_webhook(url::String, events::Vector{String})
    body = Dict(
        "url" => url,
        "events" => events
    )
    
    return heygen_make_request("POST", "v1/webhook.add", body)
end

"""
Delete a webhook

Parameters:
- webhook_id: ID of the webhook to delete
"""
@api function delete_webhook(webhook_id::String)
    body = Dict("webhook_id" => webhook_id)
    return heygen_make_request("POST", "v1/webhook.delete", body)
end

# ===== UTILITY FUNCTIONS =====

"""Get account information and usage limits"""
@api function get_account_info()
    return heygen_make_request("GET", "v1/user.remaining_quota")
end

"""List available languages for video translation"""
@api function list_languages()
    return heygen_make_request("GET", "v1/video_translate/target_languages")
end

"""
Create a complete video workflow

This is a convenience @api function that:
1. Creates a video
2. Waits for completion
3. Returns the download URL
"""
@api function create_and_wait_for_video(avatar_id::String, voice_id::String, text::String;
                                 background_color="#FFFFFF", max_wait_time=300)
    
    println("🎬 Creating video...")
    response = create_simple_video(config, avatar_id, voice_id, text, background_color=background_color)
    video_id = response.data.video_id
    
    println("📹 Video ID: $video_id")
    println("⏳ Waiting for completion...")
    
    completed_response = wait_for_video_completion(config, video_id, max_wait_time=max_wait_time)
    
    return Dict(
        "video_id" => video_id,
        "video_url" => completed_response.data.video_url,
        "thumbnail_url" => completed_response.data.thumbnail_url,
        "duration" => completed_response.data.duration
    )
end

# ===== EXAMPLE USAGE =====

"""
Example usage:

# Initialize configuration
config = HeyGenConfig("your_api_key_here")

# List available avatars and voices
avatars = list_avatars(config)
voices = list_voices(config)

# Create a simple video
video_result = create_and_wait_for_video(
    config,
    "Daisy-inskirt-20220818",  # avatar_id
    "2d5b0e6cf36f460aa7fc47e3eee4ba54",  # voice_id
    "Welcome to HeyGen API! This is a test video created with Julia."
)

# Download the video
download_video(video_result["video_url"], "my_video.mp4")

# Create video with template
templates = list_templates(config)
template_id = templates.data.templates[1].template_id
template_video = generate_from_template(config, template_id, Dict("name" => "John"))

# Create photo avatar
photo_avatar = create_photo_avatar(config, "My Avatar", "https://example.com/photo.jpg", "male")
photo_avatar_id = photo_avatar.data.photo_avatar_id

# Create streaming session
stream = create_streaming_session(config, "avatar_id")
start_streaming(config, stream.data.session_id)
speak_in_stream(config, stream.data.session_id, "Hello from streaming!")
close_streaming_session(config, stream.data.session_id)

# Check account usage
quota = get_account_info(config)
println("Remaining quota: \$(quota.data.remaining_quota)")
"""

println("📚 HeyGen API Julia Client Loaded!")
println("🔧 Available @api functions:")
println("   Video Generation:")
println("     - create_simple_video(config, avatar_id, voice_id, text)")
println("     - create_video_with_audio(config, avatar_id, audio_url)")
println("     - create_and_wait_for_video(config, avatar_id, voice_id, text)")
println("   Resource Management:")
println("     - list_avatars(config)")
println("     - list_voices(config)")
println("     - list_templates(config)")
println("   Status Checking:")
println("     - get_video_status(config, video_id)")
println("     - wait_for_video_completion(config, video_id)")
println("   Advanced Features:")
println("     - create_photo_avatar(config, name, image_url, gender)")
println("     - translate_video(config, video_url, target_language)")
println("     - create_streaming_session(config, avatar_id)")
println("\n💡 Remember to set your API key: config = HeyGenConfig(\"your_api_key\")")