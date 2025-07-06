extends Control
class_name RacingHUD

# UI References
@onready var speed_bar: ProgressBar = $VBoxContainer/SpeedBar
@onready var speed_label: Label = $VBoxContainer/SpeedBar/SpeedLabel
@onready var boost_bar: ProgressBar = $VBoxContainer/BoostBar
@onready var boost_label: Label = $VBoxContainer/BoostBar/BoostLabel
@onready var durability_bar: ProgressBar = $VBoxContainer/DurabilityBar
@onready var durability_label: Label = $VBoxContainer/DurabilityBar/DurabilityLabel
@onready var lap_label: Label = $TopContainer/LapLabel
@onready var position_label: Label = $TopContainer/PositionLabel

# Racing data
var current_lap: int = 1
var total_laps: int = 3
var current_position: int = 1
var total_racers: int = 4

func _ready():
	# Initialize UI elements
	setup_progress_bars()
	update_lap_display()
	update_position_display()

func setup_progress_bars():
	# Speed bar setup
	speed_bar.min_value = 0
	speed_bar.max_value = 100
	speed_bar.value = 0
	
	# Boost bar setup
	boost_bar.min_value = 0
	boost_bar.max_value = 100
	boost_bar.value = 100
	
	# Durability bar setup
	durability_bar.min_value = 0
	durability_bar.max_value = 100
	durability_bar.value = 100

func connect_to_chariot(chariot: ChariotController):
	if chariot:
		print("Connecting HUD to chariot: ", chariot.name)
		chariot.speed_changed.connect(_on_speed_changed)
		chariot.boost_energy_changed.connect(_on_boost_energy_changed)
		chariot.durability_changed.connect(_on_durability_changed)
		print("HUD signals connected successfully")
	else:
		print("Error: No chariot provided to HUD")

func _on_speed_changed(new_speed: float):
	var speed_percentage = (new_speed / 50.0) * 100  # Assuming max speed of 50
	speed_bar.value = speed_percentage
	speed_label.text = "Speed: %d%%" % int(speed_percentage)

func _on_boost_energy_changed(new_energy: float):
	boost_bar.value = new_energy
	boost_label.text = "Boost: %d%%" % int(new_energy)
	
	# Change color based on boost level
	if new_energy > 50:
		boost_bar.modulate = Color.CYAN
	elif new_energy > 25:
		boost_bar.modulate = Color.YELLOW
	else:
		boost_bar.modulate = Color.RED

func _on_durability_changed(new_durability: float):
	durability_bar.value = new_durability
	durability_label.text = "Hull: %d%%" % int(new_durability)
	
	# Change color based on durability
	if new_durability > 70:
		durability_bar.modulate = Color.GREEN
	elif new_durability > 30:
		durability_bar.modulate = Color.YELLOW
	else:
		durability_bar.modulate = Color.RED

func update_lap_display():
	lap_label.text = "Lap: %d/%d" % [current_lap, total_laps]

func update_position_display():
	var position_suffix = "th"
	match current_position:
		1: position_suffix = "st"
		2: position_suffix = "nd"
		3: position_suffix = "rd"
	
	position_label.text = "%d%s / %d" % [current_position, position_suffix, total_racers]

func set_lap(lap: int):
	current_lap = lap
	update_lap_display()

func set_race_position(position: int):
	current_position = position
	update_position_display()

func set_total_laps(laps: int):
	total_laps = laps
	update_lap_display()

func set_total_racers(racers: int):
	total_racers = racers
	update_position_display()
