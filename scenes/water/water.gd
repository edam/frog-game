extends ColorRect

const POINT_STEP = 8
const SURFACE_DROP = 64
const SURFACE_THICK = 64
const SPRING_K = 0.9 # spring k
const SPRING_S = 100 # spring strength
const SPRING_R = 5   # spring radius (3 = 5 point ave)
const SPRING_C = 0.8 # velocity damping
const RIPPLE_R = 64  # splash radius
const RIPPLE_FU = 5  # ripple force up
const RIPPLE_FD = 10 # ripple force down


var _collision_body = null
var _point_ys = [] # point y-positions
var _point_vs = [] # point y-velocities

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:

	var num_points = floor(self.size.x / POINT_STEP) + 1

	# init points
	for i in range(num_points):
		_point_ys.append(0.0) #randf() * 20.0 - 10)
		_point_vs.append(0.0)

	# move collision box to mirror parent
	%CollisionShape2D.position = Vector2(floor(self.size.x / 2), SURFACE_DROP)
	%CollisionShape2D.shape = RectangleShape2D.new()
	%CollisionShape2D.shape.size = Vector2(self.size.x, SURFACE_THICK)

	# make transparent
	self.color = Color(0, 0, 0, 0)


func _exit_tree() -> void:
	_collision_body = null


func _physics_process(delta: float) -> void:

	# apply collision to forces
	if _collision_body:
		var body_pos = _collision_body.position - self.position
		for i in range(_point_ys.size()):
			var p = Vector2(min(self.size.x, i * POINT_STEP), SURFACE_DROP + _point_ys[i])
			var f = max(0, RIPPLE_R - p.distance_to(body_pos)) / RIPPLE_R
			var d = (_collision_body.velocity * f * delta).y
			_point_vs[i] += d * (RIPPLE_FU if d < 0 else RIPPLE_FD)
	#self.color = Color(1 if _collision_body else 0, 0, 0, .5 if _collision_body else 0)

	# update velcities
	for i in range(_point_ys.size()):

		# calculate weighted average force
		var f = 0.0
		for j in range(i - SPRING_R + 1, i + SPRING_R):
			if j >= 0 && j < _point_ys.size():
				var weight = 1 - abs(j - i) / (SPRING_R + 1)
				f += -SPRING_K * _point_ys[j] * weight
		f += SPRING_R * -SPRING_K * _point_ys[i] # help midpoint
		_point_vs[i] += (SPRING_S * f / (2 * SPRING_R) - SPRING_C * _point_vs[i]) * delta
		#if i == 10:
			#var s = "|"
			#for j in range(i - SPRING_R + 1, i + SPRING_R):
				#s += str(j) + ":" + str(_point_ys[j]) + "|"
			#print(_point_ys[i], " ", _point_vs[i], " ", f, " ", s)

	# apply velocities and generate line
	for i in range(_point_ys.size()):
		_point_ys[i] += _point_vs[i] * delta

	var points = []
	var x
	for i in range(_point_ys.size()):
		x = min(i * POINT_STEP, self.size.x)
		points.append(Vector2(x, min(SURFACE_DROP + _point_ys[i], self.size.y)))
	%Line2D.points = points
	points.append(Vector2(x, self.size.y))
	points.append(Vector2(0, self.size.y))
	%Polygon2D.polygon = points


func _on_area_2d_body_entered(body: Node2D) -> void:
	_collision_body = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if _collision_body == body:
		_collision_body = null
