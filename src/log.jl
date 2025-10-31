using Logging

struct Logger <: AbstractLogger
    console_logger::ConsoleLogger
    file_logger::SimpleLogger
end

Logging.min_enabled_level(logger::Logger) = min(Logging.min_enabled_level(logger.console_logger), Logging.min_enabled_level(logger.file_logger))

Logging.shouldlog(logger::Logger, level, _module, group, id) = Logging.shouldlog(logger.console_logger, level, _module, group, id) || Logging.shouldlog(logger.file_logger, level, _module, group, id)

Logging.handle_message(logger::Logger, level, message, _module, group, id, file, line; kwargs...) = begin
    # Logging.handle_message(logger.console_logger, level, message, _module, group, id, file, line; kwargs...)
    Logging.handle_message(logger.file_logger, level, message, _module, group, id, file, line; kwargs...)
end

const file_stream(x) = open(joinpath(OS_ROOT_DIR, "logs", "log-$(round(Int, time()))-$x"), "a")
const file_logger = SimpleLogger(file_stream("aos.txt"), Logging.Info)
const console_logger = ConsoleLogger(stdout, Logging.Info)
const logger = Logger(console_logger, file_logger)
global_logger(logger)
