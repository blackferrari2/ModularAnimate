local src = script.Parent.Parent
local packages = src.Parent

local Meta = require(script.Parent.Meta)
local Signal = require(packages.Signal)
local Config = require(src.Config)
local Poses = require(src.Poses)

local PoseController = {
    Handlers = {},
}

PoseController.__index = PoseController

----------------------

type self = {
    humanoid: Humanoid,
    currentPose: Poses.Pose,
    poseChanged: Signal.Signal<Poses.Pose>,
    configMap: Config.ConfigMap,
}

export type PoseController = typeof(setmetatable({} :: self, PoseController)) & Meta.Handler

---------------

function PoseController.new(humanoid: Humanoid, configMap: Config.ConfigMap): PoseController
    local self = Meta.new()
    self.humanoid = humanoid
    self.currentPose = Poses.Them.Idle
    self.poseChanged = Signal.new()
    self.configMap = configMap

    setmetatable(self, PoseController)

    return self
end

function PoseController.switch(self: PoseController, to: Poses.Pose)
    if self.currentPose == to then
        return
    end

    self.currentPose = to
    self.poseChanged:Fire(to)
end

function PoseController.disconnect(self: PoseController)
    self:switch(Poses.Them.Idle)
    Meta.disconnect(self)
end

function PoseController.destroy(self: PoseController)
    Meta.destroy(self)
    self.poseChanged:Destroy()
end

--

PoseController.Handlers[Poses.Them.Idle] = function(self: PoseController): RBXScriptConnection
    local connection = self.humanoid.Running:Connect(function(speed)
        if speed > 1 then
            return
        end

        self.cache.walkingSpeed = 0
        self:switch(Poses.Them.Idle)
    end)

    return connection
end

PoseController.Handlers[Poses.Them.Walk] = function(self: PoseController): RBXScriptConnection
    local connection = self.humanoid.Running:Connect(function(speed)
        if speed < 1 then
            return
        end

        self.cache.walkingSpeed = speed
        self:switch(Poses.Them.Walk)
    end)

    return connection
end

PoseController.Handlers[Poses.Them.Jump] = function(self: PoseController): RBXScriptConnection
    local connection = self.humanoid.StateChanged:Connect(function(_, newState)
        if newState ~= Enum.HumanoidStateType.Jumping then
            return
        end

        self.cache.isJumping = true
        self:switch(Poses.Them.Jump)
    end)

    return connection
end

PoseController.Handlers[Poses.Them.Fall] = function(self: PoseController): RBXScriptConnection
    local connection = self.humanoid.StateChanged:Connect(function(_, newState)
        if newState ~= Enum.HumanoidStateType.Freefall then
            return
        end

        local jumpConfig = Config.getConfigFromMap(self.configMap, Poses.Them.Jump)

        if self.cache.isJumping then
            local thread
            local connection = self.humanoid.StateChanged:Once(function()
                self.cache.isJumping = false
                task.cancel(thread)
            end)

            thread = task.spawn(function()
                task.wait(jumpConfig.duration)

                connection:Disconnect()
                self:switch(Poses.Them.Fall)
            end)

            return
        end

        self:switch(Poses.Them.Fall)
    end)

    return connection
end

PoseController.Handlers[Poses.Them.Climb] = function(self: PoseController): RBXScriptConnection
    local connection = self.humanoid.Climbing:Connect(function(speed)
        self.cache.climbingSpeed = speed
        self:switch(Poses.Them.Climb)
    end)

    return connection
end

PoseController.Handlers[Poses.Them.Sit] = function(self: PoseController): RBXScriptConnection
    local connection = self.humanoid.StateChanged:Connect(function(_, newState)
        if newState ~= Enum.HumanoidStateType.Seated then
            return
        end

        self:switch(Poses.Them.Sit)
    end)

    return connection
end

----------------------

setmetatable(PoseController, Meta)

return PoseController