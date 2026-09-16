extends Node
## Poses the site at the mixer call, presses GO for real and watches the pour
## beat's idle hint for a few seconds of wall time, printing what the beat's
## own rule sees. A thirty-second stand-in for the eight-minute smoke when the
## pour's hint is the only question.
##
##   BC_DEBUG=1 godot --headless --path . res://scenes/dev/pour_probe.tscn

var main: SiteMain


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	# A probe decides the OS's reduce-motion for itself, or the picture it
	# measures is decided by the machine it runs on (6.4).
	Settings.motion_override = -1
	await get_tree().process_frame
	# The stage names the mixer's call by its verb (the fifth session renumbered
	# every step).
	Engine.set_meta("shot_args", {"stage": "rebar"})
	SaveGame.enabled = false
	var packed: PackedScene = load("res://scenes/site.tscn")
	main = packed.instantiate() as SiteMain
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var runner := main.runner
	var hud := main.hud
	print("POUR_PROBE posed: step %d finished %s waiting %s" % [runner.index, str(runner.finished), runner.waiting_button()])
	hud.simulate_button("call")
	var frames := 0
	while frames < 9000 and not (runner.current_step() != null and runner.current_step().verb == "pour_chute"):
		# The mixer stops in the road and waits to be backed in (1.8): hold it.
		if runner.current_step() != null and runner.current_step().verb == "back_mixer" and not runner.held:
			runner.hold(true)
		frames += 1
		await get_tree().process_frame
	runner.hold(false)
	print("POUR_PROBE on the pour after %d frames; rig moving %s" % [frames, str(main.rig.is_moving())])
	var pointer := main.get_node_or_null("Pointer") as SpotRings
	for i in range(10):
		await get_tree().create_timer(0.5).timeout
		print("POUR_PROBE t+%.1fs pointer lit %s count %d held_arrow %s busy %s held %s pads %s/%s/%s/%s stick %s fill %.3f"
			% [0.5 * float(i + 1), str(pointer != null and pointer.lit()), pointer.count() if pointer != null else -1,
				str(runner._held_arrow), str(runner.is_busy()), str(runner.held),
				str(main.pad_held("up")), str(main.pad_held("down")), str(main.pad_held("left")), str(main.pad_held("right")),
				str(Pad.move()), main.drive.fill_fraction()])
	print("POUR_PROBE done")
	get_tree().quit(0)
