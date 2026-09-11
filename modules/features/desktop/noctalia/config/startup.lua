local noctalia = @NOCTALIA@

hl.layer_rule({ name = "noctalia", match = { namespace = "noctalia-background-.*" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({
	name = "noctalia-shell-region",
	match = { namespace = "noctalia-shell:regionSelector" },
	no_anim = true,
})
hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm app -- " .. noctalia)
end)
