extends Label

@onready var player: CharacterBody2D = get_node("../../Player")

func _ready() -> void:
	# 设置锚点：顶部居中
	anchor_left = 0.5
	anchor_top = 0.0
	anchor_right = 0.5
	anchor_bottom = 0.0
	offset_left = -100.0
	offset_top = 20.0
	offset_right = 100.0
	offset_bottom = 60.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_END

func _process(_delta: float) -> void:
	if not player:
		text = "未找到玩家"
		return
	
	# 直接访问冷却时间变量
	if player.teleport_cooldown > 0.0:
		# 显示冷却时间，保留1位小数
		text = "传送冷却: %.1f" % player.teleport_cooldown
		visible = true
	else:
		# 冷却完成，显示"就绪"
		text = "传送就绪"
		visible = true

