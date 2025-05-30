@api const FancyTextDisplay = "this knowledge provides a way to display text with fancy styling on the MiniFB output device. Use `display_fancy_text_on_minifb(text; x, y, font_size, font, color, bold, italic, shadow, shadow_offset, shadow_color)` to show styled text with various options like position, size, font type, color, boldness, italics, and shadow effects."
@api function display_fancy_text_on_minifb(text::String; x=100.0, y=200.0, font_size=36.0, font="Serif", color=(0.0,0.2,0.8), bold=true, italic=false, shadow=true, shadow_offset=3.0, shadow_color=(0.3,0.3,0.3))
    # Implementation details hidden, function available for use
end
