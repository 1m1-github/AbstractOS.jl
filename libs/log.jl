using Dates

# const LOG_STREAM = open("/data/log.jl", "a")
const LOG_STREAM = open("./logs", "a")

macro log(ex)
    stacktrace()
    quote
        let value = $(esc(ex))
            timestamp = "$Dates."
            calling_function_name = "$(stacktrace()[1].func)"
            s = calling_function_name * ": " * $(string(ex)) * " = " * repr(value)
            println(s)
            println(LOG_STREAM, s)
            flush(LOG_STREAM)
            value
        end
    end
end
