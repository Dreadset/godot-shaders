tool
class_name ToonSceneBuilder
extends Node

enum DataType { LIGHT, SPECULAR }

const VIEW_NAMES := ["ToonLightDataView", "ToonSpecularDataView"]

export var shadow_resolution: int = 2048 setget _set_shadow_resolution
export var specular_material: SpatialMaterial
export var white_diffuse_material: SpatialMaterial
export var specular_ignores_shadows := false

var light_data: Viewport
var specular_data: Viewport

onready var scene_root := get_tree().edited_scene_root if Engine.editor_hint else get_tree().root


func _ready() -> void:
	if not specular_material:
		specular_material = SpatialMaterial.new()
		specular_material.albedo_color = Color.black
		specular_material.roughness = 0.4
	if not white_diffuse_material:
		white_diffuse_material = SpatialMaterial.new()

	light_data = _find_viewport(DataType.LIGHT)
	specular_data = _find_viewport(DataType.SPECULAR)
	
	if Engine.editor_hint:
		if not light_data:
			light_data = yield(_build_data(DataType.LIGHT), "completed")
		if not specular_data:
			specular_data = yield(_build_data(DataType.SPECULAR), "completed")


func _find_viewport(type: int) -> Viewport:
	var viewport_name: String = VIEW_NAMES[type]
	var container: ToonViewportContainer = scene_root.find_node(
		viewport_name, true, false
	)

	if container:
		return container.get_child(0) as Viewport
	else:
		return null


func _build_data(type: int) -> Viewport:
	var view := ToonViewportContainer.new()
	view.name = VIEW_NAMES[type]
	view.stretch = true
	view.anchor_right = 1
	view.anchor_bottom = 1
	view.self_modulate.a = 0

	var viewport := Viewport.new()
	viewport.transparent_bg = true
	viewport.world = World.new()
	viewport.usage = Viewport.USAGE_3D_NO_EFFECTS
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	if type == DataType.LIGHT:
		viewport.shadow_atlas_size = 1024
	view.add_child(viewport)

	yield(get_tree(), "idle_frame")
	scene_root.add_child(view)
	scene_root.call_deferred("move_child", view, type + 1)
	view.owner = scene_root
	viewport.owner = scene_root

	return viewport


func _set_shadow_resolution(value: int) -> void:
	shadow_resolution = value
	if not Engine.editor_hint:
		return
	if not is_inside_tree():
		yield(self, "ready")
	light_data.shadow_atlas_size = shadow_resolution
	specular_data.shadow_atlas_size = 0 if specular_ignores_shadows else shadow_resolution