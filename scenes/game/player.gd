extends Area2D

signal HPChanged(health:int, delta:int) ## When HP changes, report total HP and the change
signal died(killing_entity:String) ## when hp hits 0, report what enemy we are touching
signal collectedItem(item:Pickup) ## looooot
signal tookalife ## When we cause an enemy to vanish

@export var speed:int = 400 ## How fast the player will move (px/s)
@export var default_health:int = 3 ## How many hits the player can take, 
@export var maximum_health:int = 4 ## How many HP we cap out at 
@export var onhitdamage:int = 1 ## How much damage we take on hit
var screen_size:Vector2 ## Size of the game window
var health:int = default_health
var aim:Vector2 = Vector2(1.0, 0.0) # Aim right by default
var invulnerable:bool = false
var game_over:bool = true
var cause_of_death:String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	HPChanged.emit(default_health, 0) ## Delta is 0 to indicate new game
	$Weapon.hide()
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (!game_over and health <= 0): 
		die()
#	Physics is past here, don't apply if we can't move
	if invulnerable or game_over:
		return
		
	var velocity = Vector2.ZERO # The player's movement vector
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	
	velocity = velocity.normalized()
	
	if velocity.length() > 0:
		aim = velocity ## redirect aim when moving, lock when still
		velocity *= speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$Weapon.z_index = 1
		$AnimatedSprite2D.flip_h = velocity.x < 0
		$Weapon/WeaponSprite.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$Weapon.z_index = -1
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0
	
	$Weapon.position = aim * 80
	if Input.is_action_just_pressed("attack"):
		attack()

func start(pos):
	health = default_health
	HPChanged.emit(default_health, 0) ## Delta is 0 to indicate new game
	position = pos
	$AnimatedSprite2D.animation = "walk"
	invulnerable = false
	game_over=false
	show()
	$CollisionShape2D.disabled = false

func attack():
	$Weapon/WeaponHitbox.disabled = false
	$Weapon.show()
	await get_tree().create_timer(0.5).timeout
	$Weapon.hide()
	$Weapon/WeaponHitbox.disabled = true

func take_lethal_damage(damage_amount:int):
	health += damage_amount
	if(health <= 0):
		health = 0
	HPChanged.emit(health, damage_amount)
	return health

func take_nonlethal_damage(damage_amount:int):
	if(health + damage_amount <= 0):
		health = 1
	else:
		health += damage_amount
	HPChanged.emit(health, damage_amount)
	return health

func recover_health(healing_amount:int):
	if (health + healing_amount >= maximum_health):
		health = maximum_health
	else:
		health += healing_amount
	HPChanged.emit(health, healing_amount)
	return health

func die():
	died.emit(cause_of_death)
	game_over = true
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.animation = "hurt"
	$Weapon.hide()

func process_pickup(_pickup:Pickup):
	if _pickup.is_collectable:
		collectedItem.emit(_pickup)
	
	if _pickup.health_effect > 0:
		recover_health(_pickup.health_effect)
	elif _pickup.health_effect < 0:
		if _pickup.kill == true:
			take_lethal_damage(_pickup.health_effect)
		else:
			take_nonlethal_damage(_pickup.health_effect)
	#If this pickup caused us to di, we should let the rest of the game know what did it
	if (health <= 0):
		cause_of_death = _pickup.type

func process_enemy_attack(_enemy:Enemy):
	invulnerable = true
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.animation = "hurt"
	$Weapon.hide()
	
	take_lethal_damage(_enemy.health_effect)
	
	if (health <= 0):
		cause_of_death = _enemy.type
	else:
		await get_tree().create_timer(0.5).timeout 
		$AnimatedSprite2D.animation = "walk"
		invulnerable = false
		$CollisionShape2D.set_deferred("disabled", false)

func _on_area_entered(area):
	area.queue_free()
#	Handle pickups elsewhere
	if(area.get_meta("pickup_type") is Pickup):
		process_pickup(area.get_meta("pickup_type"))

func _on_body_entered(body): 
	body.queue_free()
	if(body.get_meta("mob_type") is Enemy):
		process_enemy_attack(body.get_meta("mob_type"))

func _on_weapon_body_entered(body):
	tookalife.emit()
	body.queue_free()


