extends Area2D

signal HPChanged(health, delta) ## When HP changes, report total HP and the change
signal died(killing_entity) ## when hp hits 0, report what enemy we are touching
signal collectedItem(item) ## looooot
signal tookalife ## When we cause an enemy to vanish

@export var speed = 400 ## How fast the player will move (px/s)
@export var default_health = 3 ## How many hits the player can take, 
@export var maximum_health = 4 ## How many HP we cap out at 
@export var onhitdamage = 1 ## How much damage we take on hit
var screen_size ## Size of the game window
var health = default_health
var aim = Vector2(1.0, 0.0) # Aim right by default
var damage_invuln = false

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	HPChanged.emit(default_health, 0) ## Delta is 0 to indicate new game
	$Weapon.hide()
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if damage_invuln:
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
	damage_invuln = false
	show()
	$CollisionShape2D.disabled = false

func attack():
	$Weapon/WeaponHitbox.disabled = false
	$Weapon.show()
	await get_tree().create_timer(0.5).timeout
	$Weapon.hide()
	$Weapon/WeaponHitbox.disabled = true

func die(cause:String):
	died.emit(cause)
	damage_invuln = true
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.animation = "hurt"
	$Weapon.hide()

func _on_area_entered(area):
#	Everything is a pickup for now
	assert(area.get_meta("pickup_type") is Pickup)
		
	var item_encountered:Pickup = area.get_meta("pickup_type")
	area.queue_free()
	
	if item_encountered.is_collectable:
		collectedItem.emit(item_encountered)
	var health_delta = item_encountered.health_effect
	if health >= maximum_health && health_delta > 0:
		health_delta = 0
		
	if health <= 1 && health_delta < 0:
		if item_encountered.kill == false:
			health_delta = 0 
		
	health += health_delta
	HPChanged.emit(health, health_delta)
	
	if (health <= 0):
		die(item_encountered.type)


## When colliding with an enemy
func _on_body_entered(body): 
	health -= onhitdamage
	HPChanged.emit(health, -onhitdamage)
	damage_invuln = true
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.animation = "hurt"
	$Weapon.hide()
	if (health <= 0):
		die(body.get_meta("mob_name"))
	else:
		body.queue_free()
		await get_tree().create_timer(0.5).timeout 
		$AnimatedSprite2D.animation = "walk"
		damage_invuln = false
		$CollisionShape2D.set_deferred("disabled", false)

func _on_weapon_body_entered(body):
	tookalife.emit()
	body.queue_free()
