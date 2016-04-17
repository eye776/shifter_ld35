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

const blob_width = 22

export var trailNodeCount = 10

var outline_trail = []
var fill_trail = []
var trail_pos = []
var trail_pos_pre = []
var trail_vel = []

export var TrailStiffness = 30000.0
export var TrailDamping = 60.0

export var start_scale = 1.0
export var end_scale = 0.3
export var lerp_exp = 0.5
export var trail_mass = 11.2
export var fill_color = Color(1, 1, 1)
export var outline_color = Color(0, 0, 0)
export var outline_size = 10.0

const NONE = 0
const LINE = 1
const BOOMERANG = 2
const SHIELD = 3

export var shape = 0 setget set_shape, get_shape

func set_shape(value):
	shape = value
	if trail_pos_pre.size() >= trailNodeCount:
		for i in range(1, trailNodeCount):
			trail_pos_pre[i] = trail_pos[i] - trail_pos[0]
	dt = 0

func get_shape():
	return shape

func _ready():
	self.set_fixed_process(true)

	var outline_sprite = self.get_node("Outline/OutlineSprite0")
	outline_trail.append(outline_sprite)
	trail_pos.append(Vector2(0, 0))
	trail_vel.append(Vector2(0, 0))
	trail_pos_pre.append(Vector2(0, 0))
	for i in range(1, trailNodeCount):
		var new_sprite = outline_sprite.duplicate()
		new_sprite.set_name(str("OutlineSprite", i))
		new_sprite.set_modulate(outline_color)
		self.get_node("Outline").add_child(new_sprite)
		new_sprite.set_owner(self)
		outline_trail.append(new_sprite)
		trail_pos.append(Vector2(0, 0))
		trail_pos_pre.append(Vector2(0, 0))
		trail_vel.append(Vector2(0, 0))
	
	var fill_sprite = get_node("Fill/FillSprite0")
	fill_trail.append(fill_sprite)
	for i in range(1, trailNodeCount):
		var new_sprite = fill_sprite.duplicate()
		new_sprite.set_name(str("FillSprite", i))
		new_sprite.set_modulate(fill_color)
		self.get_node("Fill").add_child(new_sprite)
		new_sprite.set_owner(self)
		fill_trail.append(new_sprite)

var dt = 0

func update_trail(delta):
	dt += delta
	if dt > 1: dt = 1
	var direction=1
	var dist = 0
	for i in range(1, trailNodeCount):
		if shape == NONE:
			var stretch = trail_pos[i] - trail_pos[i-1]
			var force = -TrailStiffness * stretch - TrailDamping * trail_vel[i]
			# Apply acceleration
			var acceleration = force / trail_mass
			trail_vel[i] += acceleration * delta
			# Apply velocity
			trail_pos[i] += trail_vel[i] * delta
			self.set_rot(deg2rad(0))
		elif shape == LINE:
			dist += 1
			trail_pos[i].x = trail_pos[0].x + lerp(trail_pos_pre[i].x, (dist * direction), dt)
			dist += 1
			trail_pos[i].y = trail_pos[0].y + lerp(trail_pos_pre[i].y, (dist * direction), dt)
			direction *= -1
			self.set_rot(deg2rad(-45))
		elif shape == BOOMERANG:
			dist += 2
			if i % 2 == 0:
				trail_pos[i].x = trail_pos[0].x + lerp(trail_pos_pre[i].x, (dist * direction), dt)
				trail_pos[i].y = trail_pos[0].y + lerp(trail_pos_pre[i].y, 0, dt)
			else:
				trail_pos[i].x = trail_pos[0].x + lerp(trail_pos_pre[i].x, 0, dt)
				trail_pos[i].y = trail_pos[0].y + lerp(trail_pos_pre[i].y, (dist * direction), dt)
			direction *= -1
			self.set_rot(deg2rad(-45))
		elif shape == SHIELD:
			var angle = 0.129 * i
			trail_pos[i].x = trail_pos[0].x + lerp(trail_pos_pre[i].x, (24 + 24) * sin(angle), dt)
			trail_pos[i].y = trail_pos[0].y + lerp(trail_pos_pre[i].y, (24 + 24) * cos(angle), dt)
			self.set_rot(deg2rad(30))

func reset():
	for i in range(trailNodeCount):
		trail_pos[i] = self.get_pos()

func _fixed_process(delta):
	trail_pos[0] = self.get_pos()
	update_trail(delta)
	var borderstart_scale = start_scale + outline_size / blob_width
	var borderend_scale = end_scale + outline_size / blob_width
	for i in range(trailNodeCount):
		var lerpFactor = float(i) / float(trailNodeCount - 1)
		lerpFactor = pow(lerpFactor, lerp_exp)
		var scale = lerp(borderstart_scale, borderend_scale, lerpFactor)
		outline_trail[i].set_rot(outline_trail[i].get_rot() + PI/8 * i+1 * delta)
		outline_trail[i].set_pos(trail_pos[i] - self.get_pos())
		outline_trail[i].set_scale(Vector2(scale, scale))
		outline_trail[i].set_modulate(outline_color)
		scale = lerp(start_scale, end_scale, lerpFactor)
		fill_trail[i].set_rot(fill_trail[i].get_rot() + PI/8 * i+1 * delta)
		fill_trail[i].set_pos(trail_pos[i] - self.get_pos())
		fill_trail[i].set_scale(Vector2(scale, scale))
		fill_trail[i].set_modulate(fill_color)
