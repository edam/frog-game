extends Node

var window_size: Vector2i
var game: Node
var _game_scene = preload("res://scenes/game/game.tscn")

func _ready() -> void:
	var viewport_width = ProjectSettings.get("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get("display/window/size/viewport_height")
	window_size = Vector2i(viewport_width, viewport_height)
	print("main: window ", window_size)
	_start_title()

func _start_title() -> void:
	print("main: title screen")
	%Title.reset()
	%Title.visible = true

# play a named sound
func sound(snd_name: String) -> AudioStreamPlayer:
	var player = %Sounds.find_child(snd_name)
	if player: player.play()
	return player

func start_game() -> void:
	if game != null: return
	print("main: start game")
	game = _game_scene.instantiate()
	add_child(game)
	game.start()
	%Title.enable_focus(false)

func end_game() -> void:
	if game == null: return
	print("main: end game")
	remove_child(game)
	game = null
	_start_title()
