class_name NozzlePreset
extends Resource

@export var nozzle_label: String = "25°"
@export_range(8.0, 512.0) var spray_size_px: float = 64.0
@export_range(0.01, 1.0) var pressure: float = 0.5
## Optional nozzle spray shape. White (default) = uniform circle.
@export var spray_pattern: Texture2D
