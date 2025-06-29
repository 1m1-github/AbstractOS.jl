FROM julia:1.11.5-bookworm

# RUN apt-get update
# RUN apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN mkdir ~/.julia/config
COPY startup.jl ~/.julia/config
COPY . /AbstractOS
WORKDIR /AbstractOS

ENV ABSTRACTOS_HTTP_IP=0.0.0.0
ENV ABSTRACTOS_HTTP_PORT=8080
ENV ABSTRACTOS_WEBSOCKET_PORT=8081
EXPOSE 8080 8081

CMD ["julia", "-t", "4"]
# CMD ["julia", "-t", "4", "AbstractOS.jl"]
