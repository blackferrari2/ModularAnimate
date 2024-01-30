local Poses = require(script.Parent.Poses)

local Config = {}
Config.__index = Config

---------------

type self = {
    id: string?,
    weight: number,
    priority: Enum.AnimationPriority,
    transitionTime: number,
    speed: number,
    duration: number,
}

export type Config = typeof(setmetatable({} :: self, Config))
export type ConfigMap = {[Poses.Pose]: Config}

---------------

function Config.new(): Config
    local self = {
        weight = 10,
        priority = Enum.AnimationPriority.Core,
        transitionTime = 0.1,
        speed = 1,
        duration = 0,
    }

    setmetatable(self, Config)

    return self
end

function Config.clone(self: Config): Config
    local new = Config.new()

    for key, value in pairs(self) do
        new[key] = value
    end

    return new
end

--

function Config.createConfigMap(): ConfigMap
    local map = {}

    for _, pose in pairs(Poses.Them) do
        map[pose] = Config.new()
    end

    return map
end

function Config.replaceConfigFromMap(configMap: ConfigMap, pose: Poses.Pose, new: Config)
    configMap[pose] = new
end

function Config.getConfigFromMap(configMap: ConfigMap, pose: Poses.Pose): Config
    return configMap[pose]
end

---------------

return Config