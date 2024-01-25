local packages = script.Parent.Parent

local Signal = require(packages.Signal)
local PoseController = require(script.Parent.PoseController)

local AnimationHandler = {}
AnimationHandler.__index = AnimationHandler

----------------------

type self = {
    current: AnimationTrack,
    animator: Animator,
    poseController: PoseController.PoseController,
    configs: PoseController.Configs,
    animationTracks: {[PoseController.Pose]: AnimationTrack},
    connections: {Signal.Connection},
    cache: {Signal.Connection},
}

export type AnimationHandler = typeof(setmetatable({} :: self, AnimationHandler))

---------------

local function getAnimationFrom(id: string): Animation
    local animation = Instance.new("Animation")

    animation.AnimationId = id

    return animation
end

---------------

function AnimationHandler.new(animator: Animator, poseController: PoseController.PoseController, configs: PoseController.Configs): AnimationHandler
    local self = {
        current = nil,
        animator = animator,
        poseController = poseController,
        configs = configs,
        animationTracks = {},
        connections = {},
        cache = {},
    }

    setmetatable(self, AnimationHandler)

    self:_refreshAnimationTracks()

    return self
end

function AnimationHandler.connect(self: AnimationHandler)
    local poseController = self.poseController

    self:_refreshAnimationTracks()
    self:_handle(PoseController.Poses.Jump)
    self:_handle(PoseController.Poses.Fall)
    self:_handle(PoseController.Poses.Sit)
    self:_handle(PoseController.Poses.Idle)

    local humanoid = poseController.humanoid
    local originalSpeed = humanoid.WalkSpeed

    local function getAnimationSpeed(currentSpeed: number): number
        return currentSpeed / originalSpeed
    end

    self:_handle(PoseController.Poses.Climb, function()
        local track = self.current
        local config = self:getConfig(PoseController.Poses.Climb)

        track:AdjustSpeed(config.speed * getAnimationSpeed(poseController.climbingSpeed))

        local updateSpeedConnection = humanoid.Climbing:Connect(function(speed)
            track:AdjustSpeed(config.speed * (speed / 12))
        end)

        self:_addCache(updateSpeedConnection)
        self:_addCache(poseController.changed:Once(function()
            self:_clearCache()
        end))
    end)

    self:_handle(PoseController.Poses.Walk, function()
        local track = self.current
        local config = self:getConfig(PoseController.Poses.Walk)

        track:AdjustSpeed(config.speed * getAnimationSpeed(poseController.walkingSpeed))

        local updateSpeedConnection = humanoid.Running:Connect(function(speed)
            track:AdjustSpeed(config.speed * getAnimationSpeed(speed))
        end)

        self:_addCache(updateSpeedConnection)
        self:_addCache(poseController.changed:Once(function()
            self:_clearCache()
        end))
    end)

    -- play animation of current pose by TRICKING the connect into idk doing the the event thing whatever i dont Care it works
    -- sorry for the gotcha im so tired

    local current = poseController.current

    poseController:change(PoseController.Poses.Idle)
    poseController:change(current)
end

function AnimationHandler.disconnect(self: AnimationHandler)
    self:_clearCache()

    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    self.connections = {}
end

function AnimationHandler.getConfig(self: AnimationHandler, of: PoseController.Pose)
    return self.configs[of]
end

function AnimationHandler.getAnimationTrack(self: AnimationHandler, of: PoseController.Pose)
    return self.animationTracks[of]
end

--

function AnimationHandler._handle(self: AnimationHandler, pose: PoseController.Pose, callback: () -> ())
    local connection = self.poseController.changed:Connect(function(newPose)
        if pose ~= newPose then
            return
        end

        self:_play(pose)

        if callback then
            callback()
        end
    end)

    self:_addConnection(connection)
end

function AnimationHandler._addConnection(self: AnimationHandler, connection: Signal.Connection)
    table.insert(self.connections, connection)
end

function AnimationHandler._addCache(self: AnimationHandler, connection: Signal.Connection)
    table.insert(self.cache, connection)
end

function AnimationHandler._clearCache(self: AnimationHandler)
    for _, connection in pairs(self.cache) do
        connection:Disconnect()
    end

    self.cache = {}
end

function AnimationHandler._play(self: AnimationHandler, pose: PoseController.Pose)
    local track = self:getAnimationTrack(pose)

    if self.current == track then
        return
    end

    local config = self:getConfig(pose)

    if self.current then
        self.current:Stop(config.transitionTime)
    end

    track.Priority = config.priority
    track:Play(config.transitionTime, config.weight, config.speed)

    self.current = track
end

function AnimationHandler._refreshAnimationTracks(self: AnimationHandler)
    for pose, config in pairs(self.configs) do
        local animation = getAnimationFrom(config.id)

        if self.animationTracks[pose] then
            self.animationTracks[pose]:Destroy()
        end

        self.animationTracks[pose] = self.animator:LoadAnimation(animation)

        animation:Destroy()
    end
end

----------------------

return AnimationHandler