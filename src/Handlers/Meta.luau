local packages = script.Parent.Parent.Parent

local Signal = require(packages.Signal)

local Handler = {
    Handlers = {},
}

Handler.__index = Handler

----------------------

type self = {
    connections: {RBXScriptConnection | Signal.Connection},
    cache: {[string]: any},
}

export type Handler = typeof(setmetatable({} :: self, Handler))

---------------

function Handler.new(): Handler
    local self = {
        connections = {},
        cache = {},
    }

    setmetatable(self, Handler)

    return self
end

function Handler.connect(self: Handler)
    local connections = self.connections

    for pose, handler in pairs(self.Handlers) do
        if connections[pose] then
            continue
        end

        connections[pose] = handler(self)
    end
end

function Handler.disconnect(self: Handler)
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    table.clear(self.connections)
end

function Handler.destroy(self: Handler)
    self:disconnect()

    local setmetatable: any = setmetatable
    setmetatable(self, nil)
end

----------------------

return Handler