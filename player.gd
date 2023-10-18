extends Area2D

signal HPChanged(health, delta) ## When HP changes, report total HP and the change
signal died(killing_entity) ## when hp hits 0, report what enemy we are touching
signal collectedItem(item) ## looooot
signal tookalife ## When we cause an enemy to vanish

@export var speed = 400 ## How fast the player will move (px/s)
@export var maxhealth = 3 ## How many hits the player can take, 
@export var onhitdamage = 1 ## How much damage we take on hit
var screen_size ## Size of the game window
var health = maxhealth
var aim = Vector2(1.0, 0.0) # Aim right by default

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	HPChanged.emit(maxhealth, 0) ## Delta is 0 to indicate new game
	$Weapon.hide()
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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

## When colliding with an enemy
func _on_body_entered(body): 
	health -= onhitdamage
	HPChanged.emit(health, -onhitdamage)
	if (health <= 0):
		hide() # Player disappears after being hit
		died.emit(body.get_meta("mob_name"))
		# Must be deferred as we can't change physics properties on a physics callback.
		$CollisionShape2D.set_deferred("disabled", true)

func start(pos):
	health = maxhealth
	HPChanged.emit(maxhealth, 0) ## Delta is 0 to indicate new game
	position = pos
	show()
	$CollisionShape2D.disabled = false

func attack():
	$Weapon/WeaponHitbox.disabled = false
	$Weapon.show()
	await get_tree().create_timer(0.5).timeout
	$Weapon.hide()
	$Weapon/WeaponHitbox.disabled = true

func _on_area_entered(area):
	var item_name = area.get_meta("item_name")
	area.queue_free()
	collectedItem.emit(item_name)
	match (item_name):
		"heart":
			if health <= 6:
				health += 1
				HPChanged.emit(health, 1)
		_:
			pass
		


func _on_weapon_body_entered(body):
	tookalife.emit()
	body.queue_free()
