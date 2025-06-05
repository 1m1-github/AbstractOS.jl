import Pkg
Pkg.add(["Cairo"])
using Cairo

@api function display_text_on_minifb(text::String, x::Float64=100.0, y::Float64=300.0, font_size::Float64=24.0)
    surface = CairoARGBSurface(MiniFB_OutputDevice_WIDTH, MiniFB_OutputDevice_HEIGHT)
    ctx = CairoContext(surface)
    set_source_rgb(ctx, 1.0, 1.0, 1.0)
    paint(ctx)
    set_source_rgb(ctx, 0.0, 0.0, 0.0)
    select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(ctx, font_size)
    move_to(ctx, x, y)
    show_text(ctx, text)
    buffer = getMiniFBBufferFromCairoSurface(surface)
    put!(outputs[:MiniFB], buffer)
end
@api const DisplaySimpleText = "this knowledge provides a simple one-liner to display text on the MiniFB output device. Use `display_text_on_minifb(text, x, y, font_size)` to easily show text at the specified position and size."
