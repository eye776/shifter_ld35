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

extends Sprite

var destroyed = false
var laser_spawn_time = 5
var last_t = OS.get_unix_time()
var has_shield
var shield_count = 3
var should_fire = false
onready var shield = self.get_node("Shield")

func _ready():
	has_shield = (int(rand_range(0, 1) * 10) % 2) == 0
	if(has_shield):
		shield.show()
	set_process(true)

func _process(delta):
	if should_fire == false:
		var now_t = OS.get_unix_time()
		if now_t - last_t >= laser_spawn_time:
			should_fire = true
			last_t = OS.get_unix_time()

func damage():
	shield_count -= 1
	if(has_shield and shield_count > 0):
		if(shield_count == 2):
			shield.set_modulate(Color(1, 1, 0))
		elif(shield_count == 1):
			shield.set_modulate(Color(1, 0, 0))
		return
	destroyed = true

func is_destroyed():
	return destroyed
