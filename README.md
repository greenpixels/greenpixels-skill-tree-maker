# Skill Tree Interface (JSON)

Simple tool for creating skill trees.

## Export Data Structure

### Root Fields

- `nodes`: List of skills with position and unlock rules.  
- `connections`: Links between skills.  
- `node_id_index`: Next free node ID.  
- `connection_id_index`: Next free connection ID.

### Node

```json
{
  "id": 0,
  "key": "name_of_my_skill",
  "max_points": 1,
  "needed_neighbour_point_sum": 0,
  "position_x": 180.0,
  "position_y": 0.0
}
```

- `id`: Unique skill ID  
- `key`: Skill key
- `max_points`: Max allocatable points  
- `needed_neighbour_point_sum`: Points needed from neighbors to make this node available 
- `position_x/y`: UI position

### Connection

```json
{
  "id": 0,
  "from_skill_id": 0,
  "to_skill_id": 1,
  "from_anchor": "RIGHT",
  "to_anchor": "LEFT"
}
```

- Connects one skill to another for dependency or UI  
- Anchors are visual positions (`"UP"`, `"DOWN"`, `"LEFT"`, `"RIGHT"`, `"UP_LEFT"`, `"UP_RIGHT"`, `"DOWN_LEFT"`, `"DOWN_RIGHT"` )