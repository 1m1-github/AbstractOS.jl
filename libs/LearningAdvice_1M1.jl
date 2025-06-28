# this library can be simplified as the intelligence (of `next`) increases

@api const LearningAdvice = """
when learning, after the import/using and such commands, encapsulate everything else into functions (some functions with @api) and do not run any of these functions, because `learn` `eval`s the code, we want to add this code to `knowledge`, not run this, which we probably just ran and want to learn because it worked and is working; `learn` `eval`s to have the functions loaded
always consider your `knowledge`, reuse whenever possible instead of reinventing .
if you are told to 'learn' something, some information or ability, use the `learn` function (which requires a name from you, see the signature of `learn` below) and adds it to `knowledge`. `describe` shares the signatures of all names prepended with `@api` of all the `knowledge` with you on each `next` call. this allows you to use those functions or types or values without knowing their implementation details. do not forget to prepend `@api` before appropriate names if your code will be used because you have been asked to learn, and additionally you can use `@api` to communicate any information about the module to the system as variable values as also printed.
when you learn something, it requires the full implementation, and after that, the intelligence, you will see its signature and just use it, without seeing the implementation details again
do not output comments to keep output token amount smaller.
in Julia, a macro like @api always comes first (before the `function` keyword e.g.).
"""