local src = script.Parent.Parent
local packages = src.Parent

local Meta = require(script.Parent.Meta)
local Signal = require(packages.Signal)
local PoseController = require(script.Parent.PoseController)
local Poses = require(src.Poses)
local Config = require(src.Config)

local AnimationPlayer = {
    Handlers = {},
}

AnimationPlayer.__index = AnimationPlayer

----------------------

type self = {
    animator: Animator,
    poseController: PoseController.PoseController,
    configMap: Config.ConfigMap,
    currentAnimationTrack: AnimationTrack?,
}

export type AnimationPlayer = typeof(setmetatable({} :: self, AnimationPlayer)) & Meta.Handler

---------------

local function getAnimationFrom(id: string): Animation
    local animation = Instance.new("Animation")

    animation.AnimationId = id

    return animation
end

---------------

function AnimationPlayer.new(animator: Animator, poseController: PoseController.PoseController, configMap: Config.ConfigMap): AnimationPlayer
    local self = Meta.new()
    self.animator = animator
    self.poseController = poseController
    self.configMap = configMap

    setmetatable(self, AnimationPlayer)

    return self
end

function AnimationPlayer.play(self: AnimationPlayer, pose: Poses.Pose)
    self:stop()

    local config = Config.getConfigFromMap(self.configMap, pose)
    local animation = getAnimationFrom(config.id)
    local track = self.animator:LoadAnimation(animation)

    track:Play(config.transitionTime, config.weight, config.speed)
    self.currentAnimationTrack = track
end

function AnimationPlayer.stop(self: AnimationPlayer)
    if not self.currentAnimationTrack then
        return
    end

    local config = Config.getConfigFromMap(self.configMap, self.poseController.currentPose)

    self.currentAnimationTrack:Stop(config.transitionTime)
    self.currentAnimationTrack = nil
end

function AnimationPlayer.connect(self: AnimationPlayer)
    self.cache.originalWalkSpeed = self.poseController.humanoid.WalkSpeed
    Meta.connect(self)
end

function AnimationPlayer.disconnect(self: AnimationPlayer)
    self:stop()
    Meta.disconnect(self)

    if self.cache.cleanupConnection then
        self.cache.cleanupConnection:Disconnect()
    end
end

--

function AnimationPlayer.getAnimationSpeedRelativeToWalkSpeed(self: AnimationPlayer, speed: number)
    return speed / self.cache.originalWalkSpeed
end

AnimationPlayer.Handlers[Poses.Them.Idle] = function(self: AnimationPlayer): Signal.Connection
    local connection = self.poseController.poseChanged:Connect(function(newPose)
        if newPose == Poses.Them.Idle then
            self:play(Poses.Them.Idle)
        end
    end)

    return connection
end

AnimationPlayer.Handlers[Poses.Them.Walk] = function(self: AnimationPlayer): Signal.Connection
    local humanoid = self.poseController.humanoid

    local connection = self.poseController.poseChanged:Connect(function(newPose)
        if newPose ~= Poses.Them.Walk then
            return
        end

        local config = Config.getConfigFromMap(self.configMap, Poses.Them.Walk)

        self:play(Poses.Them.Walk)
        self.currentAnimationTrack:AdjustSpeed(config.speed * self:getAnimationSpeedRelativeToWalkSpeed(self.poseController.cache.walkingSpeed))

        local updateSpeedConnection = humanoid.Running:Connect(function(speed)
            if speed < 1 then
                return
            end

            config = Config.getConfigFromMap(self.configMap, Poses.Them.Walk)
            self.currentAnimationTrack:AdjustSpeed(config.speed * self:getAnimationSpeedRelativeToWalkSpeed(speed))
        end)

        local cleanupConnection = self.poseController.poseChanged:Once(function()
            updateSpeedConnection:Disconnect()
        end)

        self.cache.cleanupConnection = cleanupConnection
    end)

    return connection
end

AnimationPlayer.Handlers[Poses.Them.Jump] = function(self: AnimationPlayer): Signal.Connection
    local connection = self.poseController.poseChanged:Connect(function(newPose)
        if newPose == Poses.Them.Jump then
            self:play(Poses.Them.Jump)
        end
    end)

    return connection
end

AnimationPlayer.Handlers[Poses.Them.Fall] = function(self: AnimationPlayer): Signal.Connection
    local connection = self.poseController.poseChanged:Connect(function(newPose)
        if newPose == Poses.Them.Fall then
            self:play(Poses.Them.Fall)
        end
    end)
    return connection
end

AnimationPlayer.Handlers[Poses.Them.Climb] = function(self: AnimationPlayer): Signal.Connection
    local humanoid = self.poseController.humanoid

    local connection = self.poseController.poseChanged:Connect(function(newPose)
        if newPose ~= Poses.Them.Climb then
            return
        end

        local config = Config.getConfigFromMap(self.configMap, Poses.Them.Climb)

        self:play(Poses.Them.Climb)
        self.currentAnimationTrack:AdjustSpeed(config.speed * (self.poseController.cache.climbingSpeed / 12))

        local updateSpeedConnection = humanoid.Climbing:Connect(function(speed)
            config = Config.getConfigFromMap(self.configMap, Poses.Them.Climb)
            self.currentAnimationTrack:AdjustSpeed(config.speed * (speed / 12))
        end)

        local cleanupConnection = self.poseController.poseChanged:Once(function()
            updateSpeedConnection:Disconnect()
        end)

        self.cache.cleanupConnection = cleanupConnection
    end)

    return connection
end

AnimationPlayer.Handlers[Poses.Them.Sit] = function(self: AnimationPlayer): Signal.Connection
    local connection = self.poseController.poseChanged:Connect(function(newPose)
        if newPose == Poses.Them.Sit then
            self:play(Poses.Them.Sit)
        end
    end)

    return connection
end

----------------------

setmetatable(AnimationPlayer, Meta)

return AnimationPlayer