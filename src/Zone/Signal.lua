-- Signal
-- Author: Quenty
-- Source: https://github.com/Quenty/NevermoreEngine/blob/1bed579e0fc63cf4124a1e50c2379b8a7dc9ed1d/Modules/Shared/Events/Signal.lua
-- License: MIT (https://github.com/Quenty/NevermoreEngine/blob/version2/LICENSE.md)


local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"
Signal.totalConnections = 0

function Signal.new(ignoreCC)
	local self = setmetatable({}, Signal)

	self._bindableEvent = Instance.new("BindableEvent")
	self._argData = nil
	self._argCount = nil -- Prevent edge case of :Fire("A", nil) --> "A" instead of "A", nil
	if not ignoreCC then
		self.connectionsChanged = Signal.new(true)
	end

	return self
end

function Signal:Fire(...)
	self._argData = {...}
	self._argCount = select("#", ...)
	self._bindableEvent:Fire()
	self._argData = nil
	self._argCount = nil
end

function Signal:Connect(handler)
	if not (type(handler) == "function") then
		error(("connect(%s)"):format(typeof(handler)), 2)
	end
	-- Slightly modified this to account for very rare times
	-- when an event is duplo-called and both _argData and
	-- _argCount == nil
	local connection = self._bindableEvent.Event:Connect(function()
		if self._argData ~= nil then
			handler(unpack(self._argData, 1, self._argCount))
		end
	end)
	-- this enables us to determine when a signal is connected to from an outside source
	self.totalConnections += 1
	if self.connectionsChanged then
		self.connectionsChanged:Fire(self.totalConnections)
	end

	return connection
end

function Signal:Wait()
	self._bindableEvent.Event:Wait()
	assert(self._argData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
	return unpack(self._argData, 1, self._argCount)
end

function Signal:Destroy()
	if self._bindableEvent then
		self._bindableEvent:Destroy()
		self._bindableEvent = nil
	end
	if self.connectionsChanged then
		self.connectionsChanged:Destroy()
		self.connectionsChanged = nil
	end

	self._argData = nil
	self._argCount = nil

	self.totalConnections -= 1
	self.connectionsChanged:Fire(self.totalConnections)
end

function Signal:Disconnect()
	self:Destroy()
end

return Signal