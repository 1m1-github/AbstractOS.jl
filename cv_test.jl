filepath = "1m1.io_bluesky.txt"
file = open(filepath, "r")
bytes = readavailable(file)
close(file)
dartcode = String(bytes)
regex = r"const SuccessData\(([\s\S]*?)\),"
match_iter = eachmatch(regex, dartcode)
matches = collect(match_iter)

coding_text = 
"""
Python, julia, Solidity, Golang, TEAL, IPFS, Javascript/Node.js, Typescript, C, C++, C#, Rust, Dart, Java, Matlab, (No)SQL, MongoDB, PostgreSQL, HTML, Vue, VBA, Perl, Meteor, GCP, AWS, Docker, Flutter, Tcl/Tk, Pascal, Opal, RabbitMQ, ZeroMQ, Docker, Kubernetes, Lambda, Azure, Lua, REST, API design, various ML algorithms
"""

file = open("role_description.md", "r")
bytes = readavailable(file)
close(file)
role_description = String(bytes)


# function here_is_my_info()
#   msgs = []
#   for match in matches
#     content = match[1]
#     # @show content
#     push!(msgs, content)
#     # ask_learner_to_remember(content)
#   end
#   push!(msgs, "i have experience with the following tech: $coding_text")
# end

# tell_me_knowing_me(question) = ask_learner([here_is_my_info()...; question])

# tell_me_knowing_me("can you summarize me in 50 words based on what you know about me?")

msgs = [map(x->x[1], matches)...;coding_text; role_description;
"tailor the a cover letter to my experiences provided earlier. "]

response = ask_learner(msgs)

file=open("response.txt", "w")
write(file, response)
close(file)