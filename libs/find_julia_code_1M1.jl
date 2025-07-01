function find_julia_code(query_param)
    query_param = HTTP.unescapeuri(query_param)
    !startswith(query_param, "/?") && return ""
    query_params = split(query_param[length("/?")+1:end], '&')
    julia_query_param = filter(qp -> startswith(qp, "julia="), query_params)
    isempty(julia_query_param) && return ""
    first(julia_query_param)[length("julia=")+1:end]
end