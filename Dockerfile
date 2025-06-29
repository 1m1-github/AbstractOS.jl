FROM julia:1.11.5-bookworm

# RUN apt-get update
# RUN apt-get install -y git && rm -rf /var/lib/apt/lists/*

COPY . /AbstractOS
WORKDIR /AbstractOS

ENV ABSTRACTOS_HTTP_IP=0.0.0.0
ENV ABSTRACTOS_HTTP_PORT=80
ENV ABSTRACTOS_WEBSOCKET_PORT=81
EXPOSE 80 81

CMD ["julia", "-t", "4", "AbstractOS.jl"]