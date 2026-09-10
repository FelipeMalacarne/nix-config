local mod = "SUPER"
local noctalia = "@NOCTALIA@"
local brightnessctl = "@BRIGHTNESSCTL@"
local grimblast = "@GRIMBLAST@"
local hyprctl = "@HYPRCTL@"
local playerctl = "@PLAYERCTL@"
local wpctl = "@WPCTL@"
local yazi = "@YAZI@"
local btop = "@BTOP@"
local bash = "@BASH@"
local fastfetch = "@FASTFETCH@"
local firefox = "@FIREFOX@"
local term_here = "@TERM_HERE@"

local function bind(keys, action, opts)
	hl.bind(keys, action, opts)
end
local function key(suffix)
	return mod .. " + " .. suffix
end
local function exec(command)
	return hl.dsp.exec_cmd(command)
end

hl.env("GDK_SCALE", "1")
hl.env("LC_CTYPE", "pt_BR.UTF-8")
hl.env("XCOMPOSEFILE", "$HOME/.XCompose")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "22")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "intl",
		follow_mouse = 1,
		touchpad = { natural_scroll = false },
		kb_options = "caps:shiftlock",
		repeat_rate = 40,
		repeat_delay = 600,
	},
})

bind(key("RETURN"), exec(term_here))
bind(key("W"), hl.dsp.window.close())
bind(key("Q"), hl.dsp.window.kill())
bind(key("F"), hl.dsp.window.fullscreen())
bind(key("T"), hl.dsp.window.float({ action = "toggle" }))
bind(key("E"), hl.dsp.layout("togglesplit"))
bind(key("P"), hl.dsp.window.pseudo())
bind(key("SHIFT + P"), hl.dsp.window.pin())
bind(key("SHIFT + R"), exec(hyprctl .. " reload"))
bind(key("SHIFT + Q"), hl.dsp.exit())
bind(key("SPACE"), exec(noctalia .. " ipc call launcher toggle"))
bind(key("PERIOD"), exec(noctalia .. " ipc call controlCenter toggle"))
bind(key("COMMA"), exec(noctalia .. " ipc call settings toggle"))
bind(key("DELETE"), exec(noctalia .. " ipc call sessionMenu toggle"))
-- bind(key("CONTROL + L"), exec(noctalia .. " ipc call lockScreen lock"))
bind(key("S"), hl.dsp.workspace.toggle_special("scratch"))
bind(key("SHIFT + S"), hl.dsp.window.move({ workspace = "special:scratch" }))
bind("PRINT", exec(grimblast .. " copy output"))
bind("SHIFT + PRINT", exec(grimblast .. " copy area"))
bind(key("PRINT"), exec(grimblast .. " save area"))
for _, pair in ipairs({ { "H", "l" }, { "L", "r" }, { "K", "u" }, { "J", "d" } }) do
	bind(key(pair[1]), hl.dsp.focus({ direction = pair[2] }))
	bind(key("SHIFT + " .. pair[1]), hl.dsp.window.swap({ direction = pair[2] }))
	bind(key("CONTROL + " .. pair[1]), hl.dsp.window.move({ direction = pair[2] }))
end
bind(key("TAB"), hl.dsp.focus({ workspace = "previous" }))
bind(key("BRACKETRIGHT"), hl.dsp.focus({ workspace = "e+1" }))
bind(key("BRACKETLEFT"), hl.dsp.focus({ workspace = "e-1" }))
bind(key("SHIFT + PERIOD"), exec(hyprctl .. " dispatch movewindow mon:+1"))
bind(key("SHIFT + F"), exec("uwsm app -- $TERMINAL -e " .. yazi))
bind(key("SHIFT + T"), exec("uwsm app -- $TERMINAL -e " .. btop))
bind(
	key("SHIFT + I"),
	exec("uwsm app -- $TERMINAL -e " .. bash .. " -c '" .. fastfetch .. '; read -rp \\"Press enter to close...\\"\'')
)
bind(key("SHIFT + B"), exec("uwsm app -- " .. firefox))
for i = 1, 9 do
	bind(key(tostring(i)), hl.dsp.focus({ workspace = i }))
	bind(key("SHIFT + " .. i), hl.dsp.window.move({ workspace = i }))
end
for _, pair in ipairs({ { "H", "-80 0" }, { "L", "80 0" }, { "K", "0 -80" }, { "J", "0 80" } }) do
	bind(key("ALT + " .. pair[1]), exec(hyprctl .. " dispatch resizeactive " .. pair[2]), { repeating = true })
end
bind(key("mouse:272"), hl.dsp.window.drag(), { mouse = true })
bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })
bind("XF86AudioRaiseVolume", exec(noctalia .. " ipc call volume increase"), { repeating = true })
bind("XF86AudioLowerVolume", exec(noctalia .. " ipc call volume decrease"), { repeating = true })
bind("XF86MonBrightnessUp", exec(brightnessctl .. " set +5%"), { repeating = true })
bind("XF86MonBrightnessDown", exec(brightnessctl .. " set 5%-"), { repeating = true })
bind("XF86AudioMute", exec(noctalia .. " ipc call volume muteOutput"), { locked = true })
bind("XF86AudioMicMute", exec(wpctl .. " set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
bind("XF86AudioPlay", exec(playerctl .. " play-pause"), { locked = true })
bind("XF86AudioNext", exec(playerctl .. " next"), { locked = true })
bind("XF86AudioPrev", exec(playerctl .. " previous"), { locked = true })

hl.config({
	animations = { enabled = true },
	general = { gaps_in = 5, gaps_out = 10, border_size = 2, layout = "dwindle" },
	decoration = {
		rounding = 20,
		rounding_power = 2,
		shadow = { enabled = true, range = 4, render_power = 3 },
		blur = { enabled = true, size = 3, passes = 2, vibrancy = 0.1696 },
	},
	misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
	dwindle = { preserve_split = true },
})
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
hl.layer_rule({ name = "noctalia", match = { namespace = "noctalia-background-.*" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({
	name = "noctalia-shell-region",
	match = { namespace = "noctalia-shell:regionSelector" },
	no_anim = true,
})
hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm app -- " .. noctalia)
end)
