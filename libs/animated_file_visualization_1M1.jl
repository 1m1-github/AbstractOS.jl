import Pkg
Pkg.add(["Cairo", "Colors"])
using Cairo, Colors

function create_file_visualization()
    # Get file list
    files = readdir(".")
    
    # Create surface
    surface = CairoARGBSurface(MiniFB_OutputDevice_WIDTH, MiniFB_OutputDevice_HEIGHT)
    ctx = CairoContext(surface)
    
    # Background gradient
    pat = pattern_create_linear(0.0, 0.0, MiniFB_OutputDevice_WIDTH, MiniFB_OutputDevice_HEIGHT)
    pattern_add_color_stop_rgb(pat, 0, 0.1, 0.1, 0.2)
    pattern_add_color_stop_rgb(pat, 1, 0.2, 0.1, 0.3)
    set_source(ctx, pat)
    paint(ctx)
    
    # Prepare file data
    file_data = []
    for (i, file) in enumerate(files)
        try
            size = filesize(file)
            is_dir = isdir(file)
            ext = splitext(file)[2]
            push!(file_data, (name=file, size=size, is_dir=is_dir, ext=ext, index=i))
        catch
            continue
        end
    end
    
    # Draw files as floating bubbles
    t = time()
    for (i, fd) in enumerate(file_data)
        # Position with gentle floating motion
        base_x = 100 + (i % 5) * 140
        base_y = 100 + div(i, 5) * 120
        x = base_x + 20 * sin(t + i * 0.5)
        y = base_y + 10 * cos(t * 0.7 + i * 0.3)
        
        # Size based on file size
        radius = 20 + min(30, log10(fd.size + 1) * 5)
        
        # Color based on file type
        if fd.is_dir
            set_source_rgba(ctx, 0.3, 0.6, 0.9, 0.8)
        elseif fd.ext in [".jl", ".julia"]
            set_source_rgba(ctx, 0.9, 0.3, 0.5, 0.8)
        elseif fd.ext in [".txt", ".md"]
            set_source_rgba(ctx, 0.3, 0.9, 0.5, 0.8)
        else
            set_source_rgba(ctx, 0.7, 0.7, 0.3, 0.8)
        end
        
        # Draw bubble
        arc(ctx, x, y, radius, 0, 2π)
        fill_preserve(ctx)
        set_source_rgba(ctx, 1, 1, 1, 0.3)
        set_line_width(ctx, 2)
        stroke(ctx)
        
        # Draw filename
        set_source_rgb(ctx, 1, 1, 1)
        set_font_size(ctx, 10)
        
        # Truncate long names
        display_name = length(fd.name) > 15 ? fd.name[1:12] * "..." : fd.name
        text_extents = Cairo.text_extents(ctx, display_name)
        move_to(ctx, x - text_extents[3]/2, y)
        show_text(ctx, display_name)
        
        # Show size for files
        if !fd.is_dir
            size_str = fd.size < 1024 ? "$(fd.size)B" : 
                       fd.size < 1024*1024 ? "$(round(fd.size/1024, digits=1))KB" :
                       "$(round(fd.size/1024/1024, digits=1))MB"
            set_font_size(ctx, 8)
            text_extents = Cairo.text_extents(ctx, size_str)
            move_to(ctx, x - text_extents[3]/2, y + 15)
            show_text(ctx, size_str)
        end
    end
    
    # Title
    set_source_rgb(ctx, 1, 1, 1)
    set_font_size(ctx, 24)
    move_to(ctx, 300, 40)
    show_text(ctx, "Your Files Universe")
    
    # Stats
    set_font_size(ctx, 12)
    move_to(ctx, 20, 580)
    show_text(ctx, "$(length(file_data)) items | $(count(x->x.is_dir, file_data)) directories")
    
    buffer = getMiniFBBufferFromCairoSurface(surface)
    put!(outputs[:MiniFB], buffer)
end

@api function animated_file_universe(duration::Float64 = Inf)
    memory[:file_viz_running] = true
    start_time = time()
    while get(memory, :file_viz_running, true) && (time() - start_time < duration)
        create_file_visualization()
        sleep(0.05)
    end
end

@api const animated_file_visualization_description = "Creates an animated bubble universe visualization of files in the current directory. Files float as bubbles with size based on file size and colors based on type. Use `animated_file_universe(duration)` to run for a specific duration or `animated_file_universe()` to run indefinitely until memory[:file_viz_running] = false"
