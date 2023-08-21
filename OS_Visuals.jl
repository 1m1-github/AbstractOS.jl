module OS_Visuals
using MiniFB, Colors
struct Outstream
    width::Int
    height::Int
    window::Ptr{mfb_window}
end
OUTSTREAMS = [
    Outstream(
        800,
        600,
        mfb_open_ex("juliaOS", 800, 600, MiniFB.WF_RESIZABLE))]
abstract type Visual{T,N} <: AbstractArray{T,N} end
abstract type RectangularVisual{T,N} <: Visual{T,N} end
function show(a::RectangularVisual{Colors.RGB,2})

    global OUTSTREAM_WIDTH
    global OUTSTREAM_HEIGHT
    global OUTSTREAMS

    for oustream in OUTSTREAMS
        # buffer = zeros(UInt32, OUTSTREAM_WIDTH*OUTSTREAM_HEIGHT)
        # while true

        # TODO add some rendering into the buffer
        # buffer = rand(UInt32, WIDTH, HEIGHT)
        buffer = map(x -> mfb_rgb(x[:r], x[:g], x[:b]), a)

        state = mfb_update(oustream.window, buffer)
        if state != MiniFB.STATE_OK
            break
        end
        # end    
    end
end
end

rgb_2_uint(x) = mfb_rgb(x.r, x.g, x.b)
f(x, i) = i*sin(x)
function f()
    W = 100
    H = 100
    window = mfb_open_ex("juliaOS", W, H, MiniFB.WF_RESIZABLE)
    i = 10
    while true
        i += 1 ; i %= 1000

        # a = rand(RGB, W, H)
        a = fill(RGB(), W, H)
        a
        for x in 1:W
            y = round(Int, f(x, i))
            (x < 1 || y < 1) && continue
            @show x, y
            a[x, y] = RGB(1.0, 1.0, 1.0)
        end

        buffer = rgb_2_uint.(a)

        state = mfb_update(window, buffer)
        if state != MiniFB.STATE_OK
            break
        end
    end
end
f()
RGB()

using Images, VideoIO, ImageIO
vp=joinpath("/Users/1m1", "Downloads", "dcim3", "PXL_20230424_235614576.TS.mp4")
vp=joinpath("/Users/1m1", "Downloads", "dcim3", "PXL_20230721_181315310.mp4")
video = VideoIO.load(vp)
video[1]