return {
	-- Enable/disable verbose debug logging.
	-- Will destroy your output if enabled!
	VerboseOutput = false,

	-- Timeout (in seconds) that ::Init() callbacks must finish executing within.
	-- If this timeout is exceeded, a warning will be pushed to the output.
	SlowInitTimeout = 0.25,

	-- Case-sensitive names of job modules that will be ignored (not required)
	-- during the initialization phase.
	IgnoredJobNames = {},
}
