extends Camera3D
class_name RacingCamera

# Camera positioning settings
@export var follow_distance: float = 12.0
@export var follow_height: float = 6.0
@export var side_offset: float = 0.0

# Camera responsiveness
@export var position_smoothing: float = 8.0
@export var rotation_smoothing: float = 6.0

# Predictive tracking
@export var velocity_prediction_strength: float = 2.0
@export var steering_prediction_strength: float = 3.0
@export var max_prediction_distance: float = 8.0

# Camera shake
@export var shake_intensity: float = 0.0
@export var shake_decay: float = 5.0

# Internal variables
var shake_timer: float = 0.0
var base_position: Vector3
var chariot: ChariotController
var last_valid_direction: Vector3 = Vector3.FORWARD

func _ready():
	current = true
	
	# Get reference to chariot controller
	chariot = get_parent().get_parent() as ChariotController
	if not chariot:
		print("Warning: RacingCamera cannot find ChariotController!")
	else:
		print("RacingCamera initialized with chariot: ", chariot.name)

func _process(delta):
	if not chariot or not chariot.chariot_body:
		return
	
	update_predictive_camera(delta)
	apply_camera_shake(delta)

func update_predictive_camera(delta):
	var chariot_body = chariot.chariot_body
	var chariot_position = chariot_body.global_position
	var chariot_velocity = chariot_body.linear_velocity
	
	# Calculate velocity-based direction prediction
	var velocity_direction = Vector3.ZERO
	if chariot_velocity.length() > 1.0:  # Only use velocity if moving significantly
		velocity_direction = chariot_velocity.normalized()
		last_valid_direction = velocity_direction
	else:
		# Use last known direction when stationary
		velocity_direction = last_valid_direction
	
	# Add steering prediction
	var steering_input = chariot.steering_input if chariot.has_method("get_steering_input") else 0.0
	var steering_prediction = Vector3(steering_input * steering_prediction_strength, 0, 0)
	
	# Combine predictions
	var total_prediction = (velocity_direction * velocity_prediction_strength + steering_prediction)
	total_prediction = total_prediction.limit_length(max_prediction_distance)
	
	# Calculate target look-at point
	var look_target = chariot_position + total_prediction
	
	# Calculate camera position behind and above the chariot
	var camera_offset = Vector3(side_offset, follow_height, follow_distance)
	
	# Rotate offset based on predicted direction
	if velocity_direction.length() > 0.1:
		var rotation_basis = Basis.looking_at(-velocity_direction, Vector3.UP)
		camera_offset = rotation_basis * camera_offset
	
	var target_position = chariot_position + camera_offset
	
	# Smooth camera movement
	global_position = global_position.lerp(target_position, position_smoothing * delta)
	
	# Smooth camera rotation to look at predicted target
	var current_transform = global_transform
	var target_transform = current_transform.looking_at(look_target, Vector3.UP)
	global_transform = current_transform.interpolate_with(target_transform, rotation_smoothing * delta)
	
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
