extends CharacterBody2D

# 移动速度（单位：像素/秒）
@export var speed: int = 300

func _physics_process(delta: float):
	# 1. 获取输入
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	
	# 2. 处理移动（使用 delta 实现帧率无关移动）
	if input_direction.length() > 0:
		velocity = input_direction.normalized() * speed * delta
	else:
		velocity = Vector2.ZERO
	
	# 3. 执行移动
	move_and_slide()
	
	# 4. 可选：更新精灵方向
	if velocity.x != 0 and has_node("Sprite2D"):
		$Sprite2D.flip_h = velocity.x < 0
