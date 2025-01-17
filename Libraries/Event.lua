
local event, handlers, interruptingKeysDown, lastInterrupt = {
	interruptingEnabled = true,
	interruptingDelay = 1,
	interruptingKeyCodes = {
		[29] = true,
		[46] = true,
		[56] = true
	},
	push = os.queueEvent
}, {}, {}, 0

local computerPullSignal, computerUptime, mathHuge, mathMin, skipSignalType = os.pullEvent, computer.uptime, math.huge, math.min

--------------------------------------------------------------------------------------------------------

function event.addHandler(callback, interval, times)
	assert(type(callback) == "function", "Callback must be a function")
	assert(type(interval) == "number" or interval == nil, "Interval must be a positive number")
	assert(times == nil or type(times) == "number" or times == nil, "Times must be a positive number")

	local handler = {
		callback = callback,
		times = times or mathHuge,
		interval = interval,
		nextTriggerTime = interval and computerUptime() + interval or 0
	}

	handlers[handler] = true

	return handler
end

function event.removeHandler(handler)
	assert(type(handler) == "table", "Handler must be a table")

	if handlers[handler] then
		handlers[handler] = nil

		return true
	else
		return false, "Handler with given table is not registered"
	end
end

function event.getHandlers()
	return handlers
end

function event.skip(signalType)
	skipSignalType = signalType
end

function event.pull(preferredTimeout)	
	local uptime, signalData = computerUptime()
	local deadline = uptime + (preferredTimeout or mathHuge)
	
	repeat
		-- Determining pullSignal timeout
		timeout = deadline
		for handler in pairs(handlers) do
			if handler.nextTriggerTime > 0 then
				timeout = mathMin(timeout, handler.nextTriggerTime)
			end
		end

		-- Pulling signal data
		if timeout ~= mathHuge then
			os.startTimer(timeout - computerUptime())
		end
		signalData = { computerPullSignal() }
				
		-- Handlers processing
		for handler in pairs(handlers) do
			if handler.times > 0 then
				uptime = computerUptime()

				if
					handler.nextTriggerTime <= uptime
				then
					handler.times = handler.times - 1
					if handler.nextTriggerTime > 0 then
						handler.nextTriggerTime = uptime + handler.interval
					end

					-- Callback running
					handler.callback(table.unpack(signalData))
				end
			else
				handlers[handler] = nil
			end
		end

		-- Program interruption support. It's faster to do it here instead of registering handlers
		if (signalData[1] == "key" or signalData[1] == "key_up") and event.interruptingEnabled then
			-- Analysing for which interrupting key is pressed - we don't need keyboard API for this
			if event.interruptingKeyCodes[signalData[4]] then
				interruptingKeysDown[signalData[4]] = signalData[1] == "key" and true or nil
			end

			local shouldInterrupt = true
			for keyCode in pairs(event.interruptingKeyCodes) do
				if not interruptingKeysDown[keyCode] then
					shouldInterrupt = false
				end
			end
			
			if shouldInterrupt and uptime - lastInterrupt > event.interruptingDelay then
				lastInterrupt = uptime
				error("interrupted", 0)
			end
		end
		
		-- Loop-breaking condition
		if signalData[1] then
			if signalData[1] == skipSignalType then
				skipSignalType = nil
			else
				return table.unpack(signalData)
			end
		end
	until uptime >= deadline
end

-- Sleeps "time" of seconds via "busy-wait" concept
function event.sleep(time)
	assert(type(time) == "number" or time == nil, "Time must be a positive number")

	local deadline = computerUptime() + (time or 0)
	repeat
		event.pull(deadline - computerUptime())
	until computerUptime() >= deadline
end

--------------------------------------------------------------------------------------------------------

return event
