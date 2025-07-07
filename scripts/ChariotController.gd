extends Node3D
class_name ChariotController

# Racing mechanics variables
@export var max_force: float = 200.0
@export var acceleration_force: float = 240.0
@export var turn_force_differential: float = 140.0
@export var air_control_strength: float = 0.3

# Boost mechanics
@export var boost_multiplier: float = 1.8
@export var max_boost_energy: float = 100.0
@export var boost_consumption_rate: float = 50.0
@export var boost_recharge_rate: float = 25.0

# Durability system
@export var max_durability: float = 100.0
@export var damage_force_penalty: float = 0.5

# Physics tuning
@export var creature_force_smoothing: float = 5.0
@export var steering_responsiveness: float = 1.5

# Drift compensation
@export var drift_compensation_strength: float = 50.0
@export var force_balance_smoothing: float = 10.0

# Current state variables
var current_speed: float = 0.0
var boost_energy: float = 100.0
var durability: float = 100.0
var is_boosting: bool = false
var is_airborne: bool = false

# Input variables
var throttle_input: float = 0.0
var steering_input: float = 0.0
var raw_steering_input: float = 0.0
var steering_smoothing: float = 12.0
var boost_input: bool = false

# Force application variables
var left_creature_force: float = 0.0
var right_creature_force: float = 0.0
var target_left_force: float = 0.0
var target_right_force: float = 0.0

# Drift compensation tracking
var accumulated_drift: float = 0.0
var drift_compensation: float = 0.0

# References
@onready var chariot_body: RigidBody3D = $ChariotBody
@onready var left_creature: RigidBody3D = $LeftCreature
@onready var right_creature: RigidBody3D = $RightCreature
@onready var ground_check: RayCast3D = $ChariotBody/GroundCheck
@onready var camera_target: Node3D = $CameraTarget

# Signals for UI updates
signal speed_changed(new_speed: float)
signal boost_energy_changed(new_energy: float)
signal durability_changed(new_durability: float)

func _ready():
	# Initialize boost energy and durability to max
	boost_energy = max_boost_energy
	durability = max_durability
	
	# Emit initial values
	emit_signal("speed_changed", current_speed)
	emit_signal("boost_energy_changed", boost_energy)
	emit_signal("durability_changed", durability)
	
	# Set up physics properties
	setup_physics_properties()

func setup_physics_properties():
	# Configure chariot physics
	if chariot_body:
		chariot_body.mass = 5.0
		chariot_body.gravity_scale = 1.0
		chariot_body.angular_damp = 5.0
		
	# Configure creature physics
	if left_creature:
		left_creature.mass = 2.0
		left_creature.gravity_scale = 1.0
		
	if right_creature:
		right_creature.mass = 2.0
		right_creature.gravity_scale = 1.0

func _physics_process(delta):
	handle_input()
	smooth_steering_input(delta)
	update_boost_system(delta)
	calculate_target_forces()
	apply_drift_compensation(delta)
	apply_straightening_force(delta)
	smooth_force_application(delta)
	apply_creature_forces()
	update_camera_target(delta)
	update_speed_tracking()
	check_ground_status()
	
	# Emit speed updates for UI
	emit_signal("speed_changed", current_speed)

func handle_input():
	# Get input from action map
	throttle_input = 0.0
	if Input.is_action_pressed("accelerate"):
		throttle_input = 1.0
	elif Input.is_action_pressed("decelerate"):
		throttle_input = -0.5  # Reduced reverse force
	
	# Get raw steering input and smooth it
	raw_steering_input = Input.get_axis("steer_left", "steer_right")
	boost_input = Input.is_action_pressed("boost")

func smooth_steering_input(delta):
	# Smoothly interpolate steering input to reduce sharp responses
	steering_input = move_toward(steering_input, raw_steering_input, steering_smoothing * delta)

func update_boost_system(delta):
	if boost_input and boost_energy > 0 and not is_boosting:
		is_boosting = true
	elif not boost_input or boost_energy <= 0:
		is_boosting = false
	
	# Consume or recharge boost energy
	if is_boosting:
		boost_energy -= boost_consumption_rate * delta
		boost_energy = max(0, boost_energy)
	else:
		boost_energy += boost_recharge_rate * delta
		boost_energy = min(max_boost_energy, boost_energy)
	
	# Emit boost energy updates
	emit_signal("boost_energy_changed", boost_energy)

func calculate_target_forces():
	# Base force from throttle input
	var base_force = acceleration_force * throttle_input
	
	# Apply boost multiplier
	if is_boosting:
		base_force *= boost_multiplier
	
	# Apply durability penalty
	var durability_factor = durability / max_durability
	base_force *= (1.0 - damage_force_penalty * (1.0 - durability_factor))
	
	# Calculate steering differential
	var steering_differential = steering_input * turn_force_differential * steering_responsiveness
	
	# Apply air control reduction when airborne
	if is_airborne:
		steering_differential *= air_control_strength
	
	# Set target forces for each creature with drift compensation
	target_left_force = base_force - steering_differential + drift_compensation
	target_right_force = base_force + steering_differential - drift_compensation
	
	# Clamp forces to reasonable limits
	target_left_force = clamp(target_left_force, -max_force * 0.5, max_force)
	target_right_force = clamp(target_right_force, -max_force * 0.5, max_force)

