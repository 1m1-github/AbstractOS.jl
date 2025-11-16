function describe()::String
    join([
            "describe() BEGIN",
            "OS source code BEGIN\n" * read(joinpath(OS_SRC_DIR, "core.jl"), String) * "\nOS source code END",
            map(describe, [input_devices, output_devices, memory, knowledge, tasks, signals])...,
            "describe() END",
        ], "\n")
end
describe(name::String, d::Dict{Symbol, T}) where T = "$name BEGIN\n" * join(map(k -> ":$k", collect(keys(d))), ',') * "\n$name END"
describe(::Dict{Symbol, InputDevice}) = describe("input_devices", input_devices)
describe(::Dict{Symbol, OutputDevice}) = describe("output_devices", output_devices)
describe(::Dict{Symbol, TaskElement}) = describe("tasks", tasks)
describe(::Dict{Symbol, Any}) = "memory BEGIN\n" * join(map(name -> ":$name=>$(memory[name])", collect(keys(memory))), '\n') * "\nmemory END"
describe(::Dict{Symbol, String}) = "knowledge BEGIN\n" * join(map(code_name -> describe(code_name, knowledge[code_name]), collect(keys(knowledge))), '\n') * "\nknowledge END"
describe(::Dict{Symbol, Bool}) = "signals BEGIN\n" * join(map(name -> ":$name=>$(signals[name])", collect(keys(signals))), ',') * "\nsignals END"
function describe(code_name::Symbol, code::String)
    result = "knowledge[:$code_name] BEGIN"
    code_expr = Meta.parse("begin $code end")
    api_code_exprs = find_api_macrocalls(code_expr)
    result = [result, describe.(api_code_exprs)...]
    push!(result, "knowledge[:$code_name] END")
    join(result, '\n')
end
docstring_macroname = GlobalRef(Core, Symbol("@doc"))
is_api_macrocall(expression::Expr) = 
    expression.head == :macrocall && 
    (expression.args[1] == Symbol("@api") || 
     (expression.args[1] == docstring_macroname && 
      expression.args[end].head == :macrocall && 
      expression.args[end].args[1] == Symbol("@api")))
find_api_macrocalls(::Any) = Expr[]
function find_api_macrocalls(expression::Expr)
    is_api_macrocall(expression) && return [expression]
    collect(Base.Flatten(find_api_macrocalls.(expression.args)))
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
"only run for anything following `@api` (can be following a docstring)"
function describe(expression::Expr)
    description = ""
    first_arg = expression.args[1]
    if expression.head in [:curly, :string, :abstract, :primitive]
        # todo `where` for :curly
        description = string(expression)
    elseif expression.head == :.
        description = describe(first_arg) * "." * describe(expression.args[2])
    elseif expression.head == :macro
        description = "@" * describe(first_arg)
    elseif expression.head == :(...)
        description = describe(first_arg) * "..."
    elseif expression.head == :const
        description = "const " * describe(first_arg)
    elseif expression.head == :(::)
        description = describe(first_arg) * "::" * describe(expression.args[2])
    elseif expression.head == :(<:)
        description = describe(first_arg) * "<:" * describe(expression.args[2])
    elseif expression.head == :function
        description = describe(first_arg)
    elseif expression.head == :parameters
        description = join(describe.(expression.args), ',')
    elseif expression.head == :kw
        description = describe(first_arg) * "=" * describe(expression.args[2])
    elseif expression.head == :block
        args = filter(a -> !isa(a, LineNumberNode), expression.args)
        description = join(map(a -> describe(a), args), '\n')
    elseif expression.head == :struct
        structname = expression.args[2]
        description = describe(structname)
        expression_copy = deepcopy(expression)
        expression_copy.args[end].args = filter(a -> !isa(a, LineNumberNode), expression.args[end])
        description = string(expression_copy)
    elseif expression.head == :(=)
        description = describe(first_arg)
        second_arg = expression.args[2]
        if !isa(second_arg, Expr) || second_arg.head ≠ :block
            description *= "=" * describe(second_arg)
        end
    elseif expression.head == :call
        named_params, params = filter_returning_both(a -> a isa Expr && a.head == :parameters, expression.args[2:end])
        params_description = join(map(describe, params), ',')
        description = string(first_arg) * "(" * params_description
        named_params_description = isempty(named_params) ? "" : describe(only(named_params))
        if !isempty(named_params_description) description *= ";" * named_params_description end
        description *= ")"
    elseif expression.head == :macrocall
        if first_arg == docstring_macroname
            docstring = expression.args[3]
            description = describe(docstring) * "\n"
        end
        macrobody = expression.args[end]
        description *= describe(macrobody)
    else
        throw("unknown expression.head == $(expression.head)")
    end
    description
end
describe(x::String) = "\"" * x * "\""
describe(x::QuoteNode) = describe(x.value)
describe(x) = string(x)
