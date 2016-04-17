#The MIT License (MIT) 
#Copyright (c) 2016

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is furnished
#to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
#DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
#OR OTHER DEALINGS IN THE SOFTWARE.

extends Node2D

onready var vp = get_viewport_rect()

var bullet = preload("res://bullet.scn")
var bullet_count = 0
var bullet_array = []
var bullet_speed = 300

var enemy = preload("res://enemy.scn")
var enemy_count = 0
var enemy_array = []
var enemy_spawn_time = 3
var last_t = OS.get_unix_time()

var laser = preload("res://laser.scn")
var laserCount = 0
var laser_array = []

var barrier = preload("res://barrier.scn")
var barrier_instance = null
var barrier_spawn_time = 10
var last_barrier_t = OS.get_unix_time()

onready var camera = get_node("Camera2D")
onready var player = get_node("Blob")
var player_speed = 100
var pressed_fire = false
var pressed_shift = false
var gun_per_sec = 83

onready var sfx = get_node("sfx") 
onready var root = get_node("root")
var hp = 100.0
var gun = 100.0
var gameover = false
var offscreen = 200
var score = 0

var shield_sound = 0
var hit_sound = 0

onready var ship_mode = get_node("Camera2D/ShipMode")
const player_mode = ["Shooter", "Charger", "Power", "Shield"]

onready var go_label = get_node("Camera2D/Label")
onready var go_btn = get_node("Camera2D/Button")

func _ready():
	self.set_process(true)
	camera.make_current()
	player.reset()

func _process(delta):
	if gameover:
		return

	var player_pos = player.get_pos()

	if player.shape == player.BOOMERANG:
		gun += 2 * gun_per_sec * delta
	else:
		gun += gun_per_sec * delta
	if gun > 100: gun = 100
	get_node("Camera2D/GunBar").set_value(gun)

	if Input.is_action_pressed("ui_select"):
		if pressed_fire == false and gun >= 100:
			fire()
		pressed_fire = true
	else:
		pressed_fire = false

	if Input.is_action_pressed("ui_cancel"):
		if pressed_shift == false:
			player.shape = (player.shape + 1) % 4
			ship_mode.set_text(str("MODE:", player_mode[player.shape]))
		pressed_shift = true
	else:
		pressed_shift = false

	if Input.is_action_pressed("ui_up"):
		player_pos.y -= player_speed * 2 * delta

	if Input.is_action_pressed("ui_down"):
		player_pos.y += player_speed * 2 * delta

	player_pos.x += player_speed * delta
	player.set_pos(player_pos)
	var camera_pos = Vector2(player_pos.x + vp.size.width * 0.45, 240)
	camera.set_pos(camera_pos)

	if player.shape == player.LINE:
		hp += 5 * delta
		get_node("Camera2D/ProgressBar").set_value(hp)

	var bullet_id = 0
	for bullet in bullet_array:
		var bullet_pos = bullet.get_pos()
		bullet_pos.x += bullet_speed * delta
		bullet.set_pos(bullet_pos)
		if bullet_pos.x > player_pos.x + vp.size.width:
			root.remove_child(bullet)
			bullet_array.remove(bullet_id)
		bullet_id += 1

	var laser_id = 0
	for laser in laser_array:
		var laser_pos = laser.get_pos()
		laser_pos.x -= bullet_speed * delta
		laser.set_pos(laser_pos)
		if laser_pos.distance_squared_to(player_pos) < 400:
			if player.shape != player.SHIELD:
				sfx.play("hit")
				damage_player()
			else:
				sfx.play("shield")
			root.remove_child(laser)
			laser_array.remove(laser_id)
		if laser_pos.x < player_pos.x - offscreen:
			root.remove_child(laser)
			laser_array.remove(laser_id)
		laser_id += 1

	var now_t = OS.get_unix_time()
	if  now_t - last_t >= enemy_spawn_time:
		spawn_enemy()
		last_t = OS.get_unix_time()

	now_t = OS.get_unix_time()
	if  now_t - last_barrier_t >= barrier_spawn_time:
		if barrier_instance == null:
			spawn_barrier()
		last_barrier_t = OS.get_unix_time()

	if barrier_instance != null:
		var barrier_pos = barrier_instance.get_pos()
		barrier_pos.x -= bullet_speed * delta
		barrier_instance.set_pos(barrier_pos)
		var bx = barrier_pos.x
		var px = player_pos.x
		if bx < px + 20 and bx > px - 20:
			if player.shape != player.SHIELD:
				if(sfx.is_voice_active(hit_sound) == false):
					hit_sound = sfx.play("hit")
					damage_player(1.25)
			elif(sfx.is_voice_active(shield_sound) == false):
				shield_sound = sfx.play("shield")
		if barrier_pos.x < player_pos.x - offscreen:
			root.remove_child(barrier_instance)
			barrier_instance = null

	var enemy_id = 0
	for enemy in enemy_array:
		var enemy_pos = enemy.get_pos()

		bullet_id = 0
		for bullet in bullet_array:
			var bullet_pos = bullet.get_pos()
			if enemy_pos.distance_squared_to(bullet_pos) < 400:
				enemy.damage()
				sfx.play("hit")
				root.remove_child(bullet)
				bullet_array.remove(bullet_id)
			bullet_id += 1

		if enemy.should_fire:
			fire_laser(enemy)
			enemy.should_fire = false

		if enemy_pos.x < player_pos.x - offscreen or enemy.is_destroyed() == true:
			if(enemy.is_destroyed() == true):
				sfx.play("destroy")
				score += 10
				get_node("Camera2D/score").set_text(str("SCORE:",score))
			root.remove_child(enemy)
			enemy_array.remove(enemy_id)
		enemy_id += 1

		if enemy_pos.x < player_pos.x + 320:
			if enemy_pos.distance_squared_to(player_pos) < 400:
				if(player.shape != player.SHIELD):
					if(sfx.is_voice_active(hit_sound) == false):
						hit_sound = sfx.play("hit")
						damage_player()
				elif(sfx.is_voice_active(shield_sound) == false):
					shield_sound = sfx.play("shield")
					enemy.damage()
					sfx.play("hit")

