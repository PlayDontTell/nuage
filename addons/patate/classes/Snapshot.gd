@tool
@icon("res://addons/patate/assets/icons/save.png")
class_name Snapshot
extends Resource

## The display name of this snapshot
@export var label: String = ""

## Category prefix used in filename for explorer sorting
@export var category: String = ""

## A free-writing description to better understand the purpose of this snapshot.
@export var description: String = ""

## The core scene to load when this snapshot is applied
@export var core_scene: StringName = &""

## When this snapshot was created
@export var created_at: String = ""

## The save data state captured at snapshot time
@export var save_data: SaveData = null
