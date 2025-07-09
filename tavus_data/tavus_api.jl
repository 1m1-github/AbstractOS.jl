using HTTP, JSON3

@api struct TavusAPI
    api_key::String
    base_url::String
end

@api function TavusAPI(api_key::String)
    TavusAPI(api_key, "https://tavusapi.com")
end

@api function create_replica(tavus::TavusAPI, video_url::String; replica_name::String="")
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    body = Dict(
        "video_url" => video_url,
        "replica_name" => replica_name
    )
    
    response = HTTP.post(
        "$(tavus.base_url)/v2/replicas",
        headers,
        JSON3.write(body)
    )
    
    return JSON3.read(response.body)
end

@api function get_replica(tavus::TavusAPI, replica_id::String)
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    response = HTTP.get(
        "$(tavus.base_url)/v2/replicas/$replica_id",
        headers
    )
    
    return JSON3.read(response.body)
end

@api function list_replicas(tavus::TavusAPI)
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    response = HTTP.get(
        "$(tavus.base_url)/v2/replicas",
        headers
    )
    
    return JSON3.read(response.body)
end

@api function delete_replica(tavus::TavusAPI, replica_id::String)
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    response = HTTP.delete(
        "$(tavus.base_url)/v2/replicas/$replica_id",
        headers
    )
    
    return JSON3.read(response.body)
end

@api function generate_video(tavus::TavusAPI, replica_id::String, script::String; 
                            background_url::String="", 
                            properties::Dict=Dict())
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    body = Dict(
        "replica_id" => replica_id,
        "script" => script
    )
    
    if !isempty(background_url)
        body["background_url"] = background_url
    end
    
    if !isempty(properties)
        body["properties"] = properties
    end
    
    response = HTTP.post(
        "$(tavus.base_url)/v2/videos",
        headers,
        JSON3.write(body)
    )
    
    return JSON3.read(response.body)
end

@api function get_video(tavus::TavusAPI, video_id::String)
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    response = HTTP.get(
        "$(tavus.base_url)/v2/videos/$video_id",
        headers
    )
    
    return JSON3.read(response.body)
end

@api function list_videos(tavus::TavusAPI)
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    response = HTTP.get(
        "$(tavus.base_url)/v2/videos",
        headers
    )
    
    return JSON3.read(response.body)
end

@api function delete_video(tavus::TavusAPI, video_id::String)
    headers = [
        "Authorization" => "Bearer $(tavus.api_key)",
        "Content-Type" => "application/json"
    ]
    
    response = HTTP.delete(
        "$(tavus.base_url)/v2/videos/$video_id",
        headers
    )
    
    return JSON3.read(response.body)
end

@api function wait_for_replica_ready(tavus::TavusAPI, replica_id::String; max_wait_seconds::Int=300)
    start_time = time()
    while time() - start_time < max_wait_seconds
        replica_info = get_replica(tavus, replica_id)
        if replica_info["status"] == "ready"
            return true
        elseif replica_info["status"] == "failed"
            error("Replica creation failed: $(replica_info)")
        end
        sleep(10)
    end
    return false
end

@api function wait_for_video_ready(tavus::TavusAPI, video_id::String; max_wait_seconds::Int=300)
    start_time = time()
    while time() - start_time < max_wait_seconds
        video_info = get_video(tavus, video_id)
        if video_info["status"] == "completed"
            return video_info
        elseif video_info["status"] == "failed"
            error("Video generation failed: $(video_info)")
        end
        sleep(10)
    end
    return false
end

@api TavusAPIDescription = "Tavus API wrapper for creating AI video replicas and generating videos. Main workflow: 1. Create TavusAPI instance with API key 2. Create replica using create_replica() 3. Wait for replica readiness 4. Generate videos using generate_video() 5. Wait for video completion. Key functions: TavusAPI(api_key), create_replica(), generate_video(), get_replica(), get_video(), wait_for_replica_ready(), wait_for_video_ready(). All functions return parsed JSON responses."
