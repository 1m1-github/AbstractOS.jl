is_api_macrocall(expression::Expr) = expression.head == :macrocall && expression.args[1] == Symbol("@api")
find_api_macrocalls(::Any) = Expr[]
function find_api_macrocalls(expression::Expr)
    is_api_macrocall(expression) && return [expression]
    api_macrocalls = Expr[]
    for arg in expression.args
        sub_api_macrocalls = find_api_macrocalls(arg)
        isempty(sub_api_macrocalls) && continue
        push!(api_macrocalls, sub_api_macrocalls...)
    end
    api_macrocalls
end
function could_have_docstring(mod::Module, name::Symbol)
    binding = Docs.Binding(mod, name)
    all_docs = Docs.meta(mod)
    result = haskey(all_docs, binding)
    result, result ? all_docs[binding].docs : nothing
end
function find_docstring(docs, signature)
    for (type, _) in docs
        type == signature && return join(docs[type].text)
        type == Union{} && signature == Tuple{} && return join(docs[type].text)
        type <: Tuple && collect(type.types) == signature && return join(docs[type].text)
    end
    ""
end
function get_arg_type(expression::Expr)
    if expression.head == :(::)
        return eval(expression.args[end])
    elseif expression.head == :(...)
        return Vararg{Any}
    end
    throw("unknown expression.head = $(expression.head)")
end
get_arg_type(::Symbol) = Any

function describe_api_macrocall(expression::Expr)
    docstring = Ref("")
    description = describe(expression.args[3], docstring)
    !isempty(docstring[]) && return "\"" * docstring[] * "\"\n" * description
    description
end
describe(expression::Expr) = describe(expression::Expr, Ref(""))
function describe(expression::Expr, docstring::Ref{String}) # only run for anything following `@api`
    description = ""
    first_arg = expression.args[1]
    if expression.head == :(=)
        description = describe(first_arg, docstring)
        second_arg = expression.args[2]
        if !isa(second_arg, Expr) || second_arg.head ≠ :block
            description *= "=" * describe(second_arg, docstring)
        end
    elseif expression.head == :(::)
        if length(expression.args) == 2 description = describe(first_arg, docstring) end
        description *= "::" * describe(expression.args[end], docstring)
    elseif expression.head == :(<:)
        description = describe(first_arg, docstring) * "<:" * describe(expression.args[2], docstring)
    elseif expression.head == :string
        description = "\"" * join(expression.args) * "\""
    elseif expression.head == :function
        description = describe(first_arg, docstring)
    elseif expression.head == :call
        # todo default values
        args_without_first = expression.args[2:end]
        last_arg = args_without_first[end]
        parameters = ""
        if last_arg isa Expr && last_arg.head == :parameters
            parameters = describe(last_arg)
            args_without_first = args_without_first[1:end-1]
        end
        could_have, docs = could_have_docstring(Main, first_arg)
        if could_have
            if all(a -> a isa Expr || a isa Symbol, args_without_first)
                signature = get_arg_type.(args_without_first)
                isempty(signature) && (signature = Tuple{})
                docstring[] *= find_docstring(docs, signature)
            end
        end
        description = string(first_arg) * "(" * join(map(a -> describe(a, docstring), args_without_first), ',')
        if !isempty(parameters) description *= ";" * parameters end
        description *= ")"
    elseif expression.head == :parameters
        description = join(string.(expression.args), ',')
    elseif expression.head == :block
        args = filter(a -> !isa(a, LineNumberNode), expression.args)
        description = join(map(a -> describe(a, docstring), args), '\n')
    elseif expression.head == :struct
        description = first_arg ? "mutable " : ""
        description *= "struct " * describe(expression.args[2], docstring)
        block = describe(expression.args[3], docstring)
        if isempty(block)
            description *= " end"
        else
            description *= "\n" * block * "\nend"
        end
    elseif expression.head == :abstract
        description = "abstract type " * describe(only(expression.args), docstring) * " end"
    elseif expression.head == :primitive
        description = "primitive type " * describe(first_arg, docstring) * " " * describe(expression.args[2], docstring) * " end"
    elseif expression.head == :curly
        # todo `where`
        description = describe(first_arg, docstring) * "{" * describe(expression.args[2], docstring) * "}"
    elseif expression.head == :macro
        first_arg.args[1] = Symbol("@" * string(first_arg.args[1]))
        description = "macro " * describe(first_arg, docstring)
        first_arg.args[1] = Symbol(string(first_arg.args[1])[2:end])
        description = replace(description, '@' => "")
    elseif expression.head == :(...)
        description = describe(first_arg, docstring) * "..."
    elseif expression.head == :const
        description = "const " * describe(first_arg, docstring)
    else
        throw("unknown expression.head == $(expression.head)")
    end
    description
end
function describe(name::Symbol, docstring::Ref{String})
    could_have, docs = could_have_docstring(Main, name)
    if could_have
        docstring[] *= find_docstring(docs, Union{})
    end
    string(name)
end
describe(x, ::Any) = string(x)
describe(::LineNumberNode, ::Any) = ""
function describe()::String
    join([
            "describe() BEGIN",
            "OS source code BEGIN\n" * read(joinpath(OS_SRC_DIR, "core.jl"), String) * "\nOS source code END",
            map(describe, [input_devices, output_devices, memory, knowledge, tasks, signals])...,
            "describe() END",
        ], "\n")
end
describe(name::String, d::Dict{Symbol, T}) where T = "$name BEGIN\n" * join(map(k -> ":$k", collect(keys(d))), ',') * "$name END"
describe(::Dict{Symbol, InputDevice}) = describe("input_devices", input_devices)
describe(::Dict{Symbol, OutputDevice}) = describe("output_devices", output_devices)
describe(::Dict{Symbol, Tuple{String, String, Task}}) = describe("tasks", tasks)
describe(::Dict{Symbol, Any}) = "memory BEGIN\n" * join(map(namę -> ":$name=>$(memory[name])", collect(keys(memory))), '\n') * "memory END"
describe(::Dict{Symbol, String}) = "knowledge BEGIN\n" * join(map(code_name -> describe(code_name, knowledge[code_name]), collect(keys(knowledge))), '\n') * "knowledge END"
describe(::Dict{Symbol, Bool}) = "signals BEGIN\n" * join(map(name -> ":$name=>$(signals[name])", collect(keys(signals))), ',') * "signals END"
function describe(code_name::Symbol, code::String)
    result = "knowledge[:$code_name] BEGIN"
    code_expr = Meta.parse("begin $code end")
    api_code_exprs = find_api_macrocalls(code_expr)
    result = [result, describe_api_macrocall.(api_code_exprs)...]
    push!(result, "knowledge[:$code_name] END")
    join(result, '\n')
end