func smooth_force_application(delta):
	# Smoothly interpolate current forces toward target forces
	left_creature_force = move_toward(left_creature_force, target_left_force, creature_force_smoothing * max_force * delta)
	right_creature_force = move_toward(right_creature_force, target_right_force, creature_force_smoothing * max_force * delta)

func apply_creature_forces():
	if not left_creature or not right_creature:
		return
	
	# Apply steering rotation to creatures first
	apply_creature_steering()
	
	# Get forward direction for each creature
	var left_forward = -left_creature.global_transform.basis.z
	var right_forward = -right_creature.global_transform.basis.z
	
	# Apply forces to creatures
	if left_creature_force != 0:
		left_creature.apply_central_force(left_forward * left_creature_force)
	
	if right_creature_force != 0:
		right_creature.apply_central_force(right_forward * right_creature_force)

func apply_drift_compensation(delta):
	if not chariot_body or not left_creature or not right_creature:
		return
	
	# Calculate drift by comparing chariot velocity direction with creature orientations
	var chariot_velocity = chariot_body.linear_velocity
	if chariot_velocity.length() > 2.0:  # Only compensate when moving
		var velocity_direction = chariot_velocity.normalized()
		var left_forward = -left_creature.global_transform.basis.z
		var right_forward = -right_creature.global_transform.basis.z
		var average_creature_forward = (left_forward + right_forward).normalized()
		
		# Calculate drift as cross product (sideways movement)
		var drift_vector = velocity_direction.cross(average_creature_forward)
		accumulated_drift += drift_vector.y * delta
		
		# Calculate compensation force
		var target_compensation = -accumulated_drift * drift_compensation_strength
		drift_compensation = move_toward(drift_compensation, target_compensation, force_balance_smoothing * delta)
		
		# Decay accumulated drift over time
		accumulated_drift *= 0.85

func apply_creature_steering():
	if not left_creature or not right_creature:
		return
	
	# Only apply steering when there's actual input (increased dead zone to prevent drift)
	if abs(steering_input) > 0.02:  # Very small dead zone for precision
		# Calculate steering angle based on input (reversed direction)
		var steering_angle = -steering_input * 0.25  # Moderate response
		var turn_torque = steering_angle * 6.0  # Reduced torque for less wild turning
		
		# Apply same rotational impulse to both creatures
		left_creature.apply_torque_impulse(Vector3(0, turn_torque, 0))
		right_creature.apply_torque_impulse(Vector3(0, turn_torque, 0))

func update_speed_tracking():
	# Calculate current speed based on chariot velocity
	if chariot_body:
		var velocity_2d = Vector2(chariot_body.linear_velocity.x, chariot_body.linear_velocity.z)
		current_speed = velocity_2d.length()

func update_camera_target(delta):
	# Direct camera positioning - no smoothing for instant response
	if camera_target and chariot_body and left_creature and right_creature:
		# Position follows chariot directly with slight smoothing for stability
		var target_position = chariot_body.global_position
		camera_target.global_position = camera_target.global_position.lerp(target_position, 8.0 * delta)
		
		# Calculate average creature direction for immediate camera orientation
		var left_forward = -left_creature.global_transform.basis.z
		var right_forward = -right_creature.global_transform.basis.z
		var average_forward = (left_forward + right_forward).normalized()
		
		# Set camera target to look in the average forward direction immediately
		if average_forward.length() > 0.1:  # Avoid zero vector issues
			camera_target.look_at(camera_target.global_position + average_forward, Vector3.UP)

func check_ground_status():
	if ground_check:
		is_airborne = not ground_check.is_colliding()

func apply_straightening_force(delta):
	if abs(raw_steering_input) < 0.1 and chariot_body.linear_velocity.length() > 1.0:
		var current_angular_velocity = chariot_body.angular_velocity
		var damping_factor = 10.0 # Increased damping for stronger straightening
		chariot_body.angular_velocity = current_angular_velocity.lerp(Vector3.ZERO, damping_factor * delta)

func take_damage(damage_amount: float):
	durability -= damage_amount
	durability = max(0, durability)
	emit_signal("durability_changed", durability)

func repair_damage(repair_amount: float):
	durability += repair_amount
	durability = min(max_durability, durability)
	emit_signal("durability_changed", durability)

func get_speed_percentage() -> float:
	# Convert force-based speed to percentage (approximate)
	var max_theoretical_speed = 30.0  # Estimated max speed with current forces
	return min(current_speed / max_theoretical_speed, 1.0)

func get_boost_percentage() -> float:
	return boost_energy / max_boost_energy

func get_durability_percentage() -> float:
	return durability / max_durability

func get_current_speed() -> float:
	return current_speed

# Get chariot position for external systems
func get_chariot_position() -> Vector3:
	if chariot_body:
		return chariot_body.global_position
	return global_position

# Get chariot transform for camera systems
func get_chariot_transform() -> Transform3D:
	if chariot_body:
		return chariot_body.global_transform
	return global_transform

# Called when colliding with obstacles or track boundaries
func _on_body_entered(body):
	if body.has_method("get_damage_amount"):
		var damage = body.get_damage_amount()
		take_damage(damage)
