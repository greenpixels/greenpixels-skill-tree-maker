# Skill Tree Interface (JSON)

Simple tool for creating skill trees.

## Export Data Structure

### Root Fields

- `nodes`: List of skills with position and unlock rules.  
- `connections`: Links between skills.  
- `node_id_index`: Next free node ID.  
- `connection_id_index`: Next free connection ID.
- `custom_property_definitions`: Map of custom property name to `{"type": "TEXT"|"BOOLEAN"|"DECIMAL"|"INTEGER"}`.

### Node

```json
{
  "id": 0,
  "key": "name_of_my_skill",
  "max_points": 1,
  "internal_comment": "",
  "position_x": 180.0,
  "position_y": 0.0,
  "image_base64": "<base64 encoded PNG>",
  "custom_properties": {}
}
```

- `id`: Unique skill ID  
- `key`: Skill key
- `max_points`: Max allocatable points  
- `internal_comment`: Optional comment shown as a tooltip when hovering the node
- `position_x/y`: UI position
- `image_base64`: Optional base64 encoded PNG image baked into the export
- `custom_properties`: Per-skill values for each defined custom property

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