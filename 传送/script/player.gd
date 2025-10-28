extends CharacterBody2D

@export var speed: float = 200.0          # 水平移动速度
@export var jump_force: float = -400.0    # 跳跃初速度（负号向上）
@export var gravity: float = 1000.0       # 重力强度
@export var acceleration: float = 10.0    # 水平加速度平滑度
@export var friction: float = 20.0        # 减速平滑度

func _physics_process(delta):
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = max(velocity.y, 0) # 防止下坠速度残留

	# 读取输入
	var input_dir = Input.get_axis("ui_left", "ui_right")

	# 目标水平速度
	var target_speed = input_dir * speed

	# 平滑加速与减速
	if input_dir != 0:
		velocity.x = lerp(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)

	# 跳跃逻辑
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	# 移动与碰撞
	move_and_slide()
