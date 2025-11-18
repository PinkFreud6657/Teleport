extends TileMapLayer

@export var pattern: TileMapPattern
@export var scatter_origin: Vector2i = Vector2i(0, -41)
@export var scatter_size: Vector2i = Vector2i(200, 241)
@export var scatter_attempts: int = 2000
@export var clear_before_scatter: bool = false

var _rng := RandomNumberGenerator.new()

func randomize_tiles_with_pattern() -> void:
	if scatter_attempts <= 0:
		return
	
	if pattern == null:
		push_warning("未设置图案资源")
		return
	
	if clear_before_scatter:
		clear()
	
	var pattern_size := pattern.get_size()
	var padded_size := scatter_size - pattern_size
	if padded_size.x <= 0 or padded_size.y <= 0:
		push_warning("散布区域太小，无法容纳图案")
		return
	
	_rng.randomize()
	for i in range(scatter_attempts):
		var x := _rng.randi_range(scatter_origin.x, scatter_origin.x + padded_size.x)
		var y := _rng.randi_range(scatter_origin.y, scatter_origin.y + padded_size.y)
		set_pattern(Vector2i(x, y), pattern)
