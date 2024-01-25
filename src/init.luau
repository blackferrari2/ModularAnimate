local Main = require(script.Main)
local Config = require(script.Config)
local PoseController = require(script.PoseController)

---------------

export type ModularAnimate = Main.ModularAnimate
export type Config = Config.Config
export type Pose = PoseController.Pose

---------------

return {
    Main = Main,
    Config = Config,
    Poses = PoseController.Poses,
}