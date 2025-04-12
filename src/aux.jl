import Base.print

print(func::Function) = signature(func)
signature(func::Function) = signature(func, first(methods(func)))
function signature(func::Function, method::Method)::String
    @assert method in methods(func)
    functionName = string(method.name)
    inputNames = split(method.slot_syms, '\0')[2:end-1]
    inputTypes = map(string, method.sig.parameters[2:end])
    returnTypes = Base.return_types(func, Tuple{Int, String})
    sig = "$functionName("
    for (inputName, inputType) in zip(inputNames, inputTypes)
        sig *= "$inputName::$inputType,"
    end
    sig = sig[1:end-1] # remove last ,
    sig = sig * ')'
    !isempty(returnTypes) && ( sig = sig * "::$(returnTypes[1])" )
    sig
end

print(m::Module) = explain(m)
function explain(m::Module)::Vector{String}
    signatures = String[]
    for name in names(m)
        field = getfield(m, name)
        !isa(field, Function) && continue
        push!(signatures, signature(field))
    end
    signatures
end
