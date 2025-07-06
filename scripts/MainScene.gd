extends Node3D

@onready var chariot: ChariotController = $BasicChariot
@onready var hud: RacingHUD = $RacingHUD

func _ready():
	# Connect HUD to chariot
	if chariot and hud:
		print("Main Scene: Connecting HUD to chariot...")
		hud.connect_to_chariot(chariot)
		print("Main Scene: HUD connected successfully!")
	else:
		if not chariot:
			print("Error: Could not find BasicChariot")
		if not hud:
			print("Error: Could not find RacingHUD")
