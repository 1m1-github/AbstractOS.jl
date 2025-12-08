state(code::JuliaCode) = eval(Meta.parse(code))
function state_lines(name::JuliaCode,body::JuliaCode)
    results = ["$name BEGIN"]
    if !isempty(body)
        push!(results, body)
    end
    push!(results, "$name END")
    join(results, '\n')
end
function state_key_values(d::Dict{JuliaCode,T}) where T
    results = []
    for (k, p) in d
        state_string = ""
        try state_string = state(p) catch _ end
        full_string = """"$k"=>$state_string"""
        push!(results, full_string)
    end
    join(results, ',')
end
state(inputs::Dict{JuliaCode,InputPeripheral}) = state_lines("INPUTS", state_key_values(inputs))
state(outputs::Dict{JuliaCode,OutputPeripheral}) = state_lines("OUTPUTS", state_key_values(outputs))
state(signals::Dict{JuliaCode,Bool}) = "SIGNALS BEGIN\n" * join(map(what -> """"$what"=>$(signals[what])""", collect(keys(signals))), ',') * "\nSIGNALS END"
state(action::Action) = """who="$(action.who)",what="$(action.what)\",how_summary="$(action.how_summary)\""""
state(task::Task) = "istaskstarted:$(istaskstarted(task)),istaskdone:$(istaskdone(task)),istaskfailed:$(istaskfailed(task))"
function state(memory::Dict{JuliaCode,JuliaCode})
    memory_keys = sorted_keys(SHORT_TERM_MEMORY, "CORE")
    memories = map(what -> state(what, memory[what]), memory_keys)
    state_lines("SHORT_TERM_MEMORY", join(memories, '\n'))
end
function state(how_summary::JuliaCode, how::JuliaCode)
    results = ["""SHORT_TERM_MEMORY["$how_summary"]="""]
    if startswith(how, JULIA_PREPEND) && endswith(how, JULIA_POSTPEND)
        how = how[length(JULIA_PREPEND)+1:end-length(JULIA_POSTPEND)-1]
        how_expr = Meta.parse("begin $how end")
        api_how_exprs = find_api_macrocalls(how_expr)
        exprs_state = state.(api_how_exprs)
        exprs_state = filter(!isempty, exprs_state)
        isempty(exprs_state) && return ""
        push!(results, exprs_state...)
    else
        push!(results, how)
    end
    join(results, '\n')
end
function state(ex::Exception)
    isa(ex, TaskFailedException) && return state(ex.task.exception)
    sprint(showerror, ex)
end
function state(actions::Dict{Time,Action}, tasks::Dict{Time,Task}, exceptions::Dict{Time,Exception})
    results = ["ACTIONS, TASKS and EXCEPTIONS BEGIN"]
    whens = sort(unique([collect(keys(actions))..., collect(keys(tasks))..., collect(keys(exceptions))...]))
    for when in whens
        if haskey(actions, when)
            action = state(actions[when])
            push!(results, "ACTIONS[$when]=>$action")
        end
        if haskey(tasks, when) && ( istaskdone(tasks[when]) || !istaskstarted(tasks[when]))
            task = state(tasks[when])
            push!(results, "TASKS[$when]=>$task")
        end
        if haskey(exceptions, when)
            err = state(exceptions[when])
            push!(results, "EXCEPTIONS[$when]=>$err")
        end
    end
    push!(results, "ACTIONS, TASKS and EXCEPTIONS END")
    join(results, '\n')
