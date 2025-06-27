# N8N, AirTable, HeyGen, Slack, GoHighLevel

using HTTP
using JSON
using Dates

ENV["N8N_API_KEY"] = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0OGZiYTZiOS1lZDVlLTRmZGUtYThkNi0xMTljNWJhMTNlZmUiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQ4ODA1Mjk0LCJleHAiOjE3NTEzNTMyMDB9.go01SWLSiKEILWC-pKT0BJJu2kxmF1XSNgAJHxJYyAs"
ENV["HEYGEN_API_KEY"] = "MTNmOGU4ODliZTZlNGE4MmE4MTIzMzUyZWFmYjZlYjgtMTc0OTA3OTk2Nw=="
ENV["AIRTABLE_PERSONAL_ACCESS_TOKEN"] = "patXloSZb2dgIRW65.4ecb1a1cf5c554cf006b621503b0990092f0a404f3c84ca08b99ffd13fa57beb"

# airtable
create_kgu_executive_base()
airtable_base_id = "appWALa05qLYVCy5w"

credential=get_credential("airtableTokenApi")

# airtable credentials in n8n
airtable_credential_data = Dict(
  "name" => "Airtable_API",
  "type" => "airtableTokenApi",
  "data" => Dict(
    "accessToken" => ENV["AIRTABLE_PERSONAL_ACCESS_TOKEN"]
  )
)
# Airtable PAT, ffRh8UTjaVZSK7EM
create_credential(airtable_credential_data)
airtable_credential_id = "Qhu9d0psOUwpEXVf"
heygen_credential_data = Dict(
  "name" => "HeyGen_API",
  "type" => "httpHeaderAuth",
  "data" => Dict(
    "name" => "X-API-KEY",
    "value" => ENV["HEYGEN_API_KEY"]
  )
)
create_credential(heygen_credential_data)
# heygen_credential_id = "eVSJInjatBODdomc"

# n8n
delete_all_workflows()
projects = list_all_projects()
delete_all_projects()
project_name = "KGU C Suite"
project = create_project(project_name)
project_id = project["id"]

TGU_dir = "/Users/1m1/Documents/TGU"
package_file_path = joinpath(TGU_dir, "all_15_workflows.json")
package_data = JSON3.read(read(package_file_path, String))
workflows_data = package_data["kgu_international_complete_workflow_package"]["workflows"]

workflow_key = "workflow_01"
for workflow_key in keys(workflows_data)
@show workflow_key
workflow_info = workflows_data[workflow_key]
workflow_content = workflow_info["workflow_content"]
# workflow_filename = joinpath(TGU_dir, workflow_info["filename"])
workflow_filename = joinpath(TGU_dir, "$(workflow_key).json")
workflow_data = JSON3.read(read(workflow_filename, String), Dict)
for node in workflow_data["nodes"]
    node["type"] ≠ "n8n-nodes-base.airtable" && continue
    node["parameters"]["application"] = airtable_base_id
    node["credentials"] = Dict(
        "airtableTokenApi" => Dict(
            "id" => "ffRh8UTjaVZSK7EM",
            "name" => "Airtable PAT"
        )
    )
end
created_workflow = create_workflow(workflow_data)
workflow_id = created_workflow[:id]
transfer_workflow_to_project(workflow_id, project_id)
activate_workflow(workflow_id)
end

workflow = get_workflow("Sx0x11ii6q9GyUjF")
workflow[:nodes][2][:credentials]
workflow[:nodes][2][:credentials][:airtableTokenApi]


## functions

function delete_all_workflows()
    workflows = get_workflows()[:data]
    for workflow in workflows
        workflow_id = workflow[:id]
        delete_workflow(workflow_id)
    end
end

list_all_projects() = get_projects()[:data]

function delete_all_projects()
    projects = list_all_projects()
    for project in projects
        project_id = project["id"]
        try 
            delete_project(project_id)
        catch e @show e end
    end
end

function create_kgu_executive_base()
    """
    Creates the KGU_Executive base with Strategic_Decisions and Executive_Reports tables
    
    Note: Base creation via API requires Enterprise plan. 
    If you don't have Enterprise, create the base manually first, then run setup_tables()
    """
    
    base_data = Dict(
        "name" => "KGU_Executive",
        "tables" => [
            create_strategic_decisions_table_schema(),
            create_executive_reports_table_schema()
        ],
        "workspaceId" =>"wspE1LkfqqpQzgln0"
    )
    
    try
        response = airtable_make_request(config, "POST", "meta/bases", base_data)
        println("✅ Base created successfully!")
        println("Base ID: $(response.id)")
        println("Base URL: https://airtable.com/$(response.id)")
        return response.id
    catch e
        println("❌ Base creation failed: $e")
        println("💡 If you don't have Enterprise plan, create the base manually and use setup_tables() instead")
        return nothing
    end
end

