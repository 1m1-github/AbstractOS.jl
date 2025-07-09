function start_browser_signals()
    global signals
    # previous_signal_next_running = signals[:next_running]
    @async while true
        sleep(1)
        !haskey(outputs, :Browser) && continue
        # previous_signal_next_running == signals[:next_running] && continue
        # previous_signal_next_running = signals[:next_running]
        # style_display = previous_signal_next_running ? "inline-block" : "none"
        put!(outputs[:Browser], "<script>document.getElementById('signals_1M1').innerHTML='$signals'</script>")
        # put!(outputs[:Browser], "document.getElementById('signals_1M1').innerHTML='$signals'")
    end
end
@async start_browser_signals()
