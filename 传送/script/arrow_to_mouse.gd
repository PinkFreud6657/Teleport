extends Node2D

@export var player_path: NodePath
@export var line_color: Color = Color(1, 0.85, 0.2, 0.95)
@export var line_width: float = 3.0
@export var head_length: float = 18.0
@export var head_width: float = 12.0

var _tail: Vector2 = Vector2.ZERO
var _tip: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	var player := get_node_or_null(player_path)
	if player == null:
		# 尝试自动寻找名为 Player 的节点
		var candidate := get_tree().get_current_scene().get_node_or_null("Player")
		if candidate:
			player_path = candidate.get_path()
			player = candidate

	if player and player is Node2D:
		_tail = (player as Node2D).global_position
		_tip = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	# 将全局坐标转换为本地进行绘制
	var tail_local := to_local(_tail)
	var tip_local := to_local(_tip)

	# 绘制主线
	draw_line(tail_local, tip_local, line_color, line_width, true)

	# 计算箭头三角形（指向 tip）
	var dir := (tip_local - tail_local)
	var len := dir.length()
	if len < 1.0:
		return
	var n := dir / len
	var side := Vector2(-n.y, n.x)

	var p0 := tip_local                           # 尖端
	var p1 := tip_local - n * head_length + side * (head_width * 0.5)
	var p2 := tip_local - n * head_length - side * (head_width * 0.5)

	draw_polygon(PackedVector2Array([p0, p1, p2]), PackedColorArray([line_color]))


