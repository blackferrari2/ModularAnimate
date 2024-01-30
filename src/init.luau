local Main = require(script.Main)
local Config = require(script.Config)
local Poses = require(script.Poses)
local Handler = require(script.Handlers.Meta)
local PoseController = require(script.Handlers.PoseController)
local AnimationPlayer = require(script.Handlers.AnimationPlayer)

---------------

export type ModularAnimate = Main.ModularAnimate
export type Config = Config.Config
export type ConfigMap = Config.ConfigMap
export type Pose = Poses.Pose
export type Handler = Handler.Handler
export type PoseController = PoseController.PoseController
export type AnimationPlayer = AnimationPlayer.AnimationPlayer

---------------

return {
    Main = Main,
    Config = Config,
    Poses = Poses,
}