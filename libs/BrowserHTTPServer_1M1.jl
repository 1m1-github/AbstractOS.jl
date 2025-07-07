# set 
# ENV["ABSTRACTOS_HTTP_IP"]
# ENV["ABSTRACTOS_HTTP_PORT"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"]
# ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]
# ENV["ABSTRACTOS_WEBSOCKET_PORT"]

@api const BrowserHTTPServerDescription = """
runs an HTTP server with html that shows the `signals` on the very top of the browser,

# """

using HTTP

create_base_http_html(signals, content, input, avatar) = replace(current_html, "<html>" => """<html><body>$signals$content$input$avatar</body></html>""")
create_base_http_html() = create_base_http_html("", "", "", "")
current_html = create_base_http_html()

function handle_http_request(req)
    global current_html
    # current_html = create_html(req.target)
    HTTP.Response(200, current_html)
end
@async HTTP.serve(handle_http_request, ENV["ABSTRACTOS_HTTP_IP"], parse(Int, ENV["ABSTRACTOS_HTTP_PORT"]))
# @api start_http_server(handle_http_request, host, port) = @async HTTP.serve(handle_http_request, host, port)

function find_julia_code_http_query_param(query_param)
    query_param = HTTP.unescapeuri(query_param)
    !startswith(query_param, "/?") && return ""
    query_params = split(query_param[length("/?")+1:end], '&')
    julia_query_param = filter(qp -> startswith(qp, "julia="), query_params)
    isempty(julia_query_param) && return ""
    first(julia_query_param)[length("julia=")+1:end]
end

function create_base_http_html(target)
    input = read("libs/BrowserInputDiv_1M1.html", String)
    input = replace(input, """\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://\$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):\$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""" => """$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL"])://$(ENV["ABSTRACTOS_OUTER_WEBSOCKET_IP"]):$(ENV["ABSTRACTOS_WEBSOCKET_PORT"])""")
    julia_code = find_julia_code_http_query_param(target)
    global current_html
    content = isempty(julia_code) ? current_html : string(eval(Meta.parse(julia_code)))
    content = """<div id="content">$content</div>"""
    signals = """<div id="signals_next_running" style="display: inline-block; background-color: #ff4444; color: white; width: 40px; height: 40px; border-radius: 50%; text-align: center; line-height: 40px; font-size: 24px; font-weight: bold; box-shadow: 0 2px 5px rgba(0,0,0,0.2); margin: 10px;">✕</div>"""
    create_base_http_html(signals, content, input, avatar)
end
