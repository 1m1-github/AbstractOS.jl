Request("run", "get_newest_file_age", """
function get_newest_file_age()::Int64
    files = readdir()
    newest_file = sort(files, by = x -> Dates.mtime(x), rev = true)[1]
    age = Dates.now() - Dates.mtime(newest_file)
    return age
end
""", "", nothing, "", Int64)