using Logging
log_name(x) = "$(WORK_DIR)/log-$x-$(round(Int, time()))"
logger = SimpleLogger(open(log_name("1M1"), "a"), Logging.Debug)
# logger = SimpleLogger(open("./logs_1M1", "a"), Logging.Debug)
global_logger(logger)
