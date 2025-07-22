class_name EnemySpawnAreas extends TileMapLayer

const AREAS_WEIGHTED : Array = [
	[ # 0
		"Slime Green", 1,
		"Skeleton",    3],
	[# 1
		"Orc Rider", 1,
		"Orc Elite", 3],
	[# 2
		"Skeleton GS", 1,
		"Clown",    3],
]

func _ready():
	hide()

func get_enemies_weighted_at_cell(pos: Vector2) -> Array:
	print("EnemySpawnAreas.gd/get_enemies_weighted_at_cell() called")
	var cell : Vector2 = local_to_map(pos)
	var autotile_width : int = 4
	var autotile_coord : Vector2i = get_cell_atlas_coords(Vector2i(int(cell.x), int(cell.y)))
	var area_index : int = autotile_coord.x + autotile_coord.y * autotile_width

	# Check bounds
	if area_index < 0 or area_index >= AREAS_WEIGHTED.size():
		#DEBUG print("Invalid area_index: ", area_index)
		return []

	var weighted = AREAS_WEIGHTED[area_index]

	# Handle missing, empty, or 'no encounter' marker (-5)
	if weighted == null or weighted == []:
		return []
	if typeof(weighted) == TYPE_INT and weighted == -5:
		#DEBUG print("Tile marked as no encounter (-5).")
		return []

	return weighted
