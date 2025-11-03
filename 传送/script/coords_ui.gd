extends CanvasLayer

@export var player_path: NodePath

var _label: Label
var _cd_label: Label

func _ready():
	# 确保存在用于显示的 Label
	if has_node("Label"):
		_label = get_node("Label")
	else:
		_label = Label.new()
		_label.name = "Label"
		add_child(_label)

	# 冷却显示标签
	if has_node("CDLabel"):
		_cd_label = get_node("CDLabel")
	else:
		_cd_label = Label.new()
		_cd_label.name = "CDLabel"
		add_child(_cd_label)

	# 布局到左下角
	_label.anchor_left = 0.0
	_label.anchor_right = 0.0
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.position = Vector2(20, 10)
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# 冷却标签位于坐标标签下一行
	_cd_label.anchor_left = 0.0
	_cd_label.anchor_right = 0.0
	_cd_label.anchor_top = 1.0
	_cd_label.anchor_bottom = 1.0
	_cd_label.position = Vector2(20, 28)
	_cd_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# 默认尝试在根下查找名为 Player 的节点
	if player_path == NodePath():
		var candidate := get_tree().get_current_scene().get_node_or_null("Player")
		if candidate:
			player_path = candidate.get_path()

func _process(_delta: float) -> void:
	var player := get_node_or_null(player_path)
	if player and player is Node2D:
		var gp: Vector2 = player.global_position
		_label.text = "%d %d" % [int(gp.x), int(gp.y)]
		# 显示冷却剩余时间（保留1位小数），为0显示 Ready
		var cd_left := 0.0
		if "get_teleport_cooldown_left" in player:
			cd_left = player.get_teleport_cooldown_left()
		elif "_teleport_cd_left" in player:
			cd_left = float(player._teleport_cd_left)
		_cd_label.text = ("CD %.1fs" % cd_left) if cd_left > 0.0 else "CD Ready"
	else:
		_label.text = "--- ---"
		_cd_label.text = "CD --"


