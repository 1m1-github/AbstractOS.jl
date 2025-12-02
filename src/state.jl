state() = join([
        isdefined(Main, :STATE_PRE) ? STATE_PRE : "",
        "STATE BEGIN",
        state(SHORT_TERM_MEMORY),
        state(ACTIONS),
        state(ERRORS),
        state(INPUTS),
        state(OUTPUTS),
        state(SIGNALS),
        "STATE END",
        isdefined(Main, :STATE_POST) ? STATE_POST : "",
    ], '\n')
state(inputs::Dict{JuliaCode,InputPeripheral}) = state("INPUT PERIPHERALS", inputs)
state(outputs::Dict{JuliaCode,OutputPeripheral}) = state("OUTPUT PERIPHERALS", outputs)
state(memory::Dict{JuliaCode,JuliaCode}) = "SHORT_TERM_MEMORY BEGIN\n" * join(map(what -> state(what, memory[what]), collect(keys(memory))), '\n') * "\nSHORT_TERM_MEMORY END"
state(signals::Dict{JuliaCode,Bool}) = "SIGNALS BEGIN\n" * join(map(what -> """"$what"=>$(signals[what])""", collect(keys(signals))), ',') * "\nSIGNALS END"
state(actions::Dict{Time,Action}) = "ACTIONS BEGIN\n" * join(map(when -> state(actions[when]), collect(keys(actions))), '\n') * "\nACTIONS END"
state(errors::Dict{Time,Exception}) = "ERRORS BEGIN\n" * join(map(when -> "$when=>" * state(errors[when]), collect(keys(errors))), '\n') * "\nERRORS END"

function state(name::JuliaCode, d::Dict{JuliaCode,T}) where T
    _name = state(name)
    "$_name BEGIN\n" * join(map(k -> """"$k\"""", collect(keys(d))), ',') * "\n$_name END"
end
state(code::JuliaCode) = eval(Meta.parse(code))
state(action::Action) = """"$(action.when)=>$(action.what_summary)"(istaskstarted:$(istaskstarted(action.task)),istaskdone:$(istaskdone(action.task)),istaskfailed:$(istaskfailed(action.task)))"""
function state(how_summary::JuliaCode, how::JuliaCode)
    result = """SHORT_TERM_MEMORY["$how_summary"] BEGIN"""
    how_expr = Meta.parse("begin $how end")
    api_how_exprs = find_api_macrocalls(how_expr)
    result = [result, state.(api_how_exprs)...]
    push!(result, """SHORT_TERM_MEMORY["$how_summary"] END""")
    join(result, '\n')
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
