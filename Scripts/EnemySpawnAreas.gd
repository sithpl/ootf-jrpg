class_name EnemySpawnAreas extends TileMapLayer

const AREAS_WEIGHTED : Array = [
	[ # 0
		"Slime Green", 3,
		"Skeleton",    3],
]

func _ready():
	hide()

func get_enemies_weighted_at_cell(pos: Vector2) -> Array:
	print("EnemySpawnAreas.gd/get_enemies_weighted_at_cell() called")
	var cell : Vector2 = local_to_map(pos)
	var autotile_width : int = 4
	var autotile_coord : Vector2i = get_cell_atlas_coords(Vector2i(int(cell.x), int(cell.y)))
	var area_index : int = autotile_coord.x + autotile_coord.y * autotile_width
	return AREAS_WEIGHTED[area_index]
