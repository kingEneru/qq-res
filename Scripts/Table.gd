extends Sprite2D

# 定义椅子相对于桌子的位置 (假设椅子在桌子的右下方格子：x+0, y+1)
# 根据你的美术图，可能需要调整这个偏移量
var seat_offset = Vector2i(0, 1) 

var is_occupied = false # 是否有人坐了

func get_grid_pos() -> Vector2i:
	# 将自己的像素坐标 转换为 网格坐标
	# 注意：这里假设父节点就是 MainGame，或者通过 get_parent() 能找到 TileMapLayer
	# 为了简单，我们通过全局组或者直接向上查找。这里先用最直接的方法：
	var map = get_node("/root/MainGame/TileMapLayer") # 绝对路径查找
	return map.local_to_map(position)

func get_seat_pos() -> Vector2i:
	return get_grid_pos() + seat_offset

func sit_down():
	is_occupied = true

func stand_up():
	is_occupied = false
