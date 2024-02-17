extends Node

@export var enemyScene:PackedScene
@export var pickupScene:PackedScene
var score
var paused = false

var _all_enemies:Array[Enemy]
var _all_pickups:Array[Pickup]

# Called when the node enters the scene tree for the first time.
func _ready():
	for file in DirAccess.get_files_at("res://data/enemies/"):
		var resource_file = "res://data/enemies/" + file
		var enemy:Enemy = load(resource_file) as Enemy
		_all_enemies.append(enemy)
	for file in DirAccess.get_files_at("res://data/pickups/"):
		var resource_file = "res://data/pickups/" + file
		var pickup:Pickup = load(resource_file) as Pickup
		_all_pickups.append(pickup)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("toggle_pause"):
		paused = !paused
		get_tree().paused = paused
		$HUD.pause_game(paused)
		$StartTimer.paused = paused
		$MobTimer.paused = paused
		$PickupTimer.paused = paused


func new_game():
	get_tree().call_group("collectable", "queue_free")
	get_tree().call_group("mobs", "queue_free")
	score = 0
	$Player.start($StartPosition.position)
	$Music.play()
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get ready...")
	


func game_over(who_landed_killing_blow):
	$Music.stop()
	$DeathSound.play()
	$MobTimer.stop()
	$CollectableTimer.stop()
	$HUD.show_game_over(who_landed_killing_blow)


func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene
	var mob_to_spawn = _all_enemies.pick_random()
	var mob = enemyScene.instantiate()
	
	mob.get_node("AnimatedSprite2D").play(mob_to_spawn.type)
	mob.set_meta("mob_name", mob_to_spawn.type)
	
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
	mob.position = mob_spawn_location.position

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)

func _on_score():
	score += 1
	$HUD.update_score(score)


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
	add_child(pickup_scene)
