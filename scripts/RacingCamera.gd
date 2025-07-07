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
var shake_timer: float = 0.0
var base_position: Vector3
var chariot: ChariotController
var smoothed_forward: Vector3

func _ready():
	current = true
	
	# Get reference to chariot controller
	chariot = get_parent().get_parent() as ChariotController
	if not chariot:
		print("Warning: RacingCamera cannot find ChariotController!")
	else:
		print("RacingCamera initialized with chariot: ", chariot.name)
		smoothed_forward = -chariot.global_transform.basis.z

func _process(delta):
	if not chariot or not chariot.chariot_body:
		return
	
	update_simple_camera(delta)
	apply_camera_shake(delta)

func update_simple_camera(delta):
	var chariot_body = chariot.chariot_body
	var chariot_position = chariot_body.global_position
	
	# Smooth the forward direction based on velocity
	var chariot_velocity = chariot_body.linear_velocity
	if chariot_velocity.length_squared() > 1.0:
		var target_forward = chariot_velocity.normalized()
		smoothed_forward = smoothed_forward.slerp(target_forward, rotation_smoothing * delta)

	# Calculate camera position behind the chariot using the smoothed forward direction
	var target_position = chariot_position - (smoothed_forward * follow_distance) + Vector3(0, follow_height, 0)
	
	# Smooth camera movement
	global_position = global_position.lerp(target_position, position_smoothing * delta)
	
	# Look at the chariot's position but with our smoothed rotation
	look_at(chariot_position, Vector3.UP)
	
	base_position = global_position

func apply_camera_shake(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Generate random shake offset
		var shake_offset = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		# Apply shake to position
		global_position = base_position + shake_offset
		
		# Decay shake intensity
		shake_intensity = max(0, shake_intensity - shake_decay * delta)
	else:
		shake_intensity = 0.0

func add_shake(intensity: float, duration: float):
	shake_intensity = max(shake_intensity, intensity)
	shake_timer = max(shake_timer, duration)

func get_current_speed() -> float:
	if chariot and chariot.has_method("get_current_speed"):
		return chariot.get_current_speed()
	return 0.0
