class_name MainMap extends TileMapLayer

func get_threat_level(pos: Vector2) -> int:
	#DEBUG print("MainMap.gd/get_threat_level() called")
	var cell : Vector2 = local_to_map(pos)
	var tile : int = get_cell_source_id(cell)
	match tile:
		_:
			return 1
