extends CanvasLayer

signal start_game

# Called when the node enters the scene tree for the first time.
func _ready():
	$DamageOverlay.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()

func show_game_over(who_landed_killing_blow):
	$DamageOverlay.show()
	$OverlayTimer.stop()
	show_message("You were killed by "+str(who_landed_killing_blow))
	# Wait for message timer to count down
	await $MessageTimer.timeout
	
	$DamageOverlay.hide()
	$Message.text = "Watch out for Wallace and the Band!"
	$Message.show()
	$StartButton.show()

func update_score(score):
	$ScoreLabel.text = str(score)

func update_HP(health, delta):
	set_HP(health)
	if delta < 0:
		pass
		#$DamageOverlay.show()
		#$OverlayTimer.start()
	if (abs(delta) > 1):
		pass
	
func set_HP(value):
	for i in $HPContainer.get_child_count():
		$HPContainer.get_child(i).visible = value > i

func pause_game(paused):
	$Message.text = "Paused!"
	if paused:
		$Message.show()
		$DamageOverlay.show()
	else:
		$Message.hide()
		$DamageOverlay.hide()

func picked_up_collectable(item):
	$CollectableLabel.text = item
	
func _on_message_timer_timeout():
	$Message.hide()


func _on_start_button_pressed():
	$StartButton.hide()
	start_game.emit()


func _on_overlay_timer_timeout():
	$DamageOverlay.hide()
