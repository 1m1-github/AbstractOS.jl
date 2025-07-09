# set 
# ENV["ABSTRACTOS_HTTP_IP"]
# ENV["ABSTRACTOS_HTTP_PORT"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
# ENV["ABSTRACTOS_WEBSOCKET_PORT"]

@api const BrowserHTTPServerDescription = """
runs an HTTP server that serves the current_html adding a content div (id `content_1M1`), an input div (id `input_1M1`) to receive text input from the browser and a signals div (id `signals_1M1`) to show the user `signals`.
if the query param with key `julia` is set, the value is `eval`ed verbatim.
# """

using HTTP

function find_julia_code_http_query_param(query_param)
    query_param = HTTP.unescapeuri(query_param)
    !startswith(query_param, "/?") && return ""
    query_params = split(query_param[length("/?")+1:end], '&')
    julia_query_param = filter(qp -> startswith(qp, "julia="), query_params)
    isempty(julia_query_param) && return ""
    first(julia_query_param)[length("julia=")+1:end]
end

function add_input_and_avatar_to_html!(html)
    global signals
    # !contains(html, """<div id="content_1M1\"""") && content_html = """<div id="content_1M1"></div>"""
    content_html = """<div id="content_1M1"></div>"""
    input_html = read("libs/BrowserInputDiv_1M1.html", String)
    input_html = replace(input_html, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    # avatar_html = read("libs/BrowserHeyGenAvatarDiv_1M1.html", String)
    # avatar_html = replace(avatar_html, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    signals_html = """<div id="signals_1M1" style="position: fixed; top: 0; left: 0; width: 100%; background: #f0f0f0; border-bottom: 1px solid #ccc; padding: 8px 16px; z-index: 1000; font-family: Arial, sans-serif;">$signals</div>"""
    replace(html, init_body_start_tag => "$(init_body_start_tag)$(signals_html)$(input_html)")
    replace(html, init_body_start_tag => "$(init_body_start_tag)$(signals_html)$(input_html)$(content_html)")
    # replace(html, "<body>" => "<body>$(signals_html)$(input_html)$(content_html)")
    # replace(html, "<body>" => "<body>$(signals_html)$(input_html)$(content_html)$(avatar_html)")
end

init_body_start_tag = """<body style="padding-top:40px">"""
current_html = """<html>$(init_body_start_tag)</body></html>"""
function handle_http_request(req)
    @show "handle_http_request", req.target, current_html # DEBUG
    global current_html
    current_html = add_input_and_avatar_to_html!(current_html)
    @show current_html # DEBUG
    julia_code = find_julia_code_http_query_param(req.target)
    @show julia_code # DEBUG
    isempty(julia_code) && return HTTP.Response(200, current_html)
    julia_response = string(eval(Meta.parse(julia_code)))
    @show julia_response # DEBUG
    current_html = replace(current_html, "<body>" => """<body><div id="julia_response">$(julia_response)</div>""")
    @show current_html # DEBUG
    HTTP.Response(200, current_html)
end
@async HTTP.serve(handle_http_request, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))
# @api start_http_server(handle_http_request, host, port) = @async HTTP.serve(handle_http_request, host, port)
