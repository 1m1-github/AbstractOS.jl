import Pkg
Pkg.add(["Cairo"])
using Cairo

@api function endless_animated_pattern(line_width::Float64 = 2.0, sleep_duration::Float64 = 0.02)
    @assert 0 < sleep_duration
    
    # Initialize Cairo surface
    surface = CairoARGBSurface(MiniFB_OutputDevice_WIDTH, MiniFB_OutputDevice_HEIGHT)
    ctx = CairoContext(surface)
    
    # Set line width
    set_line_width(ctx, line_width)
    
    # Starting position (center of screen)
    x = MiniFB_OutputDevice_WIDTH / 2.0
    y = MiniFB_OutputDevice_HEIGHT / 2.0
    
    # Line segment length
    segment_length = 20.0
    
    # Step counter for continuous animation
    step = 0
    
    # Endless animation loop
    while true
        step += 1
        
        # Clear background with slight transparency for trail effect
        set_source_rgba(ctx, 0.0, 0.0, 0.0, 0.05)
        paint(ctx)
        
        # Calculate angle using sine function for smooth variation
        angle = sin(step * 0.1) * 2π
        
        # Calculate end point of line segment
        x_end = x + segment_length * cos(angle)
        y_end = y + segment_length * sin(angle)
        
        # Draw line segment with color based on step
        hue = (step % 360) / 360.0
        set_source_rgb(ctx, 
            0.5 + 0.5 * sin(hue * 2π),
            0.5 + 0.5 * sin(hue * 2π + 2π/3),
            0.5 + 0.5 * sin(hue * 2π + 4π/3)
        )
        
        move_to(ctx, x, y)
        line_to(ctx, x_end, y_end)
        stroke(ctx)
        
        # Update position for next segment
        x = x_end
        y = y_end
        
        # Wrap around screen edges
        if x < 0
            x += MiniFB_OutputDevice_WIDTH
        elseif x > MiniFB_OutputDevice_WIDTH
            x -= MiniFB_OutputDevice_WIDTH
        end
        
        if y < 0
            y += MiniFB_OutputDevice_HEIGHT
        elseif y > MiniFB_OutputDevice_HEIGHT
            y -= MiniFB_OutputDevice_HEIGHT
        end
        
        # Display current frame
        buffer = getMiniFBBufferFromCairoSurface(surface)
        put!(outputs[:MiniFB], buffer)
        
        # Control animation speed
        sleep(sleep_duration)
    end
end

@api const endless_animated_pattern_description = "Creates an endless animated line pattern with customizable line width and animation speed. The pattern creates colorful trails that move based on sine wave patterns."
