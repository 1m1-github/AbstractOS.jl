#!/bin/sh

rm /data/1M1.jl # DEBUG
if [ ! -f /data/1M1.jl ]; then
    cp /tmp/1M1.jl /data/1M1.jl
fi

julia -t 4 1M1.jl
