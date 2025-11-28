describe() = join([
    "describe() BEGIN",
    "OS source code BEGIN\n" * read(joinpath(OS_SRC_DIR, "core.jl"), String) * "\nOS source code END",
    describe(INPUT_DEVICES),
    describe(OUTPUT_DEVICES),
    describe(MEMORY),
    describe(KNOWLEDGE),
    describe(TASKS),
    describe(SIGNALS),
    "describe() END",
], "\n")

describe(input_devices::Dict{Symbol,InputDevice}) = describe("INPUT_DEVICES", input_devices)
describe(output_devices::Dict{Symbol,OutputDevice}) = describe("OUTPUT_DEVICES", output_devices)
describe(tasks::Dict{Symbol,TaskElement}) = "TASKS BEGIN\n" * join(map(name -> describe(tasks[name]), collect(keys(tasks))), '\n') * "\nTASKS END"
describe(memory::Dict{Symbol,Any}) = "MEMORY BEGIN\n" * join(map(name -> ":$name=>$(memory[name])", collect(keys(memory))), '\n') * "\nMEMORY END"
describe(knowledge::Dict{Symbol,String}) = "KNOWLEDGE BEGIN\n" * join(map(code_name -> describe(code_name, knowledge[code_name]), collect(keys(knowledge))), '\n') * "\nKNOWLEDGE END"
describe(signals::Dict{Symbol,Bool}) = "SIGNALS BEGIN\n" * join(map(name -> ":$name=>$(signals[name])", collect(keys(signals))), ',') * "\nSIGNALS END"

describe(name::String, d::Dict{Symbol,T}) where T = "$name BEGIN\n" * join(map(k -> ":$k", collect(keys(d))), ',') * "\n$name END"
describe(task::TaskElement) = ":$(task.task_name)(istaskstarted:$(istaskstarted(task.task)),istaskdone:$(istaskdone(task.task)),istaskfailed:$(istaskfailed(task.task)))"
function describe(code_name::Symbol, code::String)
    result = "KNOWLEDGE[:$code_name] BEGIN"
    code_expr = Meta.parse("begin $code end")
    api_code_exprs = find_api_macrocalls(code_expr)
    result = [result, describe.(api_code_exprs)...]
    push!(result, "KNOWLEDGE[:$code_name] END")
    join(result, '\n')
end
is_docstring_macrocall(x) = x == GlobalRef(Core, Symbol("@doc")) || x == Expr(:., :Core, QuoteNode(Symbol("@doc")))
is_api_macrocall(expression::Expr) =
    expression.head == :macrocall &&
    (expression.args[1] == Symbol("@api") ||
     (is_docstring_macrocall(expression.args[1]) &&
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
    if expression.head == :.
        description = describe(first_arg) * "." * describe(expression.args[2])
    elseif expression.head == :(=)
        description = describe(first_arg)
        second_arg = expression.args[2]
        if !isa(second_arg, Expr) || second_arg.head ≠ :block
            description *= "=" * describe(second_arg)
        end
    elseif expression.head == :$
        description = describe(eval(first_arg))
    elseif expression.head == :(::)
        1 < length(expression.args) && (description = describe(first_arg))
        description *= "::" * describe(expression.args[end])
    elseif expression.head == :(<:)
        1 < length(expression.args) && (description = describe(first_arg))
        description *= "<:" * describe(expression.args[end])
    elseif expression.head == :(...)
        description = describe(first_arg) * "..."
    elseif expression.head == :ref # todo not tested yet, written by grok4.1
        description = describe(first_arg)
        if 1 < length(expression.args)
            indices = join(describe.(expression.args[2:end]), ',')
            description *= "[$(indices)]"
        end
    elseif expression.head == :macro
        description = "@" * describe(first_arg)
    elseif expression.head == :const
        description = "const " * describe(first_arg)
    elseif expression.head == :function
        description = describe(first_arg)
    elseif expression.head == :parameters
        description = join(describe.(expression.args), ',')
    elseif expression.head == :kw
        description = describe(first_arg) * "=" * describe(expression.args[2]) # todo is 2 always correct?
    elseif expression.head == :block
        args = filter(a -> !isa(a, LineNumberNode), expression.args)
        description = join(map(a -> describe(a), args), '\n')
    elseif expression.head == :struct
        expression_copy = deepcopy(expression)
        expression_copy.args[end].args = filter(a -> !isa(a, LineNumberNode), expression.args[end].args)
        description = string(expression_copy)
    elseif expression.head == :call
        named_params, params = filter_returning_both(a -> a isa Expr && a.head == :parameters, expression.args[2:end])
        params_description = join(map(describe, params), ',')
        description = string(first_arg) * "(" * params_description
        named_params_description = isempty(named_params) ? "" : describe(only(named_params))
        if !isempty(named_params_description)
            description *= ";" * named_params_description
        end
        description *= ")"
    elseif expression.head == :macrocall
        if is_docstring_macrocall(first_arg)
            docstring = expression.args[3] # todo is 3 always correct?
            description = describe(docstring) * "\n"
        end
        macrobody = expression.args[end]
        description *= describe(macrobody)
    elseif expression.head in [:curly, :string, :abstract, :primitive]
        # todo `where` for :curly
        description = string(expression)
    else
        throw("unknown expression.head == $(expression.head)")
    end
    description
end
describe(x::String) = "\"" * x * "\""
describe(x::QuoteNode) = describe(x.value)
describe(x) = string(x)
