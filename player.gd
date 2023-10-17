extends Area2D
signal HPChanged(health, delta) ## When HP changes, report total HP and the change
signal died(killing_entity) ## when hp hits 0, report what enemy we are touching
signal collectedItem(item)

@export var speed = 400 ## How fast the player will move (px/s)
@export var maxhealth = 3 ## How many hits the player can take, 
@export var onhitdamage = 1 ## How much damage we take on hit
var screen_size ## Size of the game window
var health = maxhealth

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	HPChanged.emit(maxhealth, 0) ## Delta is 0 to indicate new game
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
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

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
		
