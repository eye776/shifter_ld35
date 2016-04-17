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

const TwoPi = 6.28319
const MaxMouseSpeed = 8.5
const MouseTurnSpeed = 0.2

onready var vp = get_viewport_rect()
onready var screen_size = OS.get_screen_size(0)
onready var window_size = OS.get_window_size()
onready var blob = get_node("Blob")

var blobPosition = Vector2()
var wanderOrientation = 0.0
var wanderDirection = Vector2()

var allowStartGame = false

func _ready():
	OS.set_window_position(screen_size / 2 - window_size / 2)
	set_process(true)
	set_process_input(true)
	randomize()
	blobPosition = Vector2(3 * vp.size.width / 4, vp.size.height / 2)
	blob.set_pos(blobPosition)
	blob.reset()
	get_node("AnimationPlayer").play("fadeTitle")

func wrap_angle(radians):
	while (radians < -PI):
		radians += TwoPi
	while (radians > PI):
		radians -= TwoPi
	return radians

func turn_to_face(position, faceThis, currentAngle, turnSpeed):
	var x = faceThis.x - position.x
	var y = faceThis.y - position.y
	var desiredAngle = atan2(y, x)
	var difference = wrap_angle(desiredAngle - currentAngle)
	difference = clamp(difference, -turnSpeed, turnSpeed)
	return wrap_angle(currentAngle + difference)

func wander(position, turnSpeed):
	wanderDirection.x += lerp(-0.25, 0.25, randf())
	wanderDirection.y += lerp(-0.25, 0.25, randf())
	if (wanderDirection != Vector2()):
		wanderDirection = wanderDirection.normalized()
	var targetPosition = position + wanderDirection
	wanderOrientation = turn_to_face(position, targetPosition, wanderOrientation, 0.15 * turnSpeed)
	var screenCenter = Vector2(vp.size.width / 2, vp.size.height / 2)
	var distanceFromScreenCenter = screenCenter.distance_to(position)
	var maxDistanceFromScreenCenter = min(screenCenter.y, screenCenter.x)
	var normalizedDistance = distanceFromScreenCenter / maxDistanceFromScreenCenter
	var turnToCenterSpeed = 0.3 * normalizedDistance * normalizedDistance * turnSpeed
	wanderOrientation = turn_to_face(position, screenCenter, wanderOrientation, turnToCenterSpeed)

func update_mouse():
	wander(blobPosition, MouseTurnSpeed)
	var currentMouseSpeed = 0.25 * MaxMouseSpeed
	var heading = Vector2(cos(wanderOrientation), sin(wanderOrientation));
	blobPosition += heading * currentMouseSpeed

func clamp_to_viewport(vector):
	vector.x = clamp(vector.x, vp.pos.x, vp.pos.x + vp.size.width)
	vector.y = clamp(vector.y, vp.pos.y, vp.pos.y + vp.size.height)
	return vector

func _process(delta):
	update_mouse()
	blobPosition = clamp_to_viewport(blobPosition)
	blob.set_pos(blobPosition)

func allowStart():
	allowStartGame = true

func _input(event):
	if(event.type == InputEvent.MOUSE_BUTTON):
		if(event.is_pressed() && allowStartGame):
			get_node("SamplePlayer").play("Blip_Select")
			Fader.fade_to_scene("res://Game.scn")


func _on_Timer_timeout():
	blob.shape = (blob.shape + 1) % 4
