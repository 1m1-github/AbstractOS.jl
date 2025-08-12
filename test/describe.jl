using Test

code = """
       begin
       "f1 is good"
       f1 = 1

       "f2 is good"
       @api f2 = 2

       f3 = 3

       @api f4 = 4

       "f5 is good"
       f5(a::Int)::Int = 5

       "f6 is good"
       @api f6(a::Int)::Int = 6

       f7(a::Int)::Int = 7

       @api f8(a::Int)::Int = 8

       "f9 is good"
       function f9(a::Int)::Int 9 end

       "f10 is good"
       @api function f10(a::Int)::Int 10 end

       function f11(a::Int)::Int 11 end

       @api function f12(a::Int)::Int 12 end

       "f13 is good"
       f13(a::Int)::Int = begin 13 end

       "f14 is good"
       @api f14(a::Int)::Int = begin 14 end

       f15(a::Int)::Int = begin 15 end

       @api f16(a::Int)::Int = begin 16 end

       @api 17

       @api f18 = begin 18 end

       "f19 is good"
       @api function f19()::Int 19 end

       "f20 is good"
       @api function f20() 20 end

       struct S1 end

       abstract type S2 end

       "S3 is good"
       struct S3 end

       "S4 is good"
       abstract type S4 end

       @api struct S5 end

       @api abstract type S6 end

       "S7 is good"
       @api struct S7 end

       "S8 is good"
       @api abstract type S8 end

       "S9 is good"
       @api mutable struct S9 end

       "S10 is good"
       @api primitive type S10 8 end

       "S11 is good"
       @api struct S11{T} end

       "S12 is good"
       @api abstract type S12{T} end

       @api f5(5)

       "f21 is good"
       @api function f21(a::Int, b::Int64, c, d::String)::Int 21 end

       "S13 is good"
       @api struct S13 <: Number end

       "S14 is good"
       @api abstract type S14 <: Number end

       "S15 is good"
       @api mutable struct S15 <: Number end

       "S16 is good"
       @api primitive type S16 <: Number 8 end

       "S17 is good"
       @api abstract type S17{T} <: Number end

       "S18 is good"
       @api mutable struct S18{T1} <: Number 
           a::Int
           b::String
           c
       end

       "mmm is good"
       @api macro mmm(args...) 
           isempty(args) && return nothing
           esc(args[end])
       end

       "f22 is good"
       @api f22::Int = 22

       "f23 is good"
       @api function f23(a,b,c,d,e,f)::Int 23 end

       "f24 is good"
       @api function f24(a::Int,b::Int,c::Int,d::Int,e::Int)::Int 24 end

       "f25 is good"
       @api function f25(a,b...)::Int 25 end

       "f26 is good"
       @api const f26() = begin 26 end

       end
"""
correct_description = [
"\"f2 is good\"\nf2=2",
"f4=4",
"\"f6 is good\"\nf6(a::Int)::Int",
"f8(a::Int)::Int",
"\"f10 is good\"\nf10(a::Int)::Int",
"f12(a::Int)::Int",
"\"f14 is good\"\nf14(a::Int)::Int",
"f16(a::Int)::Int",
"17",
"f18",
"\"f19 is good\"\nf19()::Int",
"\"f20 is good\"\nf20()",
"struct S5 end",
"abstract type S6 end",
"\"S7 is good\"\nstruct S7 end",
"\"S8 is good\"\nabstract type S8 end",
"\"S9 is good\"\nmutable struct S9 end",
"\"S10 is good\"\nprimitive type S10 8 end",
"\"S11 is good\"\nstruct S11{T} end",
"\"S12 is good\"\nabstract type S12{T} end",
"f5(5)",
"\"f21 is good\"\nf21(a::Int,b::Int64,c,d::String)::Int",
"\"S13 is good\"\nstruct S13<:Number end",
"\"S14 is good\"\nabstract type S14<:Number end",
"\"S15 is good\"\nmutable struct S15<:Number end",
"\"S16 is good\"\nprimitive type S16<:Number 8 end",
"\"S17 is good\"\nabstract type S17{T}<:Number end",
"\"S18 is good\"\nmutable struct S18{T1}<:Number\na::Int\nb::String\nc\nend",
"\"mmm is good\"\nmacro mmm(args...)",
"\"f22 is good\"\nf22::Int=22",
"\"f23 is good\"\nf23(a,b,c,d,e,f)::Int",
"\"f24 is good\"\nf24(a::Int,b::Int,c::Int,d::Int,e::Int)::Int",
"\"f25 is good\"\nf25(a,b...)::Int",
"\"f26 is good\"\nconst f26()",
]

