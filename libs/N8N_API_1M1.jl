using HTTP
using JSON3

function n8n_make_request(method::String, endpoint::String, body=nothing)
    headers = [
        "X-N8N-API-KEY" => ENV["N8N_API_KEY"],
        "Content-Type" => "application/json",
        "Accept" => "application/json"
    ]
    make_HTTP_request("https://thepromiseai.app.n8n.cloud/api/v1", endpoint, method, headers, body, query_params=Dict())

end

# ===== WORKFLOW ENDPOINTS =====

"""Get all workflows"""
@api function get_workflows()
    n8n_make_request("GET", "workflows")
end

"""Get a specific workflow by ID"""
@api function get_workflow(workflow_id::String)
    return n8n_make_request("GET", "workflows/$workflow_id")
end

"""Create a new workflow"""
@api function create_workflow(workflow_data::Dict)
    for k ∈ keys(workflow_data)
        k ∈ ["name", "nodes", "connections", "settings", "staticData"] && continue
        delete!(workflow_data, k)
    end
    return n8n_make_request("POST", "workflows", workflow_data)
end

"""Update an existing workflow"""
@api function update_workflow(workflow_id::String, workflow_data::Dict)
    return n8n_make_request("PUT", "workflows/$workflow_id", workflow_data)
end

"""Delete a workflow"""
@api function delete_workflow(workflow_id::String)
    return n8n_make_request("DELETE", "workflows/$workflow_id")
end

"""Activate a workflow"""
@api function activate_workflow(workflow_id::String)
    return n8n_make_request("POST", "workflows/$workflow_id/activate")
end

"""Deactivate a workflow"""
@api function deactivate_workflow(workflow_id::String)
    return n8n_make_request("POST", "workflows/$workflow_id/deactivate")
end

@api function transfer_workflow_to_project(workflow_id::String, project_id::String)
    body = Dict(
        "destinationProjectId" => project_id
    )
    return n8n_make_request("PUT", "workflows/$workflow_id/transfer", body)
end

"""Execute a workflow (manual trigger)"""
@api function execute_workflow(workflow_id::String, input_data=nothing)
    endpoint = "workflows/$workflow_id/execute"
    body = input_data !== nothing ? Dict("data" => input_data) : nothing
    return n8n_make_request("POST", endpoint, body)
end

# ===== EXECUTION ENDPOINTS =====

"""Get all executions"""
@api function get_executions(; limit::Int=20, offset::Int=0)
    endpoint = "executions?limit=$limit&offset=$offset"
    return n8n_make_request("GET", endpoint)
end

"""Get executions for a specific workflow"""
@api function get_workflow_executions(workflow_id::String; limit::Int=20, offset::Int=0)
    endpoint = "executions?workflowId=$workflow_id&limit=$limit&offset=$offset"
    return n8n_make_request("GET", endpoint)
end

"""Get a specific execution by ID"""
@api function get_execution(execution_id::String)
    return n8n_make_request("GET", "executions/$execution_id")
end

"""Delete an execution"""
@api function delete_execution(execution_id::String)
    return n8n_make_request("DELETE", "executions/$execution_id")
end

"""Stop a running execution"""
@api function stop_execution(execution_id::String)
    return n8n_make_request("POST", "executions/$execution_id/stop")
end

# ===== CREDENTIAL ENDPOINTS =====

"""Get a specific credential by ID"""
@api function get_credential(credentialTypeName::String)
    return n8n_make_request("GET", "credentials/schema/$credentialTypeName")
end

"""Create a new credential"""
@api function create_credential(credential_data::Dict)
    return n8n_make_request("POST", "credentials", credential_data)
end

"""Update an existing credential"""
@api function update_credential(credential_id::String, credential_data::Dict)
    return n8n_make_request("PUT", "credentials/$credential_id", credential_data)
end

"""Delete a credential"""
@api function delete_credential(credential_id::String)
    return n8n_make_request("DELETE", "credentials/$credential_id")
end

# ===== NODE ENDPOINTS =====

"""Get available node types"""
@api function get_node_types()
    return n8n_make_request("GET", "node-types")
end

"""Get information about a specific node type"""
@api function get_node_type(node_type::String)
    return n8n_make_request("GET", "node-types/$node_type")
end

# ===== USER/AUTH ENDPOINTS =====

"""Get current user information"""
@api function get_current_user()
    return n8n_make_request("GET", "me")
end

"""Get all users (admin only)"""
@api function get_users()
    return n8n_make_request("GET", "users")
end

# ===== HEALTH/STATUS ENDPOINTS =====

"""Check API health/status"""
@api function get_health()
    return n8n_make_request("GET", "health")
end

"""Get n8n version information"""
@api function get_version()
    return n8n_make_request("GET", "version")
end

# ===== WEBHOOK ENDPOINTS =====

"""Get webhook information for a workflow"""
@api function get_workflow_webhooks(workflow_id::String)
    return n8n_make_request("GET", "workflows/$workflow_id/webhooks")
end

# ===== PROJECT ENDPOINTS =====

@api function create_project(project_name)
    project_data = Dict(
        "name" => project_name
    )
    return n8n_make_request("POST", "projects", project_data)
end

@api get_projects() = n8n_make_request("GET", "projects")

@api function delete_project(project_id::String)
    return n8n_make_request("DELETE", "projects/$project_id")
end

@api function update_credential(project_id::String, project_name)
    project_data = Dict(
        "name" => project_name
    )
    return n8n_make_request("PUT", "projects/$project_id", project_data)
end