function create_strategic_decisions_table_schema()
    """Creates the schema for Strategic_Decisions table"""
    return Dict(
        "name" => "Strategic_Decisions",
        "description" => "Executive-level strategic decisions requiring CEO review and board approval",
        "fields" => [
            Dict(
                "name" => "Decision_Title",
                "type" => "singleLineText",
                "description" => "Brief title describing the strategic decision"
            ),
            Dict(
                "name" => "Decision_Category",
                "type" => "singleSelect",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "Market_Expansion", "color" => "blueLight2"),
                        Dict("name" => "Product_Launch", "color" => "greenLight2"),
                        Dict("name" => "Strategic_Partnership", "color" => "purpleLight2"),
                        Dict("name" => "Investment_Decision", "color" => "orangeLight2"),
                        Dict("name" => "Organizational_Change", "color" => "redLight2")
                    ]
                )
            ),
            Dict(
                "name" => "Requested_By",
                "type" => "singleLineText",
                "description" => "Name or department of the person requesting the decision"
            ),
            Dict(
                "name" => "Business_Impact",
                "type" => "multilineText",
                "description" => "Detailed description of expected business impact"
            ),
            Dict(
                "name" => "Investment_Required",
                "type" => "currency",
                "options" => Dict(
                    "symbol" => "\$",
                    "precision" => 0
                )
            ),
            Dict(
                "name" => "Timeline",
                "type" => "singleLineText",
                "description" => "Expected implementation timeline"
            ),
            Dict(
                "name" => "Stakeholders",
                "type" => "multipleSelects",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "Board", "color" => "redLight2"),
                        Dict("name" => "Investors", "color" => "orangeLight2"),
                        Dict("name" => "Employees", "color" => "blueLight2"),
                        Dict("name" => "Customers", "color" => "greenLight2"),
                        Dict("name" => "Partners", "color" => "purpleLight2")
                    ]
                )
            ),
            Dict(
                "name" => "Risk_Assessment",
                "type" => "singleSelect",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "Low", "color" => "greenLight2"),
                        Dict("name" => "Medium", "color" => "yellowLight2"),
                        Dict("name" => "High", "color" => "orangeLight2"),
                        Dict("name" => "Critical", "color" => "redLight2")
                    ]
                )
            ),
            Dict(
                "name" => "Priority",
                "type" => "singleSelect",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "Low", "color" => "grayLight2"),
                        Dict("name" => "Medium", "color" => "yellowLight2"),
                        Dict("name" => "High", "color" => "orangeLight2"),
                        Dict("name" => "Critical", "color" => "redLight2")
                    ]
                )
            ),
            Dict(
                "name" => "Status",
                "type" => "singleSelect",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "CEO_Review", "color" => "yellowLight2"),
                        Dict("name" => "CEO_Decided", "color" => "blueLight2"),
                        Dict("name" => "Board_Approval", "color" => "purpleLight2"),
                        Dict("name" => "Implementation", "color" => "orangeLight2"),
                        Dict("name" => "Completed", "color" => "greenLight2")
                    ]
                )
            ),
            Dict(
                "name" => "CEO_Decision",
                "type" => "multilineText",
                "description" => "CEO's decision and rationale"
            ),
            Dict(
                "name" => "Decision_Complexity",
                "type" => "singleSelect",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "Executive_Level", "color" => "blueLight2"),
                        Dict("name" => "Board_Level", "color" => "redLight2")
                    ]
                )
            ),
            Dict(
                "name" => "Session_ID",
                "type" => "singleLineText",
                "description" => "Unique identifier for the AI session"
            ),
            Dict(
                "name" => "Decision_Date",
                "type" => "date",
                "options" => Dict(
                    "dateFormat" => Dict("name" => "us")
                )
            ),
            Dict(
                "name" => "Request_Date",
                "type" => "date",
                "options" => Dict(
                    "dateFormat" => Dict("name" => "us")
                )
            )
        ]
    )
end

function create_executive_reports_table_schema()
    """Creates the schema for Executive_Reports table"""
    return Dict(
        "name" => "Executive_Reports",
        "description" => "Executive reports and briefings for leadership team",
        "fields" => [
            Dict(
                "name" => "Report_Date",
                "type" => "date",
                "options" => Dict(
                    "dateFormat" => Dict("name" => "us")
                )
            ),
            Dict(
                "name" => "Report_Type",
                "type" => "singleSelect",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "CEO_Executive_Briefing", "color" => "blueLight2"),
                        Dict("name" => "Board_Preparation", "color" => "purpleLight2"),
                        Dict("name" => "Strategic_Review", "color" => "greenLight2")
                    ]
                )
            ),
            Dict(
                "name" => "Revenue",
                "type" => "currency",
                "options" => Dict(
                    "symbol" => "\$",
                    "precision" => 0
                )
            ),
            Dict(
                "name" => "Profit_Margin",
                "type" => "number",
                "options" => Dict(
                    "precision" => 2
                ),
                "description" => "Profit margin as percentage"
            ),
            Dict(
                "name" => "Market_Share",
                "type" => "number",
                "options" => Dict(
                    "precision" => 2
                ),
                "description" => "Market share as percentage"
            ),
            Dict(
                "name" => "Strategic_Health",
                "type" => "singleSelect",
                "options" => Dict(
                    "choices" => [
                        Dict("name" => "Excellent", "color" => "greenLight2"),
                        Dict("name" => "Strong", "color" => "blueLight2"),
                        Dict("name" => "Requires_Attention", "color" => "redLight2")
                    ]
                )
            ),
            Dict(
                "name" => "Session_ID",
                "type" => "singleLineText",
                "description" => "Unique identifier for the AI session"
            ),
            Dict(
                "name" => "Executive_Briefing",
                "type" => "multilineText",
                "description" => "Detailed executive briefing content"
            )
        ]
    )
end