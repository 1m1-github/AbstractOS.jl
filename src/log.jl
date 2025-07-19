using Logging
log_name(x) = "$(OS_ROOT_DIR)/logs/log-$x-$(round(Int, time()))"
logger = SimpleLogger(open(log_name("1M1"), "a"), Logging.Debug)
# logger = SimpleLogger(open("./logs_1M1", "a"), Logging.Debug)
global_logger(logger)
