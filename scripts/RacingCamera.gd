extends Camera3D
class_name RacingCamera

# Camera positioning settings
@export var follow_distance: float = 10.0
@export var follow_height: float = 6.0
@export var side_offset: float = 0.0

# Camera responsiveness
@export var position_smoothing: float = 8.0
@export var rotation_smoothing: float = 6.0

# Camera shake
@export var shake_intensity: float = 0.0
@export var shake_decay: float = 5.0

# Internal variables
var chariot: ChariotController

func _ready():
	current = true
	chariot = get_parent().get_parent() as ChariotController
	if not chariot:
		print("Warning: RacingCamera cannot find ChariotController!")
		return
	
	await chariot.ready
	# Set initial position instantly
	global_position = get_ideal_position()
	look_at(get_look_at_target(), Vector3.UP)


func _physics_process(delta):
	if not chariot or not chariot.chariot_body:
		return

	var ideal_position = get_ideal_position()
	var look_target = get_look_at_target()
	
	var new_transform = global_transform.interpolate_with(
		Transform3D(Basis(), ideal_position).looking_at(look_target, Vector3.UP),
		position_smoothing * delta
	)
	global_transform = new_transform

func get_ideal_position() -> Vector3:
	var chariot_body = chariot.chariot_body
	var chariot_position = chariot_body.global_position
	var chariot_forward = -chariot_body.global_transform.basis.z
	
	var velocity = chariot_body.linear_velocity
	var velocity_dir = chariot_forward
	if velocity.length_squared() > 0.1:
		velocity_dir = velocity.normalized()

	# Check if we are moving backwards
	var dot = velocity_dir.dot(chariot_forward)
	if dot < -0.5: # Moving backwards
		return chariot_position + (chariot_forward * follow_distance) + (Vector3.UP * follow_height)
	else: # Moving forwards or stationary
		return chariot_position - (velocity_dir * follow_distance) + (Vector3.UP * follow_height)

func get_look_at_target() -> Vector3:
	return chariot.chariot_body.global_position + Vector3.UP * 1.5

func apply_camera_shake(delta):
	if shake_intensity > 0:
		shake_intensity = lerpf(shake_intensity, 0, shake_decay * delta)
		var shake_offset = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		global_position += shake_offset

func add_shake(intensity: float, duration: float):
	shake_intensity = max(shake_intensity, intensity)
	# Duration is not used in this implementation, shake decays over time