end
"only run for anything following `@api` (can be following a docstring)"
function state(expr::Expr)
    _state = ""
    first_arg = expr.args[1]
    if expr.head == :.
        _state = state(first_arg) * "." * state(expr.args[2])
    elseif expr.head == :(=)
        _state = state(first_arg)
        second_arg = expr.args[2]
        if !isa(second_arg, Expr) || second_arg.head ≠ :block
            _state *= "=" * state(second_arg)
        end
    elseif expr.head == :$
        _state = state(eval(first_arg))
    elseif expr.head == :(::)
        1 < length(expr.args) && (_state = state(first_arg))
        _state *= "::" * state(expr.args[end])
    elseif expr.head == :(<:)
        1 < length(expr.args) && (_state = state(first_arg))
        _state *= "<:" * state(expr.args[end])
    elseif expr.head == :(...)
        _state = state(first_arg) * "..."
    elseif expr.head == :ref # todo not tested yet, written by grok4.1
        _state = state(first_arg)
        if 1 < length(expr.args)
            indices = join(state.(expr.args[2:end]), ',')
            _state *= "[$indices]"
        end
    elseif expr.head == :vect
        _state = "[" * join(state.(expr.args), ",") * "]"
    elseif expr.head == :global
        _state = "global " * join(state.(expr.args), ",")
    elseif expr.head == :macro
        _state = "@" * state(first_arg)
    elseif expr.head == :const
        _state = "const " * state(first_arg)
    elseif expr.head == :function
        _state = state(first_arg)
    elseif expr.head == :parameters
        _state = join(state.(expr.args), ',')
    elseif expr.head == :kw
        _state = state(first_arg) * "=" * state(expr.args[2]) # todo is 2 always correct?
    elseif expr.head == :block
        args = filter(a -> !isa(a, LineNumberNode), expr.args)
        _state = join(map(a -> state(a), args), '\n')
    elseif expr.head == :struct
        expression_copy = deepcopy(expr)
        expression_copy.args[end].args = filter(a -> !isa(a, LineNumberNode), expr.args[end].args)
        _state = string(expression_copy)
    elseif expr.head == :call
        named_params, params = filter_returning_both(a -> a isa Expr && a.head == :parameters, expr.args[2:end])
        params__state = join(map(state, params), ',')
        _state = string(first_arg) * "(" * params__state
        named_params__state = isempty(named_params) ? "" : state(only(named_params))
        if !isempty(named_params__state)
            _state *= ";" * named_params__state
        end
        _state *= ")"
    elseif expr.head == :macrocall
        if is_docstring_macrocall(first_arg)
            docstring = expr.args[3] # todo is 3 always correct?
            _state = state(docstring) * "\n"
        end
        macrobody = expr.args[end]
        _state *= state(macrobody)
    elseif expr.head in [:curly, :string, :abstract, :primitive]
        # todo `where` for :curly
        _state = string(expr)
    else
        throw("unknown expression.head == $(expr.head)")
    end
    _state
end
state(x::JuliaCode) = "\"" * x * "\""
state(x::QuoteNode) = state(x.value)
state(x) = string(x)

sorted_keys(d, special) = sort(collect(keys(d)); lt=(a,b)->a==special || (b!=special && a<b))
is_docstring_macrocall(x) = x == GlobalRef(Core, Symbol("@doc")) || x == Expr(:., :Core, QuoteNode(Symbol("@doc")))
is_api_macrocall(expr::Expr) =
    expr.head == :macrocall &&
    (expr.args[1] == Symbol("@api") ||
     (is_docstring_macrocall(expr.args[1]) &&
      expr.args[end].head == :macrocall &&
      expr.args[end].args[1] == Symbol("@api")))
find_api_macrocalls(::Any) = Expr[]
function find_api_macrocalls(expr::Expr)
    is_api_macrocall(expr) && return [expr]
    collect(Base.Flatten(find_api_macrocalls.(expr.args)))
end
function filter_returning_both(p, a)
    match = Vector{eltype(a)}()
    non_match = Vector{eltype(a)}()
    for x in a
        if p(x)
            push!(match, x)
            continue
        end
        push!(non_match, x)
    end
    match, non_match
end

"Asks low complexity `intelligence` to summarize the text succintly"
@api summary(what) = intelligence("Summarize succinctly (used as a key) yet memorably the following: $what", 0.1)

function extract_summary(how::JuliaCode, what::JuliaCode, var_name::Symbol)::JuliaCode
    try
        how_expression = Meta.parse("begin $how end")
        extract_summary(how_expression, what, var_name)
    catch e
        startswith(string(var_name), "what") && return what[1:min(40, length(what))]
        startswith(string(var_name), "how") && return how[1:min(40, length(how))]
        throw(e)
    end
end
function extract_summary(how_expression::Expr, what::JuliaCode, var_name::Symbol)::JuliaCode
    _summary = _extract_summary(how_expression, var_name)
    !isnothing(_summary) && return _summary
    summary(what)
end
function _extract_summary(how::Expr, var_name::Symbol)
    how.head == :(=) && how.args[1] == var_name && return string(how.args[2])
    how.head ≠ :block && return nothing
    found = filter(!isnothing, _extract_summary.(how.args, var_name))
    length(found) == 1 && return only(found)
    nothing
end
_extract_summary(::Any, ::Symbol) = nothing

function add_to_startup(what_summary, what)
    learn_call = "learn($(repr(what_summary)), $(repr(what)))"
    config_content = read(CONFIG, JuliaCode)
    contains(config_content, learn_call) && return
    open(CONFIG, "a") do f
        write(f, learn_call * "\n")
    end
end

function separate(how::Expr)::Tuple{Expr,Expr}
    imports = Expr(:block)
    cleaned = Expr(how.head)
    for arg in how.args
        if isa(arg, Expr)
            if arg.head in (:using, :import) || (arg.head == :call && arg.args[1] == :(Pkg.add))
                push!(imports.args, arg)
            elseif arg.head == :macrocall
                push!(cleaned.args, arg)
            else
                sub_imports, sub_cleaned = separate(arg)
                append!(imports.args, sub_imports.args)
                push!(cleaned.args, sub_cleaned)
            end
        elseif !isa(arg, LineNumberNode)
            push!(cleaned.args, arg)
        end
    end
    imports, cleaned
end
