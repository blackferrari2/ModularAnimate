local packages = script.Parent

local t = require(packages.t)
local Config = require(script.Config)
local PoseController = require(script.PoseController)
local AnimationHandler = require(script.AnimationHandler)

local ModularAnimate = {
    Animations = PoseController.Poses,

    DefaultConfigs = {
        [PoseController.Poses.Idle] = Config.new("rbxassetid://180435571"),
        [PoseController.Poses.Walk] = Config.new("rbxassetid://180426354"),
        [PoseController.Poses.Jump] = Config.new("rbxassetid://125750702"),
        [PoseController.Poses.Fall] = Config.new("rbxassetid://180436148"),
        [PoseController.Poses.Sit] = Config.new("rbxassetid://178130996"),
        [PoseController.Poses.Climb] = Config.new("rbxassetid://180436334"),
    },
}

ModularAnimate.__index = ModularAnimate

-- special settings
ModularAnimate.DefaultConfigs[PoseController.Poses.Idle].weight = 9
ModularAnimate.DefaultConfigs[PoseController.Poses.Fall].transitionTime = 0.3
ModularAnimate.DefaultConfigs[PoseController.Poses.Jump].duration = 0.3

---------------

type self = {
    poseController: PoseController.PoseController,
    animationHandler: AnimationHandler.AnimationHandler,
    configs: {[PoseController.Pose]: Config.Config},
}

export type ModularAnimate = typeof(setmetatable({} :: self, ModularAnimate))

---------------

local ERROR_INVALID_CONFIG = "config %s doesnt exist"

--

local function copyConfigs(from: {[PoseController.Pose]: Config.Config}): {[PoseController.Pose]: Config.Config}
    local new = {}

    for pose, config in pairs(from) do
        new[pose] = config:copy()
    end

    return new
end

---------------

function ModularAnimate.new(humanoid: Humanoid, animator: Animator): ModularAnimate
    assert(t.instanceOf("Humanoid")(humanoid))
    assert(t.instanceOf("Animator")(animator))

    local configs = copyConfigs(ModularAnimate.DefaultConfigs)
    local poseController = PoseController.new(humanoid, configs)
    local animationHandler = AnimationHandler.new(animator, poseController, configs)

    local self = {
        poseController = poseController,
        animationHandler = animationHandler,
        configs = configs,
    }

    setmetatable(self, ModularAnimate)

    poseController:connect()
    animationHandler:connect()

    return self
end

--[[
    changes animation data

    example code:

    ```lua
    animate:modify(function()
        local config = animate:getConfig(animate.Animations.Walk)
        
        config.id = "rbxassetid://10353567659"
        config.speed = 3
        
        local config2 = animate:getConfig(animate.Animations.Jump)

        config2.id = "rbxassetid://10353567659"
        config2.duration = 10
    end)
    ```
]]
function ModularAnimate.modify(self: ModularAnimate, changes: () -> ())
    assert(t.callback(changes))

    changes()
    self:_refresh()
end

function ModularAnimate.getConfig(self: ModularAnimate, of: PoseController.Pose): Config.Config
    local config = self.configs[of]

    if not config then
        error(string.format(ERROR_INVALID_CONFIG, of))
    end

    return config
end

--

function ModularAnimate._refresh(self: ModularAnimate)
    self.poseController:disconnect()
    self.poseController:connect()
    self.animationHandler:disconnect()
    self.animationHandler:connect()
end

---------------

return ModularAnimate