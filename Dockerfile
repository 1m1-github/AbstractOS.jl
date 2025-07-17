FROM julia:1.11.5-bookworm

RUN apt-get update && apt-get install -y git

RUN useradd -m installer-1m1
RUN useradd -m user-1m1

RUN mkdir /data && chown user-1m1:user-1m1 /data && chmod 755 /data
RUN mkdir /1M1 && chown installer-1m1:installer-1m1 /1M1 && chmod 755 /1M1

WORKDIR /data

COPY . /1M1

COPY ./1M1.jl /tmp/1M1.jl
COPY docker_entrypoint.sh /docker_entrypoint.sh
RUN chmod +x /docker_entrypoint.sh
USER user-1m1
CMD /docker_entrypoint.sh
# CMD ["tail", "-f", "/dev/null"]
# CMD ["sleep", "infinity"]
# RUN julia -e 'using Pkg; Pkg.add(["Revise", "HTTP"]); using Revise, HTTP'

# CMD pwd && whoami && ls && which julia
# CMD ["pwd", "&&", "whoami", "&&", "ls", "&&", "which julia"]
# CMD ["julia", "-t", "4", "-e", "@show pwd();run(\`whoami\`);@show readdir()"]
# CMD ["julia", "-t", "4", "1M1.jl"]
# CMD julia -t 4 1M1.jl

# ENV ABSTRACTOS_HTTP_IP=0.0.0.0
# ENV ABSTRACTOS_HTTP_PORT=8080
# ENV ABSTRACTOS_OUTER_WEBSOCKET_PROTOCOL=wss
# ENV ABSTRACTOS_OUTER_WEBSOCKET_IP=1m1.fly.dev
# ENV ABSTRACTOS_INNER_WEBSOCKET_IP=0.0.0.0
# ENV ABSTRACTOS_WEBSOCKET_PORT=8081
# EXPOSE 8080 8081