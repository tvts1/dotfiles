hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("slateEase", {
    type = "bezier",
    points = {
        { 0.25, 1.0 },
        { 0.5, 1.0 },
    },
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "slateEase",
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "slateEase",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "slateEase",
    style = "fade",
})
