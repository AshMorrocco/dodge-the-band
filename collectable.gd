extends Area2D

var heart_img = preload("res://art/Heart.png")
var g_heart_img = preload("res://art/Heart_green.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	var collectable_options = {"heart":heart_img, "green_heart":g_heart_img}
	var collectable_names = collectable_options.keys()
	var random_name = collectable_names[randi_range(0, collectable_names.size() - 1)]
	
	$Sprite2D.texture = collectable_options[random_name]
	self.set_meta("item_name", random_name)

