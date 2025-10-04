local timer = {
    timer_func = {}
}

local mt = { __index = timer.timer_func }

function timer.New()
    local self = setmetatable({}, mt)
    
    self.time = 0
    self.dwell = 0
    
    return self
end

return timer