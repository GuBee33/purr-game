extends RigidBody2D

const MAX_INIT_INDEX: int  = 2
const SCORE_MULTIPLIER:int  = 10
const IMAGE_SCALE_CONST:int = 30
const KABUM_DRUATION: float = 0.6
const KABUM_OPPACITY: float = 0.2
const VIBRATION_DURATION: int = 200
const LASER_WIDTH_SCALE: float = 0.1
const LASER_OPPACITY: float = 0.4

@onready var laser: Sprite2D = $Laser
@onready var merge_sound: AudioStreamPlayer = $merge_sound
@onready var kabum: AnimatedSprite2D = $kabum

var cats_and_balls: AnimatedSprite2D 

var unit_score: int = 0
var current_id:int = 0
var current_type: String 
var laser_visibility:bool=true

func init_variables():
	laser.self_modulate.a=LASER_OPPACITY
	laser.scale=Vector2(1060/laser.texture.get_size().x,LASER_WIDTH_SCALE)

	if Global.animated_sprites_sized_and_collision==null:
		Global.set_animated_sprites_dict(cats_and_balls)
	current_id=(randi_range(0,MAX_INIT_INDEX))
	current_type=["cat","ball","ball"][randi_range(0,2)]


func create_collision_polygon(id,type)->CollisionPolygon2D:
	var texture = Global.animated_sprites_sized_and_collision[type][id].texture
	var scale_factor = Global.animated_sprites_sized_and_collision[type][id].scale
	var merged_polygon = CollisionPolygon2D.new()
	merged_polygon.polygon = Global.animated_sprites_sized_and_collision[type][id].polygon_points
	var offset=texture.get_size()*scale_factor
	merged_polygon.position = cats_and_balls.position - offset/2
	return merged_polygon
	

func set_animation():
	if Global.animated_sprites_sized_and_collision:
		cats_and_balls.play(Global.animated_sprites_sized_and_collision[current_type][current_id].name)

func update_animation_properties():
	unit_score += (current_id + 1) * SCORE_MULTIPLIER
	var scale_factor = Global.animated_sprites_sized_and_collision[current_type][current_id].scale
	cats_and_balls.scale=scale_factor
	var collision_polygon=create_collision_polygon(current_id,current_type)
	call_deferred("add_child",collision_polygon)
	self.mass =float(current_id + 1)
	add_to_group(str(current_id))
	
func play_kabumm():
	cats_and_balls.self_modulate.a=KABUM_OPPACITY
	var kabumm_scale = (current_id+2)*IMAGE_SCALE_CONST/512.0
	kabum.visible=true
	kabum.scale=Vector2(kabumm_scale,kabumm_scale)
	kabum.play("kabum")
	merge_sound.play()
	Input.vibrate_handheld(VIBRATION_DURATION)
	await get_tree().create_timer(KABUM_DRUATION).timeout
	kabum.visible=false
	cats_and_balls.self_modulate.a=1
	
func _process(delta: float) -> void:
	laser.visible=laser_visibility	

func _ready():
	cats_and_balls=Global.selected_sprite.duplicate()
	cats_and_balls.visible=true
	add_child(cats_and_balls)
	init_variables()
	set_animation()
	update_animation_properties()
	Global.score+=unit_score

func _on_Ball_collided(ball):
	if  ball is RigidBody2D and ball.is_in_group(str(current_id)):
		if ball.current_type == "ball" and current_id < Global.animated_sprites_sized_and_collision["cat"].size()-1:
			var new_position = (self.position + ball.position) / 2
			Global.score+=ball.unit_score+self.unit_score
			Global.set_new_highscore()
			ball.queue_free()
			self.position = new_position
			remove_from_group(str(current_id))
			current_id+=1
			play_kabumm()
			set_animation()
			update_animation_properties()
		elif ball.current_type == "cat" and self.current_type == "cat":
			cats_and_balls.play(Global.animated_sprites_sized_and_collision["angry"][current_id].name)

func _on_collision_end(ball):
	if  ball is RigidBody2D and ball.is_in_group(str(current_id)):
		if ball.current_type == "cat" and self.current_type == "cat":
			set_animation()
