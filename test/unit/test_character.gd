extends GutTest

var Player = load("res://scenes/game/player.gd")
var _player = null

func before_each():
	_player = Player.new()
	_player.health = 3
	_player.maximum_health = 4

func after_each():
	_player.free()

func test_take_lethal_damage():
	# We need to be able to take damage
	_player.health = 3
	var result = _player.take_lethal_damage(-1)
	assert_eq(result, 2, "Health Should be 2" )
	
	# Lethal damage should let health hit zero
	result = _player.take_lethal_damage(-2)
	assert_eq(result, 0, "Health Should be 0" )

func test_take_nonlethal_damage():
	# We need to be able to take damage
	_player.health = 3
	var result = _player.take_nonlethal_damage(-1)
	assert_eq(result, 2, "Health Should be 2" )
	
	# Non lethal damage should leave player at 1 health
	result = _player.take_nonlethal_damage(-2)
	assert_eq(result, 1, "Health Should be 1" )

func test_recover_health():
	# We need to be able to heal
	_player.health = 3
	var result = _player.recover_health(1)
	assert_eq(result, 4, "Health should be 4")
	
	# But we shouldn't heal beyond maximum health
	_player.maximum_health = 4
	result = _player.recover_health(1)
	assert_eq(result, 4, "Health should be 4")

var TestLethalPickup:Pickup = preload("res://test/unit/testResources/test_lethal_pu.tres")
var TestNonLethalPickup:Pickup =preload("res://test/unit/testResources/test_nonlethal_pu.tres")
var TestHealingPickup:Pickup = preload("res://test/unit/testResources/test_healing_pu.tres")
var TestCollectable:Pickup = preload("res://test/unit/testResources/test_collectable.tres")

func test_process_pickup():
	_player.health = 2
	# Make sure collectables can change health
	_player.process_pickup(TestCollectable)
	assert_eq(_player.health, 3, "Health Should be 3" )
	
	# We need to be able to heal
	_player.process_pickup(TestHealingPickup)
	assert_eq(_player.health, 4, "Health Should be 4" )
	
	_player.process_pickup(TestNonLethalPickup)
	assert_eq(_player.health, 1, "Health Should be 1" )
	
	watch_signals(_player)
	_player.process_pickup(TestLethalPickup)
	assert_eq(_player.health, 0, "Health Should be 0" )
	assert_eq(_player.cause_of_death, "Black Heart")
	assert_signal_emitted(_player, "HPChanged", "Should emit a health changed signal")

#var TestEnemy:Enemy = preload("res://test/unit/testResources/test_enemy.tres")
#
#func test_process_enemy_attack():
	#_player.process_enemy_attack(TestEnemy)
	#assert_eq(_player.health, 2, "Health Should be 2" )
