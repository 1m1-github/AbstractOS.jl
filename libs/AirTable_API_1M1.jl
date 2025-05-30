using HTTP
using JSON3

function airtable_make_request(method::String, endpoint::String, body=nothing)
    headers = [
        "Authorization" => "Bearer $(ENV["AIRTABLE_API_KEY"])",
        "Content-Type" => "application/json"
        ]
    make_HTTP_request("https://api.airtable.com/v0", endpoint, method, headers, body, query_params=Dict())
end

# ===== BASE ENDPOINTS =====

"""List all bases (requires base schema scope)"""
@api function list_bases()
    return airtable_make_request("GET", "meta/bases")
end

"""Get base schema (requires base schema scope)"""
@api function get_base_schema(base_id::String)
    return airtable_make_request("GET", "meta/bases/$base_id/tables")
end

# ===== TABLE ENDPOINTS =====

"""List all tables in a base (requires base schema scope)"""
@api function list_tables(base_id::String)
    return airtable_make_request("GET", "meta/bases/$base_id/tables")
end

"""Get table schema (requires base schema scope)"""
@api function get_table_schema(base_id::String, table_id::String)
    return airtable_make_request("GET", "meta/bases/$base_id/tables/$table_id")
end

# ===== RECORD ENDPOINTS =====

"""
List records in a table with optional filtering and pagination

Parameters:
- base_id: The base ID (starts with 'app')
- table_name: Table name or table ID
- view: Name of view to use (optional)
- fields: Array of field names to return (optional)
- filter_by_formula: Airtable formula to filter records (optional)
- max_records: Maximum number of records to return (optional, max 100)
- page_size: Number of records per page (optional, max 100)
- sort: Array of sort objects with field and direction (optional)
- offset: Pagination offset from previous response (optional)
"""
@api function list_records(base_id::String, table_name::String; 
                     view=nothing, fields=nothing, filter_by_formula=nothing, 
                     max_records=nothing, page_size=nothing, sort=nothing, offset=nothing)
    
    query_params = Dict{String,String}()
    
    if view !== nothing
        query_params["view"] = string(view)
    end
    if fields !== nothing
        for field in fields
            query_params["fields[]"] = string(field)
        end
    end
    if filter_by_formula !== nothing
        query_params["filterByFormula"] = string(filter_by_formula)
    end
    if max_records !== nothing
        query_params["maxRecords"] = string(max_records)
    end
    if page_size !== nothing
        query_params["pageSize"] = string(page_size)
    end
    if sort !== nothing
        for (i, sort_obj) in enumerate(sort)
            query_params["sort[$i][field]"] = string(sort_obj["field"])
            query_params["sort[$i][direction]"] = string(sort_obj["direction"])
        end
    end
    if offset !== nothing
        query_params["offset"] = string(offset)
    end
    
    return airtable_make_request("GET", "$base_id/$table_name", nothing, query_params=query_params)
end

"""Get all records from a table (handles pagination automatically)"""
@api function get_all_records(base_id::String, table_name::String; kwargs...)
    all_records = []
    offset = nothing
    
    while true
        response = list_records(config, base_id, table_name; offset=offset, kwargs...)
        append!(all_records, response.records)
        
        # Check if there are more pages
        if haskey(response, :offset)
            offset = response.offset
        else
            break
        end
    end
    
    return all_records
end

"""Get a specific record by ID"""
@api function get_record(base_id::String, table_name::String, record_id::String)
    return airtable_make_request("GET", "$base_id/$table_name/$record_id")
end

"""
Create new records in a table

Parameters:
- records: Array of record objects with 'fields' containing the data
"""
@api function create_records(base_id::String, table_name::String, records::Vector)
    body = Dict("records" => records)
    return airtable_make_request("POST", "$base_id/$table_name", body)
end

"""Create a single record"""
@api function create_record(base_id::String, table_name::String, fields::Dict)
    records = [Dict("fields" => fields)]
    response = create_records(config, base_id, table_name, records)
    return response.records[1]  # Return just the created record
end

"""
Update existing records

Parameters:
- records: Array of record objects with 'id' and 'fields'
- typecast: Whether to enable automatic data conversion (optional)
"""
@api function update_records(base_id::String, table_name::String, records::Vector; typecast=false)
    body = Dict("records" => records)
    if typecast
        body["typecast"] = true
    end
    return airtable_make_request("PATCH", "$base_id/$table_name", body)
end

"""Update a single record"""
@api function update_record(base_id::String, table_name::String, record_id::String, fields::Dict; typecast=false)
    records = [Dict("id" => record_id, "fields" => fields)]
    response = update_records(config, base_id, table_name, records, typecast=typecast)
    return response.records[1]  # Return just the updated record
end

"""
Replace records (PUT operation - replaces all fields)

Parameters:
- records: Array of record objects with 'id' and 'fields'
"""
@api function replace_records(base_id::String, table_name::String, records::Vector)
    body = Dict("records" => records)
    return airtable_make_request("PUT", "$base_id/$table_name", body)
