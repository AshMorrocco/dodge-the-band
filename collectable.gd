extends Area2D

var heart_img = preload("res://art/Heart.png")
var g_heart_img = preload("res://art/Heart_green.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	var collectable_options = [heart_img, g_heart_img]
	$Sprite2D.texture = collectable_options[randi_range(0, collectable_options.size() - 1)]
	self.set_meta("item_name", "heart")

