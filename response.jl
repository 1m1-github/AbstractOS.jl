```julia
request_type = :run

function_name = "get_age_of_newest_file"

function_signature = "function get_age_of_newest_file(directory::String)::Float64"

function_code = "
    files = readdir(directory)
    ages = map(file -> time() - mtime(joinpath(directory, file)), files)
    return minimum(ages)
"

docstring = "\"\"\" 
    get_age_of_newest_file(directory::String)

Find the age of the newest file in the given directory. The age is calculated as the current time minus the modification time of the file. The age is returned in seconds.
\"\"\""

input_name = "directory"

input_type = "String"
```

function get_age_of_newest_file(directory::String)::Float64
    files = readdir(directory)
    ages = map(file -> time() - mtime(joinpath(directory, file)), files)
    return minimum(ages)
end
get_age_of_newest_file(pwd())