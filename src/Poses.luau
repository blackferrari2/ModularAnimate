local Poses = {
    Them = {
        Idle = "Idle",
        Walk = "Walk",
        Jump = "Jump",
        Fall = "Fall",
        Sit = "Sit",
        Climb = "Climb",
    },
}

----------------------

export type Pose = "Idle" | "Walk" | "Jump" | "Fall" | "Sit" | "Climb"

----------------------

return Poses