extends Node2D

# 预加载玩家场景
var player_scene = preload("res://play.tscn")

func _ready():
	# 实例化玩家
	var player_instance = player_scene.instantiate()
	add_child(player_instance)
	player_instance.position = Vector2(500, 300)
	
	# 添加一个简单的2D精灵
	var sprite = Sprite2D.new()
	# 确保图片路径正确，建议使用PNG格式
	var texture = load("res://image/character.jpg")
	if texture:
		sprite.texture = texture
	else:
		printerr("无法加载角色图片！请检查路径")
	add_child(sprite)
	sprite.position = Vector2(500, 300)  # 将精灵放在玩家位置
