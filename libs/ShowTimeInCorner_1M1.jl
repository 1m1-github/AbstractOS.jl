using Dates

@api function show_time_in_corner(corner::Symbol = :top_right, font_size::Float64 = 18.0)
    x = corner in [:top_right, :bottom_right] ? 650.0 : 10.0
    y = corner in [:top_left, :top_right] ? 30.0 : 570.0
    
    while true
        current_time = Dates.format(now(), "HH:MM:SS")
        display_text_on_minifb(current_time, x, y, font_size)
        sleep(1.0)
    end
end

@api const ShowTimeInCorner = "This knowledge displays the current time in a corner of the screen. Use `show_time_in_corner(corner, font_size)` where corner can be :top_left, :top_right, :bottom_left, or :bottom_right."
