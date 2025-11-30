extends CharacterBody2D

@export var move_speed = 80.0
@onready var animation_player = $AnimationPlayer
@onready var visuals = $Visuals # 获取那个父节点，方便翻转

enum State { WALKING, SITTING, EATING }
var current_state = State.WALKING

var current_path: PackedVector2Array = [] # 存储路径点
var target_table = null # 目标桌子

func _ready():
	# 客人一出生，就找个位子
	find_seat()

func find_seat():
	# 1. 找到所有桌子
	var tables = get_tree().get_nodes_in_group("Tables")
	
	# 2. 筛选出空桌子
	for table in tables:
		if not table.is_occupied:
			target_table = table
			table.sit_down() # 先占座，防止别人抢
			move_to(table.get_seat_pos())
			print("找到桌子了")
			return
	
	print("没有空位了！")
	queue_free() # 没位子就离开消失

func start_sitting():
	# 1. 切换状态
	current_state = State.SITTING
	
	# 2. 强制对齐坐标 (这一步非常重要！)
	# 防止他在椅子边缘看起来像悬空
	if target_table:
		# 获取椅子的世界坐标
		var map = get_node("/root/MainGame/TileMapLayer")
		var seat_grid_pos = target_table.get_seat_pos()
		position = map.map_to_local(seat_grid_pos)
		
		# 视觉微调：人坐着的时候通常比站着要矮一点，或者位置要往上一点(视觉上坐在凳子上)
		# position.y -= 10 # 根据你的图片调整这个值
		
		# 3. 让人面向桌子
		# 如果桌子在人的左边，人就朝左；在右边，人就朝右
		var table_grid_pos = target_table.get_grid_pos()
		if table_grid_pos.x < seat_grid_pos.x:
			visuals.scale.x = 1 # 朝左 (假设你的素材默认朝左)
		else:
			visuals.scale.x = -1 # 朝右

	# 4. 停止走路动画
	animation_player.stop()
	$Visuals/Legs.region_rect = Rect2(-0.757, 50.68, 30.868, 27.228)
	# 如果你有坐下的图片（比如把腿隐藏起来，或者换个坐姿腿），在这里切换
	# $Visuals/Legs.hide() 
	# animation_player.play("sit")

func move_to(grid_target: Vector2i):
	# 向主游戏脚本请求路径
	var map = get_node("/root/MainGame/TileMapLayer")
	var main = get_node("/root/MainGame")
	
	var start_pos = map.local_to_map(position)
	# 获取世界坐标路径点
	current_path = main.get_path_to_target(start_pos, grid_target)

func _physics_process(delta):
	if current_state == State.SITTING:
		return
	if current_path.is_empty():
		return # 到达目的地了，或者没路走
	
	# 取出路径里的第一个点（目标点）
	var next_point = current_path[0]
	position = position.move_toward(next_point, move_speed * delta)
	
	# 检查是否到达（因为 move_toward 保证不会超车，所以可以用极小距离判断）
	if position.distance_to(next_point) < 2.0:
		current_path.remove_at(0) # 移除这个点，前往下一个
		if current_path.is_empty():
			# 路径空了，说明到达了最后一个点（椅子）
			start_sitting()
	
	# 计算移动方向用于翻转图片 (可选)
	var direction = (next_point - position).normalized()
	if direction.length() > 0:
		if direction.x > 0: visuals.scale.x = -1
		else: visuals.scale.x = 1
	
	# 移动过去
	var distance = position.distance_to(next_point)
	
	if distance < 5.0: # 如果距离很近了，算作到达该点
		position = next_point # 强制吸附，防止抖动
		current_path.remove_at(0) # 移除这个点，前往下一个
	else:
		# 匀速移动
		velocity = position.direction_to(next_point) * move_speed
		move_and_slide()

func _process(delta):
	# 简单的动画状态机
	if current_state == State.SITTING:
		return
	if current_state == State.WALKING:
		if not animation_player.is_playing():
			animation_player.play("walk_down")
			
		# 处理左右翻转
		if velocity.x > 0:
			# 向右走，镜像翻转
			visuals.scale.x = -1 
		else:
			# 向左走，恢复正常
			visuals.scale.x = 1
	else:
		# 停止移动时，停止动画，或者播放待机动画
		animation_player.stop()
		# 如果你有 idle 动画，取消下面这行的注释
		# animation_player.play("idle")
