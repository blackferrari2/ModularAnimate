local packages = script.Parent.Parent

local Signal = require(packages.Signal)
local Config = require(script.Parent.Config)

local PoseController = {
    Poses = {
        None = "None",
        Idle = "Idle",
        Walk = "Walk",
        Jump = "Jump",
        Fall = "Fall",
        Sit = "Sit",
        Climb = "Climb",
    },
}

PoseController.__index = PoseController

----------------------

type self = {
    humanoid: Humanoid,
    current: Pose,
    changed: Signal.Signal<Pose>,
    configsTable: {[Pose]: Config.Config},
    connections: {RBXScriptConnection},
}

export type Pose = "Idle" | "Walk" | "Jump" | "Fall" | "Sit" | "Climb"
export type PoseController = typeof(setmetatable({} :: self, PoseController))

---------------

function PoseController.new(humanoid: Humanoid, configsTable: {[Pose]: Config.Config}): PoseController
    local self = {
        humanoid = humanoid,
        current = PoseController.Poses.Idle,
        changed = Signal.new(),
        configsTable = configsTable,
        connections = {},
    }

    setmetatable(self, PoseController)

    return self
end

function PoseController.change(self: PoseController, to: Pose)
    if self.current == to then
        return
    end

    self.current = to
    self.changed:Fire(to)
end

function PoseController.connect(self: PoseController)
    local initialPose = self.current

    self:change(initialPose)

    self:_addConnection(self.humanoid.Running:Connect(function(speed)
        if speed > 0 then
            return
        end

        self:change(PoseController.Poses.Idle)
    end))

    self:_addConnection(self.humanoid.Running:Connect(function(speed)
        if speed < 1 then
            return
        end

        self:change(PoseController.Poses.Walk)
    end))

    local isJumping = false

    self:_addConnection(self.humanoid.Jumping:Connect(function(active)
        if not active then
            return
        end

        self:change(PoseController.Poses.Jump)
        isJumping = true
    end))

    local jumpConfig = self.configsTable[PoseController.Poses.Jump]

    self:_addConnection(self.humanoid.StateChanged:Connect(function(_, newState)
        if newState ~= Enum.HumanoidStateType.Freefall then
            return
        end

        if isJumping then
            local isCancelled = false
            local connection = self.humanoid.StateChanged:Once(function()
                isCancelled = true
            end)

            task.wait(jumpConfig.duration)

            if isCancelled then
                return
            end

            connection:Disconnect()
        end

        self:change(PoseController.Poses.Fall)
    end))

    self:_addConnection(self.humanoid.StateChanged:Connect(function(_, newState)
        if newState ~= Enum.HumanoidStateType.Landed then
            return
        end

        local rootPart = self.humanoid.RootPart

        if not rootPart then
            return
        end

        isJumping = false
        self:change(PoseController.Poses.Idle)
    end))

    self:_addConnection(self.humanoid.StateChanged:Connect(function(_, newState)
        if newState ~= Enum.HumanoidStateType.Seated then
            return
        end

        self:change(PoseController.Poses.Sit)
    end))

    self:_addConnection(self.humanoid.Climbing:Connect(function(speed)
        self:change(PoseController.Poses.Climb)
    end))
end

function PoseController.disconnect(self: PoseController)
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    self.connections = {}
end

--

function PoseController._addConnection(self: PoseController, connection: RBXScriptConnection)
    table.insert(self.connections, connection)
end

----------------------

return PoseController