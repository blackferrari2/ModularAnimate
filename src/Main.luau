local src = script.Parent

local Config = require(src.Config)
local Poses = require(src.Poses)
local PoseController = require(src.Handlers.PoseController)
local AnimationPlayer = require(src.Handlers.AnimationPlayer)

local ModularAnimate = {
    DefaultConfigs = Config.createConfigMap(),

    DefaultIDs = {
        [Enum.HumanoidRigType.R6] = {
            [Poses.Them.Idle] = "rbxassetid://180435571",
            [Poses.Them.Walk] = "rbxassetid://180426354",
            [Poses.Them.Jump] = "rbxassetid://125750702",
            [Poses.Them.Fall] = "rbxassetid://180436148",
            [Poses.Them.Sit] = "rbxassetid://178130996",
            [Poses.Them.Climb] = "rbxassetid://180436334",
        },
    }
}

-- special settings
Config.getConfigFromMap(ModularAnimate.DefaultConfigs, Poses.Them.Idle).weight = 9
Config.getConfigFromMap(ModularAnimate.DefaultConfigs, Poses.Them.Fall).transitionTime = 0.3
Config.getConfigFromMap(ModularAnimate.DefaultConfigs, Poses.Them.Jump).duration = 0.3

ModularAnimate.__index = ModularAnimate

---------------

type self = {
    configMap: Config.ConfigMap,
    poseController: PoseController.PoseController?,
    animationPlayer: AnimationPlayer.AnimationPlayer?,
    humanoidDeathCleanupConnection: RBXScriptConnection?,
}

export type ModularAnimate = typeof(setmetatable({} :: self, ModularAnimate))

---------------

local ERROR_RIG_NOT_SUPPORTED = "%s Rigs arent supported."

---------------

function ModularAnimate.new(customConfigMap: Config.ConfigMap?): ModularAnimate
    local self = {
        configMap = customConfigMap or ModularAnimate.DefaultConfigs,
    }

    setmetatable(self, ModularAnimate)

    return self
end

function ModularAnimate.animate(self: ModularAnimate, humanoid: Humanoid, animator: Animator)
    if self.poseController then
        return
    end

    for pose, config in pairs(self.configMap) do
        if config.id then
            continue
        end

        local defaultIDs = ModularAnimate.DefaultIDs[humanoid.RigType]

        if not defaultIDs then
            error(string.format(ERROR_RIG_NOT_SUPPORTED, humanoid.RigType.Name))
        end

        config.id = defaultIDs[pose]
    end

    local poseController = PoseController.new(humanoid, self.configMap)
    local animationPlayer = AnimationPlayer.new(animator, poseController, self.configMap)

    poseController:connect()
    animationPlayer:connect()

    self.poseController = poseController
    self.animationPlayer = animationPlayer
    self.humanoidDeathCleanupConnection = humanoid.Died:Once(function()
        self:destroy()
    end)
end

function ModularAnimate.modify(self: ModularAnimate, pose: Poses.Pose, newConfig: Config.Config)
    Config.replaceConfigFromMap(self.configMap, pose, newConfig)

    if not self.poseController or not self.animationPlayer then
        return
    end
    
    local currentPose = self.poseController.currentPose

    -- we only need to adjust animations that might already be playing.. wow
    if pose == currentPose then
        self.animationPlayer:play(currentPose)

        local currentAnimationTrack = self.animationPlayer.currentAnimationTrack
        local speed

        if currentPose == Poses.Them.Walk then
            speed = self.animationPlayer:getAnimationSpeedRelativeToWalkSpeed(self.poseController.cache.walkingSpeed)
        elseif currentPose == Poses.Them.Climb then
            speed = self.poseController.cache.climbingSpeed / 12
        end

        -- Yea you just gotta do that..
        if speed then
            currentAnimationTrack:AdjustSpeed(newConfig.speed * speed)
        end
    end
end

function ModularAnimate.stop(self: ModularAnimate)
    if not self.poseController or not self.animationPlayer or not self.humanoidDeathCleanupConnection then
        return
    end

    self.poseController:destroy()
    self.animationPlayer:destroy()
    self.humanoidDeathCleanupConnection:Disconnect()
    self.poseController = nil
    self.animationPlayer = nil
    self.humanoidDeathCleanupConnection = nil
end

function ModularAnimate.destroy(self: ModularAnimate)
    self:stop()

    local setmetatable: any = setmetatable
    setmetatable(self, nil)
end

function ModularAnimate.getConfig(self: ModularAnimate, of: Poses.Pose): Config.Config
    return Config.getConfigFromMap(self.configMap, of):clone()
end

---------------

return ModularAnimate