extends SceneTree
var p: GPUParticles2D
var finished_at := -1
var frame := 0
var emitters: Array[GPUParticles2D] = []
var t_on := 0.0
var t_off := 0.0
func _init():
	print("adapter: '", RenderingServer.get_video_adapter_name(), "' driver: ", OS.get_environment("GODOT_DRIVER"), " display: ", DisplayServer.get_name())
	p = GPUParticles2D.new()
	p.amount = 20; p.lifetime = 0.3; p.one_shot = true; p.explosiveness = 1.0
	p.process_material = ParticleProcessMaterial.new()
	p.finished.connect(func(): finished_at = frame)
	root.add_child.call_deferred(p)
	var c := Curve.new()
	print("Curve max_value default=", c.max_value)
func _process(delta: float) -> bool:
	frame += 1
	if frame == 2:
		p.emitting = true
	if frame == 40:
		print("one_shot lifetime 0.3 s at 60 fps: emitting=", p.emitting, " finished fired at frame ", finished_at, " capture_rect=", p.capture_rect())
		for i in 50:
			var e := GPUParticles2D.new()
			e.amount = 200; e.lifetime = 1.0; e.process_material = ParticleProcessMaterial.new(); e.emitting = true
			root.add_child(e); emitters.append(e)
	if frame > 60 and frame <= 360:
		t_on += Performance.get_monitor(Performance.TIME_PROCESS)
	if frame == 361:
		for e in emitters: e.queue_free()
	if frame > 380 and frame <= 680:
		t_off += Performance.get_monitor(Performance.TIME_PROCESS)
	if frame == 681:
		print("mean process time, 50 emitters x 200 GPU particles: %.4f ms; none: %.4f ms" % [t_on / 300.0 * 1000.0, t_off / 300.0 * 1000.0])
		return true
	return false
