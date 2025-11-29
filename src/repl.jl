import Pkg
Pkg.add(["ReplMaker"])
using REPL, ReplMaker

learn(:REPLOutput)
learn(:REPLInput)

atreplinit() do _
    # todo @suppress
    initrepl(
        repl_parse,
        prompt_text="aos> ",
        prompt_color=:blue,
        start_key="\\C-a",
        mode_name="AOS_mode",
        valid_input_checker=complete_julia
    )
    write(stdin.buffer, "\x01\n")
end