func fire():
	if player.shape == player.NONE or player.shape == player.BOOMERANG:
		var new_bullet = bullet.instance()
		new_bullet.set_name(str("bullet", bullet_count))
		root.add_child(new_bullet)
		new_bullet.set_owner(self)
		var bullet_pos = player.get_pos()
		new_bullet.set_pos(bullet_pos)
		bullet_array.push_back(new_bullet)
		bullet_count += 1
		gun = 0
		sfx.play("bullet")

func spawn_enemy():
	var new_enemy = enemy.instance()
	new_enemy.set_name(str("enemy", enemy_count))
	root.add_child(new_enemy)
	new_enemy.set_owner(self)
	var enemy_pos = Vector2(rand_range(720, 850), rand_range(50, 420))
	enemy_pos.x += player.get_pos().x
	new_enemy.set_pos(enemy_pos)
	enemy_array.push_back(new_enemy)
	enemy_count += 1

func fire_laser(enemy):
	var new_laser = laser.instance()
	new_laser.set_name(str("laser", laserCount))
	root.add_child(new_laser)
	new_laser.set_owner(self)
	var laser_pos = enemy.get_pos()
	new_laser.set_pos(laser_pos)
	laser_array.push_back(new_laser)
	laserCount += 1
	sfx.play("laser")

func damage_player(delta = 1):
	hp -= 15 * delta
	get_node("Camera2D/ProgressBar").set_value(hp)
	if(hp <= 0):
		sfx.play("destroy")
		gameover = true
		go_btn.show()
		go_label.show()

func spawn_barrier():
	barrier_instance = barrier.instance()
	barrier_instance.set_name("barrier")
	root.add_child(barrier_instance)
	barrier_instance.set_owner(self)
	var barrier_pos = Vector2(rand_range(720, 850), 0)
	barrier_pos.x += player.get_pos().x
	barrier_instance.set_pos(barrier_pos)

func reset_game():
	for enemy in enemy_array:
		root.remove_child(enemy)
	for laser in laser_array:
		root.remove_child(laser)
	for bullet in bullet_array:
		root.remove_child(bullet)
	root.remove_child(barrier_instance)
	barrier_instance = null
	enemy_array.clear()
	laser_array.clear()
	bullet_array.clear()
	score = 0
	hp = 100
	player.set_pos(Vector2(52, 232))
	player.reset()
	last_t = OS.get_unix_time()
	last_barrier_t = OS.get_unix_time()
	get_node("Camera2D/score").set_text(str("SCORE:",score))
	get_node("Camera2D/ProgressBar").set_value(hp)
	go_label.hide()
	go_btn.hide()
	gameover = false

func _on_Button_pressed():
	reset_game()
