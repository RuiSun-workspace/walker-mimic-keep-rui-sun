extends SceneTree
## Regression test for Rui's playtest 2026-10-29: scarecrows attacking the wall could not be shot.
## They stopped level with the archer, outside the upward fire cone. One PASS/FAIL line per check,
## exits 1 on any failure.
##   ./scripts/run-test.sh test_wall_targeting.gd 60

const MIN_REACH := 60.0                 # px either side of the archer; 530 gives ~73

var failures := 0
var passes := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passes += 1
		print("PASS  ", name)
	else:
		failures += 1
		print("FAIL  ", name, "  ", detail)


func _run() -> void:
	var game := (load("res://game/main.tscn") as PackedScene).instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	await process_frame
	var archer := game.archer
	var reach := (archer.global_position.y - Tuning.SCARECROW_STOP_Y) * tan(deg_to_rad(Tuning.FIRE_CONE_DEG / 2.0))

	_check("the wall stop line is above the archer", Tuning.SCARECROW_STOP_Y < archer.global_position.y,
		"stop_y=%.0f archer_y=%.0f" % [Tuning.SCARECROW_STOP_Y, archer.global_position.y])
	_check("a scarecrow at the wall is in the cone at least %.0f px either side" % MIN_REACH, reach >= MIN_REACH,
		"reach=%.1f px" % reach)

	# Targeting at the wall, both sides; the cone still applies beyond the reach.
	for dx in [0.0, -30.0, 30.0, -MIN_REACH, MIN_REACH, reach + 20.0]:
		var s := game.spawn_scarecrow(Vector2(archer.global_position.x + dx, Tuning.SCARECROW_STOP_Y))
		await physics_frame
		var expect := absf(dx) <= MIN_REACH
		_check("a scarecrow at the wall %+.0f px from the archer is %s" % [dx, "targeted" if expect else "ignored"],
			(archer.nearest_target() == s) == expect, "at_wall=%s" % str(s.at_wall))
		s.remove_from_group("enemies")
		s.free()

	# A real auto-fired arrow hits a scarecrow that is already attacking the wall.
	var gate_before := game.gate_hp
	var target := game.spawn_scarecrow(Vector2(archer.global_position.x + MIN_REACH, Tuning.SCARECROW_STOP_Y))
	archer.fire_cooldown = 0.0
	for i in 60:                                           # one second at 60 ticks
		await physics_frame
	_check("an auto-fired arrow hits a scarecrow at the wall", not is_instance_valid(target) or target.hp < Tuning.SCARECROW_HP,
		"hp=%s" % (str(target.hp) if is_instance_valid(target) else "dead"))
	_check("that scarecrow was attacking the gate", game.gate_hp < gate_before, "gate=%.2f" % game.gate_hp)

	print("%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
