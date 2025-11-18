extends CharacterBody2D

# 移动速度
const SPEED = 200.0
# 跳跃速度（达到100像素高度）
# 由于每帧都应用重力，实际高度会略小于理论值，所以需要稍微增加速度
# 理论值：v = sqrt(2 * GRAVITY * height) = sqrt(2 * 980 * 100) ≈ 442.7
# 实际值需要略大以确保达到100像素：约-450
const JUMP_VELOCITY = -450.0
# 重力
const GRAVITY = 980.0
# 传送距离
const TELEPORT_DISTANCE = 100.0
const MAX_HEALTH = 100
const STUCK_DEATH_DELAY = 2.0

# 传送冷却（防止连续传送）
var teleport_cooldown: float = 0.0
const TELEPORT_COOLDOWN_TIME = 1.0
# 传送动画时长
const TELEPORT_ANIMATION_TIME = 0.15
# 是否正在传送动画中
var is_teleporting: bool = false
# 角色血量
var health: int = MAX_HEALTH
var respawn_position: Vector2 = Vector2.ZERO
var stuck_timer: float = STUCK_DEATH_DELAY
var is_stuck_in_terrain: bool = false
# Sprite2D节点引用
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	respawn_position = global_position
	reset_stuck_state()

func _physics_process(delta: float) -> void:
	# 更新传送冷却
	if teleport_cooldown > 0.0:
		teleport_cooldown -= delta
	
	# 应用重力
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# 处理传送（优先级最高）
	if handle_teleport():
		# 如果传送成功，跳过其他输入处理
		move_and_slide()
		monitor_stuck_state(delta)
		return
	
	# 处理跳跃输入
	handle_jump_input()
	
	# 处理左右移动
	handle_horizontal_movement()
	
	# 移动角色
	move_and_slide()
	monitor_stuck_state(delta)

func handle_jump_input() -> void:
	# 检测是否按下跳跃键（W键）
	if Input.is_action_just_pressed("jump"):
		# 如果在地面上，执行跳跃
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

func handle_teleport() -> bool:
	# 检查是否在冷却中或正在动画中
	if teleport_cooldown > 0.0 or is_teleporting:
		return false
	
	# 检查是否按下空格键
	if not Input.is_action_pressed("teleport"):
		return false
	
	# 直接检测WASD物理按键
	var horizontal = 0.0
	var vertical = 0.0
	
	# 检测左右方向（A和D键）
	if Input.is_key_pressed(KEY_A):
		horizontal -= 1.0
	if Input.is_key_pressed(KEY_D):
		horizontal += 1.0
	
	# 检测上下方向（W和S键）
	if Input.is_key_pressed(KEY_W):
		vertical -= 1.0  # 向上是负值
	if Input.is_key_pressed(KEY_S):
		vertical += 1.0  # 向下是正值
	
	# 检查是否有方向键被按下
	if horizontal == 0.0 and vertical == 0.0:
		return false
	
	# 计算传送方向（归一化）
	var direction = Vector2(horizontal, vertical).normalized()
	
	# 计算目标位置
	var target_position = global_position + direction * TELEPORT_DISTANCE
	
	# 执行传送动画（异步，不阻塞）
	play_teleport_animation(target_position)
	
	# 设置冷却时间
	teleport_cooldown = TELEPORT_COOLDOWN_TIME
	
	return true

func play_teleport_animation(target_pos: Vector2) -> void:
	is_teleporting = true
	
	# 创建Tween用于淡出动画
	var fade_out_tween = create_tween()
	fade_out_tween.set_parallel(true)
	fade_out_tween.tween_property(sprite, "modulate:a", 0.0, TELEPORT_ANIMATION_TIME / 2)
	fade_out_tween.tween_property(sprite, "scale", Vector2(0.8, 0.8), TELEPORT_ANIMATION_TIME / 2)
	
	# 淡出完成后传送（使用回调）
	fade_out_tween.tween_callback(func():
		global_position = target_pos
		velocity = Vector2.ZERO
		
		# 创建Tween用于淡入动画
		var fade_in_tween = create_tween()
		fade_in_tween.set_parallel(true)
		fade_in_tween.tween_property(sprite, "modulate:a", 1.0, TELEPORT_ANIMATION_TIME / 2)
		fade_in_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), TELEPORT_ANIMATION_TIME / 2)
		
		# 动画完成后重置状态
		fade_in_tween.tween_callback(func():
			is_teleporting = false
		).set_delay(TELEPORT_ANIMATION_TIME / 2)
	).set_delay(TELEPORT_ANIMATION_TIME / 2)

func handle_horizontal_movement() -> void:
	# 获取输入方向
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func monitor_stuck_state(delta: float) -> void:
	if is_teleporting:
		return
	
	if is_inside_solid():
		if not is_stuck_in_terrain:
			is_stuck_in_terrain = true
			stuck_timer = STUCK_DEATH_DELAY
		else:
			stuck_timer -= delta
			if stuck_timer <= 0.0:
				apply_lethal_damage()
	else:
		reset_stuck_state()

func is_inside_solid() -> bool:
	return test_move(global_transform, Vector2.ZERO)

func reset_stuck_state() -> void:
	is_stuck_in_terrain = false
	stuck_timer = STUCK_DEATH_DELAY

func apply_lethal_damage() -> void:
	take_damage(health)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		die_and_respawn()

func die_and_respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	teleport_cooldown = 0.0
	is_teleporting = false
	sprite.modulate.a = 1.0
	sprite.scale = Vector2.ONE
	reset_stuck_state()
	health = MAX_HEALTH
