extends Node

@export var enemyScene:PackedScene
@export var pickupScene:PackedScene
var paused = false

var _all_enemies:Array[Enemy]
var inactive_enemy_types:Array[Enemy]
var active_enemy_types:Array[Enemy]
var _all_pickups:Array[Pickup]
var possible_pickups:Array[Pickup]
var coinsCollected:int = 0
var hatsCollected:int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
#	Nab all our possible enemies
	for file in DirAccess.get_files_at("res://data/enemies/"):
		file = file.replace(".remap", "")
		var resource_file = "res://data/enemies/" + file
		var enemy:Enemy = load(resource_file) as Enemy
		_all_enemies.append(enemy)
#	Nab all our possible items
	for file in DirAccess.get_files_at("res://data/pickups/"):
		file = file.replace(".remap", "")
		var resource_file = "res://data/pickups/" + file
		var pickup:Pickup = load(resource_file) as Pickup
		_all_pickups.append(pickup)

func initialize_enemy_array():
	# We just want wallace to spawn at the start of the game
	# TODO: dynamically point to wallace 
	inactive_enemy_types = _all_enemies.duplicate(true)
	active_enemy_types.clear()
	active_enemy_types.append(inactive_enemy_types[4])
	inactive_enemy_types.remove_at(4)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("toggle_pause"):
		pause_button_pressed()

func pause_button_pressed():
	paused = !paused
	get_tree().paused = paused
	$HUD.pause_game(paused)
	$StartTimer.paused = paused
	$MobTimer.paused = paused
	$PickupTimer.paused = paused

func new_game():
	initialize_enemy_array()
	get_tree().call_group("collectable", "queue_free")
	get_tree().call_group("mobs", "queue_free")
	hatsCollected = 0
	coinsCollected = 0
	$Player.start($StartPosition.position)
	$Music.play()
	$StartTimer.start()
	$HUD.show_message("Get ready...")

func game_over(who_landed_killing_blow):
	$Music.stop()
	$DeathSound.play()
	$MobTimer.stop()
	$PickupTimer.stop()
	$HUD.show_game_over(who_landed_killing_blow)

func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene
	var mob_to_spawn = active_enemy_types.pick_random()
	var enemy_scene = enemyScene.instantiate()
	
	enemy_scene.get_node("AnimatedSprite2D").play(mob_to_spawn.type)
	enemy_scene.set_meta("mob_type", mob_to_spawn)
	
	# Choose a random location on Path2d
	var mob_spawn_location = get_node("Path2D/PathFollow2D")
	mob_spawn_location.progress_ratio = randf()
	
	# Dont spawn mob within 100 px of player, for fairness
	var dist = mob_spawn_location.position.distance_to(get_node("Player").position)
	if dist < 100:
		return

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Set the mob's position to a random location.
	enemy_scene.position = mob_spawn_location.position

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	enemy_scene.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	enemy_scene.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(enemy_scene)


func _on_start_timer_timeout():
	paused = false
	$HUD.pause_game(paused)
	$MobTimer.start()
	$PickupTimer.start()


func _on_collectable_timer_timeout():
	var pickup_to_spawn = _all_pickups.pick_random()
	var pickup_scene = pickupScene.instantiate()
	pickup_scene.set_meta("pickup_type", pickup_to_spawn)
	pickup_scene.get_node("PickupSprite").set_texture(pickup_to_spawn.sprite)
	pickup_scene.position.x = randi_range( 10, 1270)
	pickup_scene.position.y = randi_range(10, 710)
	
	# Dont spawn pickup within 100 px of player
	var dist = pickup_scene.position.distance_to(get_node("Player").position)
	if dist < 100:
		return
		
	add_child(pickup_scene)


func _on_player_hp_changed(health, delta):
	$HUD.set_HP(health)
	if delta < 0:
		$HUD.show_damage_overlay()
		$DamageSound.play()

# TODO: move effects to an array of effects as property on pickup
func _on_player_collected_item(_pickup:Pickup):
	if(_pickup.type == "coin"):
		coinsCollected += 1
		$HUD.set_collectable_label("Coins: ", coinsCollected)
		if coinsCollected % 5 == 0 and inactive_enemy_types.size() > 0:
			var new_enemy_type_unlocked = inactive_enemy_types.pop_back()
			active_enemy_types.append(new_enemy_type_unlocked)
			$HUD.show_message(new_enemy_type_unlocked.type + " Unlocked!!!")
	if(_pickup.type == "hat"):
		hatsCollected += 1
		$HUD.set_collectable_label("Hats: ", hatsCollected)
	return _pickup

func _on_player_score_changed(score:int, _scoreDelta:int):
	$HUD.update_score(score)

