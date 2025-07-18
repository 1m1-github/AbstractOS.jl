# set 
# ENV["ABSTRACTOS_HTTP_IP"]
# ENV["ABSTRACTOS_HTTP_PORT"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
# ENV["ABSTRACTOS_WEBSOCKET_PORT"]

@api const BrowserHTTPServerDescription = """
runs an HTTP server that serves the current html consisting of a content div (id `content_1M1`), an input div (id `input_1M1`) to receive text input from the browser and a signals div (id `signals_1M1`) to show the user `signals`.
if the query param with key `julia` is set, the value is `eval`ed verbatim.
# """

using HTTP

content_1M1 = ""
body_start_tag = """<body style="padding-top:40px">"""
base_html = """<!DOCTYPE html><head><meta charset="UTF-8"></head>$(body_start_tag)</body></html>"""

function find_julia_code_http_query_param(query_param)
    query_param = HTTP.unescapeuri(query_param)
    !startswith(query_param, "/?") && return ""
    query_params = split(query_param[length("/?")+1:end], '&')
    julia_query_param = filter(qp -> startswith(qp, "julia="), query_params)
    isempty(julia_query_param) && return ""
    first(julia_query_param)[length("julia=")+1:end]
end

function add_avatar(html)
    @debug length(html)
    global body_start_tag
    avatar_html = read("libs/BrowserHeyGenAvatarDiv_1M1.html", String)
    avatar_html = replace(avatar_html, """ENV["HEYGEN_API_KEY"]""" => ENV["HEYGEN_API_KEY"])
    replace(html, body_start_tag => "$(body_start_tag)$(avatar_html)")
end

function add_input(html)
    @debug length(html)
    global body_start_tag
    input_html = read("libs/BrowserInputDiv_1M1.html", String)
    input_html = replace(input_html, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    replace(html, body_start_tag => "$(body_start_tag)$(input_html)")
end

function add_content(html)
    @debug length(html)
    global body_start_tag, content_1M1
    @debug length(content_1M1)
    content_html = """<div id="content_1M1">$(content_1M1)</div>"""
    replace(html, body_start_tag => "$(body_start_tag)$(content_html)")
end

function add_signals(html)
    @debug length(html)
    global body_start_tag, signals
    signals_html = """<div id="signals_1M1" style="position: fixed; top: 0; left: 0; width: 100%; background: #f0f0f0; border-bottom: 1px solid #ccc; padding: 8px 16px; z-index: 1000; font-family: Arial, sans-serif;">$signals</div>"""
    replace(html, body_start_tag => "$(body_start_tag)$(signals_html)")
end

function create_html()
    global base_html
    html = deepcopy(base_html)
    html = add_input(html)
    html = add_signals(html)
    html = add_content(html)
    # add_avatar(html)
end

function handle_http_request(req)
    @debug req.target # DEBUG
    req.target == "/.well-known/appspecific/com.chrome.devtools.json" && return HTTP.Response(200, ["Content-Type" => "application/json"], "[]")
    req.target == "/favicon.ico" && return HTTP.Response(200, ["Content-Type" => "image/x-icon"], read("favicon.ico"))
    julia_code = find_julia_code_http_query_param(req.target)
    @debug julia_code # DEBUG
    headers = ["Content-Security-Policy" => "script-src 'self' 'unsafe-inline' 'unsafe-eval' 127.0.0.1"]
    if !isempty(julia_code)
        julia_response = ""
        try
            julia_response = string(eval(Meta.parse(julia_code)))
            julia_response = replace(julia_response, '`' => ''')
        catch e
            julia_response = "$e"
        end
        @debug julia_response # DEBUG
        global base_html
        html = deepcopy(base_html)
        html = add_input(html)
        html = add_signals(html)
        julia_response_html = """<script>document.getElementById('content_1M1').textContent=`$(julia_response)`</script>"""
        html = replace(html, body_start_tag => "$(body_start_tag)$(julia_response_html)")
        content_html = """<div id="content_1M1"></div>"""
        html = replace(html, body_start_tag => "$(body_start_tag)$(content_html)")
        @debug "julia_response html", html
        return HTTP.Response(200, headers, html)
    end
    html = create_html()
    @debug html
    HTTP.Response(200, headers, html)
end
@async HTTP.serve(handle_http_request, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))
