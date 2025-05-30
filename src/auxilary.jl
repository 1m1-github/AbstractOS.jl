# todo possible rm \n

abstract type InputOutputDevice end

function wait_and_monitor_task_for_error(task::Task)
    try
        wait(task)
    catch e 
        @show "wait_and_monitor_task_for_error, error, $e, $(e.task.exception)"
        push!(errors, e.task.exception)
    end
end

function describe(e::Exception)
    io = IOBuffer()
    Base.showerror(io, e)
    String(take!(io))
end

using InteractiveUtils

function describe(;OSCoreFileName::String)::String
    join([
            "describe() BEGIN\n",
            "OS source code BEGIN:\n" * read(OSCoreFileName, String) * "==\nOS source code END",
            "inputs BEGIN:\n" * join(map(symbol -> "describe(inputs[:$symbol]) = \"" * describe(inputs[symbol]) * "\"", collect(keys(inputs))), '\n') * "\ninputs END",
            "outputs BEGIN:\n" * join(map(symbol -> "describe(outputs[:$symbol]) = \"" * describe(outputs[symbol]) * "\"", collect(keys(outputs))), '\n') * "\noutputs END",
            "memory BEGIN:\n" * join(map(symbol -> "$symbol => $(memory[symbol])", collect(keys(memory))), '\n') * "\nmemory END",
            "knowledge BEGIN:\n" * join(map(code_name ->  describe(code_name, knowledge[code_name]), collect(keys(knowledge))), '\n') * "\nknowledge END",
            "tasks BEGIN:\n" * join(keys(tasks), ',') * "\ntasks END",
            "signals BEGIN:\n" * join(map(symbol -> "$symbol => $(signals[symbol])", collect(keys(signals))), ',') * "\nsignals END",
            "errors BEGIN:\n" * join(map(describe, errors), '\n') * "\nerrors END",
            "describe() END\n==\n",
        ], "==\n")
end

function separate(code::Expr)::Tuple{Expr, Expr}
    imports = Expr(:block)
    cleaned = Expr(code.head)

    for arg in code.args
        if isa(arg, Expr)
            if arg.head in (:using, :import) || (arg.head == :call && arg.args[1] == :(Pkg.add))
                push!(imports.args, arg)
            else
                sub_imports, sub_cleaned  = separate(arg)
                append!(imports.args, sub_imports.args)
                push!(cleaned.args, sub_cleaned)
            end
        elseif !isa(arg, LineNumberNode)
            push!(cleaned.args, arg)
        end
    end

    imports, cleaned
end

function taskname(code::Expr)
    for arg in code.args
        if isa(arg, Expr)
            if arg.head == :(=) && arg.args[1] == :task_name
                return arg.args[2].value
            end
            argValue = taskname(arg)
            isa(argValue, Symbol) && return argValue
        end
    end
    nothing
end

function describe(code_name::Symbol, code::String)
    result = ["knowledge[$code_name] BEGIN"]
    code_expr = Meta.parse("begin $code end")
    for arg in code_expr.args
        if isa(arg, Expr)
            if arg.head == :macrocall && arg.args[1] == Symbol("@api")
                expr = arg.args[3]
                if expr.head ∈ (:function, :(=)) && expr.args[1] isa Expr && expr.args[1].head ∈ [:call, :where]
                    expr_description = string(expr.args[1])
                else
                    expr_description = string(expr)
                end

                push!(result, expr_description)
            end
        end
    end
    push!(result, "knowledge[$code_name] END")
    join(result, '\n')
end

function clean(t::Dict{Symbol, Tuple{Base.Threads.Atomic{Bool}, Task}})
    name_and_tasks = map(s -> (s, t[s][2]), collect(keys(t)))
    done_name_and_tasks = filter(name_and_task -> istaskdone(name_and_task[2]), name_and_tasks)
    map(name_and_task -> delete!(tasks, name_and_task[1]), done_name_and_tasks)
end
