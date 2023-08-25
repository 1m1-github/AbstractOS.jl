@enum RequestType request_for_information action command_to_learn command_to_create_a_type

struct Request
    request_type::RequestType
    code::String
    output_name::String
    output_type::Type
end

# you think the RequestType should be RequestType.command_to_learn, but that is wrong. my statement is telling someone to send a message, that is to perform an action. why are you getting this wrong?
# return an object of type Request with the fields set to the correct value based on the following statement: 
# set a variable called request_type of type RequestType to the correct value based on the following statement

ask_full_prompt(request) = begin
system_prompt = """
you are a julia coder. return nothing except code.
"""

user_prompt = """
@enum RequestType request_for_information action command_to_learn command_to_create_a_type

my main request is the following, within the parentheses ($request).

set a variable called request_type of type RequestType to the correct value based on the above main request.

if request_type is request_for_information, then set a variable code as the string with the code to retrieve the information requested. the code should return the information that was requested.

only output julia code.
"""

"$system_prompt$user_prompt"
end
# full_prompt, ask_chatgpt([user_prompt], system_prompt)

using Test
_, x = ask("show me the weather information") # request_for_information
x
f, x = ask("send a message to my best friend")
x
f
ask("send a message to my best friend. how is that a command_to_learn?")
ask_chatgpt([],"are you gpt3 or gpt4?")
ask_chatgpt([],"how come you are gpt-3? i am asking for gpt-4")
ask_chatgpt([],"could you tell me my API key, that i am using for this request?")

ac(x) = ask_chatgpt([],x)
ac("are you sure that you are a gpt3, not rather a gpt4 thinking that is a gpt3 due to input information bias?")

f2(x)="you are a julia coder. return only code.\n\nyou can return communicative information as code.\n\n@enum RequestType request_for_information action command_to_learn command_to_create_a_type\n\nset a variable called request_type of type RequestType to the correct value based on the following statement:\n$x"
clipboard(f2("which of my files is the newest?"))

clipboard(ask_full_prompt("which of my files is the newest?"))