FROM julia:1.11.5-bookworm

RUN julia -e 'using Pkg; Pkg.add(["Revise", "HTTP"]); using Revise, HTTP'

COPY . /AbstractOS
WORKDIR /AbstractOS

EXPOSE 8080

CMD ["julia", "-t", "4", "AbstractOS.jl"]