expr = Meta.parse(code)
eval(expr)

exprs = find_api_macrocalls(expr)

for i in 1:length(exprs)
    e = exprs[i]
    # @show i, e
    # @show describe_api_macrocall(e)
    @test correct_description[i] == describe_api_macrocall(e)
end

describe(code_name, knowledge[code_name])
code_name=:BrowserOutput
code=knowledge[code_name]
code_expr = Meta.parse("begin $code end")
api_code_exprs = find_api_macrocalls(code_expr)
describe_api_macrocall(api_code_exprs[end])
expression=api_code_exprs[end]
describe(expression.args[3], docstring)
expression=expression.args[3]
describe(expression::Expr, docstring::Ref{String})
expression=first_arg
expression=args_without_first[1]
expression.head
expression.args
expression.args[1]
expression.args[2]




Docs.meta(Main)
binding = Docs.Binding(Main, :next)
multi_doc = Docs.meta(Main)[binding]
docs = multi_doc.docs
collect(keys(docs))
a = collect(keys(docs))[1]
a.types
a isa Tuple
a <: Tuple
a isa NTuple
a isa NTuple{5,Int64}
a <: NTuple
a
collect(keys(docs))[1] isa Vector
collect(keys(docs))[1].types
typeof(collect(keys(docs))[1].types)
map(typeof, collect(keys(docs))[1].types)
typeof(collect(keys(docs))[1])

for (k, v) in Docs.meta(Main)
    println(map(x -> x, collect(keys(v.docs))))
end

matching_docs_keys = filter(d -> d.types == signature_without_name, collect(keys(multi_doc)))
matching_docs_keys = filter(d -> d.types == signature_without_name, (keys(multi_doc)))
docstring = ""
if !isempty(matching_docs_keys)
    text_vec = docs[first(matching_docs_keys)].text
    docstring = join(text_vec) * '\n'
end

name = "a=b is good"
a1(x) = b1(x) = 1

exprs = filter(e -> isa(e.args[3], Expr) && e.args[3].head == :(=), exprs)
exprs = filter(e -> isa(e.args[3], Expr) && e.args[3].head == :function, exprs)
exprs = filter(e -> isa(e.args[3], Expr) && e.args[3].head == :struct, exprs)
exprs = filter(e -> isa(e.args[3], Expr) && e.args[3].head == :abstract, exprs)
exprs = filter(e -> isa(e.args[3], Expr) && e.args[3].head == :primitive, exprs)

for i in 1:length(exprs)
    e = exprs[i]
    @show i, string(e.args[3].head)
end
for i in 1:length(exprs)
    e = exprs[i]
    @show i, string(e.args[3].args)
end
for i in 1:length(exprs)
    e = exprs[i]
    @show i, length(e.args[3].args)
end
for i in 1:length(exprs)
    e = exprs[i]
    @show i, string(e.args[3])
end

i = 29
@show exprs[i]
exprs[i].head
exprs[i].args
exprs[i].args[1]
exprs[i].args[3]
string(exprs[i].args[3])
typeof(exprs[i].args[3])
isa(eval(exprs[i].args[3]), Function)
exprs[i].args[3].head
exprs[i].args[3].args
typeof(exprs[i].args[3].args[1])
typeof(exprs[i].args[3].args[2])
j = 1
exprs[i].args[3].args[j].head
exprs[i].args[3].args[j].args
k = 1
typeof(exprs[i].args[3].args[j].args[k])
exprs[i].args[3].args[j].args[k]
exprs[i].args[3].args[j].args[k].head
exprs[i].args[3].args[j].args[k].args
l = 1
exprs[i].args[3].args[j].args[k].args[l]
exprs[i].args[3].args[j].args[k].args[l].head
exprs[i].args[3].args[j].args[k].args[l].args


m = methods(f10)[1]
m.source
Base.uncompressed_ast(m).code

expression = exprs[i].args[3]
expression = exprs[i].args[3].args[j].args[k]

docstring = Ref("")
typeof(expression)
description = describe(expression, docstring)