end

"""Replace a single record (PUT operation)"""
@api function replace_record(base_id::String, table_name::String, record_id::String, fields::Dict)
    records = [Dict("id" => record_id, "fields" => fields)]
    response = replace_records(config, base_id, table_name, records)
    return response.records[1]  # Return just the replaced record
end

"""
Delete records

Parameters:
- record_ids: Array of record IDs to delete
"""
@api function delete_records(base_id::String, table_name::String, record_ids::Vector{String})
    query_params = Dict{String,String}()
    for record_id in record_ids
        query_params["records[]"] = record_id
    end
    
    return airtable_make_request("DELETE", "$base_id/$table_name", nothing, query_params=query_params)
end

"""Delete a single record"""
@api function delete_record(base_id::String, table_name::String, record_id::String)
    return delete_records(config, base_id, table_name, [record_id])
end

# ===== WEBHOOK ENDPOINTS (requires OAuth token) =====

"""List webhooks for a base"""
@api function list_webhooks(base_id::String)
    return airtable_make_request("GET", "$base_id/webhooks")
end

"""Create a webhook"""
@api function create_webhook(base_id::String, notification_url::String, specification::Dict)
    body = Dict(
        "notificationUrl" => notification_url,
        "specification" => specification
    )
    return airtable_make_request("POST", "$base_id/webhooks", body)
end

"""Get webhook details"""
@api function get_webhook(base_id::String, webhook_id::String)
    return airtable_make_request("GET", "$base_id/webhooks/$webhook_id")
end

"""Update webhook"""
@api function update_webhook(base_id::String, webhook_id::String, notification_url::String, specification::Dict)
    body = Dict(
        "notificationUrl" => notification_url,
        "specification" => specification
    )
    return airtable_make_request("PATCH", "$base_id/webhooks/$webhook_id", body)
end

"""Delete webhook"""
@api function delete_webhook(base_id::String, webhook_id::String)
    return airtable_make_request("DELETE", "$base_id/webhooks/$webhook_id")
end

"""Refresh webhook (required every 7 days)"""
@api function refresh_webhook(base_id::String, webhook_id::String)
    return airtable_make_request("POST", "$base_id/webhooks/$webhook_id/refresh")
end

"""List webhook payloads"""
@api function list_webhook_payloads(base_id::String, webhook_id::String; cursor=nothing, limit=nothing)
    query_params = Dict{String,String}()
    if cursor !== nothing
        query_params["cursor"] = string(cursor)
    end
    if limit !== nothing
        query_params["limit"] = string(limit)
    end
    
    return airtable_make_request("GET", "$base_id/webhooks/$webhook_id/payloads", nothing, query_params=query_params)
end

# ===== COMMENT ENDPOINTS (requires OAuth token) =====

"""List comments on a record"""
@api function list_comments(base_id::String, table_name::String, record_id::String; offset=nothing, page_size=nothing)
    query_params = Dict{String,String}()
    if offset !== nothing
        query_params["offset"] = string(offset)
    end
    if page_size !== nothing
        query_params["pageSize"] = string(page_size)
    end
    
    return airtable_make_request("GET", "$base_id/$table_name/$record_id/comments", nothing, query_params=query_params)
end

"""Create a comment on a record"""
@api function create_comment(base_id::String, table_name::String, record_id::String, text::String)
    body = Dict("text" => text)
    return airtable_make_request("POST", "$base_id/$table_name/$record_id/comments", body)
end

"""Update a comment"""
@api function update_comment(base_id::String, table_name::String, record_id::String, comment_id::String, text::String)
    body = Dict("text" => text)
    return airtable_make_request("PATCH", "$base_id/$table_name/$record_id/comments/$comment_id", body)
end

"""Delete a comment"""
@api function delete_comment(base_id::String, table_name::String, record_id::String, comment_id::String)
    return airtable_make_request("DELETE", "$base_id/$table_name/$record_id/comments/$comment_id")
end

# ===== UTILITY FUNCTIONS =====

"""
Upload attachment to Airtable
Note: This is a two-step process - first upload to a temporary URL, then reference in a record
"""
@api function upload_attachment(file_path::String, filename::String)
    # This is a simplified version - actual implementation would handle file upload
    # For now, this returns the structure expected by Airtable
    return Dict(
        "url" => "https://example.com/uploads/$(filename)",
        "filename" => filename,
        "type" => "image/jpeg"  # You'd detect this from the file
    )
end

"""Extract base ID from an Airtable URL"""
@api function extract_base_id(url::String)
    # Extract base ID from URLs like https://airtable.com/appXXXXXXXXXXXXXX
    match_result = match(r"app[a-zA-Z0-9]{14}", url)
    return match_result !== nothing ? match_result.match : nothing
end

"""Extract record ID from an Airtable URL"""
@api function extract_record_id(url::String)
    # Extract record ID from URLs
    match_result = match(r"rec[a-zA-Z0-9]{14}", url)
    return match_result !== nothing ? match_result.match : nothing
end
