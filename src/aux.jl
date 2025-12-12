function state(name::Symbol, f::Function)
    d = getfield(Main, name)
    ks = sort(collect(keys(d)))
    lines = map(f, ks)
    join(lines, '\n')
end
state(::Dict{String,Any}) = state(:MEMORY, k -> """MEMORY["$k"]=$(state(MEMORY[k]))""")
state(::Dict{String,Bool}) = state(:FLAGS, k -> """FLAGS["$k"]=$(FLAGS[k])""")
state(::Dict{String,InputPeripheral}) = state(:INPUTS, k -> """INPUTS["$k"]=$(state(INPUTS[k]))""")
state(::Dict{String,OutputPeripheral}) = state(:OUTPUTS, k -> """OUTPUTS["$k"]=$(state(OUTPUTS[k]))""")

function state(name::String, code::String="")
    code_expr = Meta.parse(block(code))
    api_code_exprs = find_api_macrocalls(code_expr)
    api_code_exprs_state = filter(!isempty, state.(api_code_exprs))
    join(api_code_exprs_state, '\n')
end
state(::Dict{String,JuliaCode}) = state(:CODE, k -> """CODE["$k"]\n$(state(k, CODE[k]))\n""")

function state(ex::Exception)
    isa(ex, TaskFailedException) && return state(ex.task.exception)
    sprint(showerror, ex)
end
function state(task::Task)
    task_state = "istaskstarted:$(istaskstarted(task))\nistaskdone:$(istaskdone(task))\nistaskfailed:$(istaskfailed(task))"
    !istaskfailed(task) && return task_state
    "$(task_state)\nException=$(task.exception)"
end
state(action::Action) = """source=\"$(action.source)\"\ninput_summary=\"$(action.input_summary)\"\ninput=\"$(action.input)\"\noutput_summary=\"$(action.output_summary)\"\noutput=\"$(action.output)\""""
function state(history::Dict{Time,Action}, tasks::Dict{Time,Task})
    results = []
    for when in sort(collect(keys(history)))
        push!(results, "HISTORY[$when]=\n$(state(history[when]))")
        push!(results, "TASKS[$when]=\n$(state(tasks[when]))")
    end
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

const MAX_SUMMARY_LENGTH = 40
"Asks low complexity `intelligence` to summarize the text succintly"
@api summary(input) = intelligence("Summarize succinctly (used as a key) yet memorably the following: $input", 0.1)
function extract_summary(output::JuliaCode, input, var_name::Symbol)::JuliaCode
    try
        output_expr = Meta.parse(block(output))
        extract_summary(output_expr, input, var_name)
    catch e
        startswith(string(var_name), "input") && return input[1:min(MAX_SUMMARY_LENGTH, length(input))]
        startswith(string(var_name), "output") && return output[1:min(MAX_SUMMARY_LENGTH, length(output))]
        throw(e)
    end
end
function extract_summary(output_expr::Expr, input, var_name::Symbol)::JuliaCode
    _summary = _extract_summary(output_expr, var_name)
    !isnothing(_summary) && return _summary
    summary(input)
end
function _extract_summary(output::Expr, var_name::Symbol)
    output.head == :(=) && output.args[1] == var_name && return string(output.args[2])
    output.head ≠ :block && return nothing
    found = filter(!isnothing, _extract_summary.(output.args, var_name))
    length(found) == 1 && return only(found)
    nothing
end
_extract_summary(::Any, ::Symbol) = nothing

function add_to_boot(summary, code)
    learn_call = "learn($(repr(summary)), $(repr(code)))"
    content = read(BOOT, JuliaCode)
    contains(content, learn_call) && return
    open(BOOT, "a") do f
        write(f, learn_call * "\n")
    end
end

function separate(code::Expr)::Tuple{Expr,Expr}
    imports = Expr(:block)
    cleaned = Expr(code.head)
    for arg in code.args
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
