extends Camera3D
class_name RacingCamera

# Camera follow settings (relative to parent chariot)
@export var follow_distance: float = 10.0
@export var follow_height: float = 5.0

# Camera smoothing
@export var position_smoothing: float = 2.0
@export var rotation_smoothing: float = 1.5

# Camera shake
@export var shake_intensity: float = 0.0
@export var shake_decay: float = 5.0

# Look ahead settings
@export var speed_look_ahead_factor: float = 0.1
@export var max_look_ahead: float = 15.0

# Internal variables
var shake_timer: float = 0.0
var base_position: Vector3
var base_rotation: Vector3
var chariot: ChariotController

func _ready():
	# Make this camera current
	current = true
	
	# Get reference to chariot controller (now grandparent since we're child of CameraTarget)
	chariot = get_parent().get_parent() as ChariotController
	if not chariot:
		print("Warning: RacingCamera cannot find ChariotController!")
	else:
		print("RacingCamera initialized with chariot: ", chariot.name)
	
	# Set initial position relative to camera target
	position = Vector3(0, follow_height, follow_distance)
	look_at(Vector3.ZERO, Vector3.UP)

func _process(delta):
	if not chariot:
		return
	
	update_camera_position(delta)
	update_camera_rotation(delta)
	apply_camera_shake(delta)

func update_camera_position(delta):
	if not chariot:
		return
	
	# Get chariot's velocity for look-ahead
	var chariot_velocity = Vector3.ZERO
	if chariot.has_method("get_current_speed"):
		var speed = chariot.get_current_speed()
		chariot_velocity = -chariot.transform.basis.z * speed
	
	# Calculate look-ahead based on velocity
	var velocity_look_ahead = chariot_velocity * speed_look_ahead_factor
	velocity_look_ahead = velocity_look_ahead.limit_length(max_look_ahead)
	
	# Calculate desired camera position (relative to chariot)
	var desired_position = Vector3(0, follow_height, follow_distance)
	desired_position += velocity_look_ahead * 0.1  # Reduced look-ahead for relative positioning
	
	# Smooth camera movement
	base_position = position.lerp(desired_position, position_smoothing * delta)
	position = base_position

func update_camera_rotation(delta):
	if not chariot:
		return
	
	# Look at a point in front of the chariot (in local space)
	var look_target = Vector3(0, 1, -5)  # Look slightly ahead and up
	
	# Smooth camera rotation
	var desired_transform = transform.looking_at(look_target, Vector3.UP)
	transform = transform.interpolate_with(desired_transform, rotation_smoothing * delta)
	
	base_rotation = rotation

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
		position = base_position + shake_offset
		
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
