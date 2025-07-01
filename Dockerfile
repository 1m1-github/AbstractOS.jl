FROM julia:1.11.5-bookworm

RUN julia -e 'using Pkg; Pkg.add(["Revise", "HTTP"]); using Revise, HTTP'

COPY . /AbstractOS
WORKDIR /AbstractOS

ENV ABSTRACTOS_HTTP_IP=0.0.0.0
ENV ABSTRACTOS_HTTP_PORT=8080
ENV ABSTRACTOS_WEBSOCKET_PORT=8081
EXPOSE 8080 8081

CMD ["julia", "-t", "4", "AbstractOS.jl"]
