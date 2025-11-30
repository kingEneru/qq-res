extends Node2D

# 获取地图和家具层的引用
@onready var tile_map = $TileMapLayer
@onready var furniture_layer = $FurnitureLayer
@onready var spawn_point = $SpawnPoint

# 寻路算法实例
var astar = AStarGrid2D.new()
# 地图大小（假设你的餐厅是 20x20 格子，不够可以改大）
var map_rect =Rect2i(-50, -50, 100, 100)
var customer_scene = preload("res://Scenes/Customer.tscn")

func spawn_customer(number):
	print("已生成顾客:", number+1)
	var customer = customer_scene.instantiate()
	
	# 1. 直接使用标记点的像素位置
	customer.position = spawn_point.position
	
	# 2. 算出这个位置对应的格子坐标 (为了寻路用)
	# 这一步是为了防止你把 Marker2D 稍微放歪了一点点，强制修正到格子里
	var start_grid = tile_map.local_to_map(customer.position)
	
	# (可选) 安全检查：如果门口被堵住了，就不要生成
	if not astar.is_in_boundsv(start_grid) or astar.is_point_solid(start_grid):
		print("警告：大门位置无效或被家具堵住了！", start_grid)
		customer.queue_free()
		return
		
	# --- 修改结束 ---
	furniture_layer.add_child(customer)
	print("顾客已从大门出现")

func _ready():
	setup_pathfinding()
	for i in range(4):
		# 测试：2秒后生成一个客人 (后面我们会删掉这行)
		await get_tree().create_timer(1.0).timeout
		spawn_customer(i)

func setup_pathfinding():
	# 1. 配置 AStar
	astar.region = map_rect
	astar.cell_size = Vector2(64, 32) # 你的网格大小
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # QQ餐厅一般不允许走斜线
	astar.update() # 初始化数据

	# 2. 标记障碍物 (遍历所有家具)
	for child in furniture_layer.get_children():
		if child.has_method("get_grid_pos"):
			var pos = child.get_grid_pos()
			# 设置该格子为不可行走 (Solid)
			astar.set_point_solid(pos, true)

# 这是一个辅助函数：给客人提供路径
func get_path_to_target(start_grid: Vector2i, end_grid: Vector2i) -> PackedVector2Array:
	return astar.get_point_path(start_grid, end_grid)
