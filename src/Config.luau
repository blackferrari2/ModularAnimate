local Config = {}
Config.__index = Config

---------------

type self = {
    id: string,
    weight: number,
    priority: Enum.AnimationPriority,
    transitionTime: number,
    speed: number,
    duration: number,
}

export type Config = typeof(setmetatable({} :: self, Config))

---------------

function Config.new(id: string): Config
    local self = {
        id = id,
        weight = 10,
        priority = Enum.AnimationPriority.Core,
        transitionTime = 0.1,
        speed = 1,
        duration = 0,
    }

    setmetatable(self, Config)

    return self
end

function Config.copy(self: Config): Config
    local new = Config.new(self.id)

    for key, value in pairs(self) do
        new[key] = value
    end

    return new
end

---------------

return Config