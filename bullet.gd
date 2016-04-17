
extends Sprite

func _ready():
	self.get_node("AnimationPlayer").get_animation("anim").set_loop(true)
	self.get_node("AnimationPlayer").play("anim")
