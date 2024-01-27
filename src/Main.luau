local packages = script.Parent.Parent

local t = require(packages.t)
local Config = require(script.Parent.Config)
local PoseController = require(script.Parent.PoseController)
local AnimationHandler = require(script.Parent.AnimationHandler)

local ModularAnimate = {
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
    configs: PoseController.Configs,
    isActive: boolean,
    humanoidDeathCleanupConnection: RBXScriptConnection, 
}

export type ModularAnimate = typeof(setmetatable({} :: self, ModularAnimate))

---------------

local ERROR_INVALID_CONFIG = "config %s doesnt exist"

--

local function copyConfigs(from: PoseController.Configs): PoseController.Configs
    local new = {}

    for pose, config in pairs(from) do
        new[pose] = config:copy()
    end

    return new
end

---------------

function ModularAnimate.new(humanoid: Humanoid, animator: Animator): ModularAnimate
    return ModularAnimate._new(humanoid, animator, ModularAnimate.DefaultConfigs)
end

function ModularAnimate.fromConfigs(humanoid: Humanoid, animator: Animator, configs: PoseController.Configs): ModularAnimate
    return ModularAnimate._new(humanoid, animator, configs)
end

function ModularAnimate.connect(self: ModularAnimate)
    self.poseController:connect()
    self.animationHandler:connect()

    self.humanoidDeathCleanupConnection = self.poseController.humanoid.Died:Connect(function()
        self:disconnect()
    end)
end

function ModularAnimate.disconnect(self: ModularAnimate)
    self.poseController:disconnect()
    self.animationHandler:disconnect()
    self.humanoidDeathCleanupConnection:Disconnect()
end

function ModularAnimate.modify(self: ModularAnimate, pose: PoseController.Pose, newConfig: Config.Config)
    assert(t.keyOf(PoseController.Poses)(pose), "pose not a pose.")
    assert(t.literal(Config)(getmetatable(newConfig)), "configs not a config")

    self.configs[pose] = newConfig
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

function ModularAnimate._new(humanoid: Humanoid, animator: Animator, configs: PoseController.Configs): ModularAnimate
    assert(t.instanceOf("Humanoid")(humanoid))
    assert(t.instanceOf("Animator")(animator))
    assert(t.keys(t.keyOf(PoseController.Poses))(configs), "key of configs not a pose.")

    for _, pose in pairs(PoseController.Poses) do
        local config = configs[pose]

        if not config then
            config = ModularAnimate.DefaultConfigs[pose]
            configs[pose] = config
        end

        assert(t.literal(Config)(getmetatable(config)), "value of configs not a config")
    end

    configs = copyConfigs(configs)

    local poseController = PoseController.new(humanoid, configs)
    local animationHandler = AnimationHandler.new(animator, poseController, configs)

    local self = {
        poseController = poseController,
        animationHandler = animationHandler,
        configs = configs,
        isActive = false,
        humanoidDeathCleanupConnection = nil,
    }

    setmetatable(self, ModularAnimate)

    return self
end

function ModularAnimate._refresh(self: ModularAnimate)
    self.poseController:disconnect()
    self.poseController:connect()
    self.animationHandler:disconnect()
    self.animationHandler:connect()
end

---------------

return ModularAnimate