@api const DrawWithCairo = """
this knowledge allows you to do structued 2d graphics using Cairo.jl.
create and draw on a ::Cairo.CairoARGBSurface and pass it to getMiniFBBufferFromCairoSurface to get the pixels to put onto a MiniFB screen.
when this module is available, use it for all structured information, such as text. all important information like names, words, numbers, should be displayed precisely, and graphically, using this module.
getMiniFBBufferFromCairoSurface already exists.
here is an minimal example that works:
```
using Cairo
surface = CairoARGBSurface(400, 200)
ctx = CairoContext(surface)
set_source_rgb(ctx, 1.0, 1.0, 1.0)
paint(ctx)
set_source_rgb(ctx, 0.0, 0.0, 0.0)
move_to(ctx, 50.0, 100.0)
show_text(ctx, "hi Cairo")
buffer = getMiniFBBufferFromCairoSurface(surface)
put!(outputs[:MiniFB], buffer)
```
"""

import Pkg
Pkg.add(["Cairo", "Images", "MiniFB"])
using Cairo, Images, MiniFB

@api function getMiniFBBufferFromCairoSurface(cairo_surface::Cairo.CairoSurfaceBase)::Vector{UInt32}
    write_to_png(cairo_surface, "tmp/cairo.png")
    img = load("tmp/cairo.png")
    populateBuffer(cairo_surface, img)
end

function populateBuffer(cairo_surface, img)
    height = Int(Cairo.height(cairo_surface))
    width = Int(Cairo.width(cairo_surface))
    buffer = zeros(UInt32, width*height)
    for i in 1:height
        for j in 1:width
            buffer[(i-1)*width+j] = mfb_rgb(img[i,j])
        end
    end
    buffer
end