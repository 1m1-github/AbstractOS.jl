function start_browser_signals()
    while true
        sleep(1)
        global outputs
        !haskey(outputs, :Browser) && continue
        global signals
        put!(outputs[:Browser], "", "document.getElementById('signals_1M1').innerHTML='$signals'")
    end
end
tasks[:browser_signals] = @async start_browser_signals()
