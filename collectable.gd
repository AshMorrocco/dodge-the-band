extends Area2D

var heart_img = preload("res://art/Heart.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = heart_img
	self.set_meta("item_name", "heart")

