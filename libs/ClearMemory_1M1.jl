@api function clear_memory(keys::Vector{Symbol} = Symbol[])
    if isempty(keys)
        # Clear all memory
        empty!(memory)
        memory[:memory_cleared] = "All memory cleared at $(now())"
    else
        # Clear specific keys
        cleared = Symbol[]
        for key in keys
            if haskey(memory, key)
                delete!(memory, key)
                push!(cleared, key)
            end
        end
        memory[:memory_cleared] = "Cleared keys: $(cleared) at $(now())"
    end
end

@api const ClearMemory = "This knowledge provides the ability to clear memory in the OS. Use `clear_memory()` to clear all memory, or `clear_memory([:key1, :key2])` to clear specific keys from memory."
