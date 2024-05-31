extends Node

var _window_size: Vector2i
var _action_list: Dictionary
var _interact_func = null
var _interact_name = ''
var _game_state = {}
var _capcam_name = ''
var _chat_dialogue = null
var _chat_index = 0
var _chat_ready = false
var _chat_complete = null
var _game = null


func _ready() -> void:
	var viewport_width = ProjectSettings.get("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get("display/window/size/viewport_height")
	_window_size = Vector2i(viewport_width, viewport_height)
	print(type_string(typeof(_window_size)))
	%HUD.max_cups = len(%Interactions.find_children('cup*'))
	%HUD.lives = game_state('lives', 3)
	%HUD.cups = game_state('cups', 0)
	%HUD.visible = true
	%BGs.visible = true
	print("window: ", _window_size)
	print("game state: ", _game_state)
	%HUD.start_title_menu()

func _process(_delta: float) -> void:
	if %Player.position.x < _window_size.x * -7:
		%Player.position.x += _window_size.x
	if _capcam_name == '' && %Player.is_alive():
		var pos = _get_camera_pos_for_player()
		if pos != %Camera2D.position:
			if _bg_at(pos):
				%Camera2D.position = pos
				%Player.set_restart_point()
			elif pos.y > %Camera2D.position.y:
				_kill_player(true)

	# progress chat
	if _chat_dialogue && _chat_ready:
		_chat_ready = false
		var line = _chat_dialogue[_chat_index]
		%HUD.chat(line[0] == 'F', line.right(-1))

	# menu
	if Input.is_action_just_pressed('menu'):
		%HUD.start_pause_menu()

func _kill_player(fall: bool):
	if %Player.is_alive():
		%Player.die(fall)
		_action_list = {
			"after": func():
				_revive_player()
				%AnimationPlayer.play('default'),
		}
		%AnimationPlayer.play('wait-action-fade')

func _revive_player():
	if %HUD.lives > 0:
		%HUD.lives -= 1
		set_game_state('lives', %HUD.lives)
		%Player.reserect()
	else:
		get_tree().quit()

func _get_camera_pos_for_player():
	return _get_camera_pos_for(%Player.position)

func _get_camera_pos_for(target: Vector2):
	var pos = %Camera2D.position
	while target.x > pos.x + _window_size.x:
		pos.x += _window_size.x
	while target.x < pos.x:
		pos.x -= _window_size.x
	while target.y > pos.y + _window_size.y:
		pos.y += _window_size.y
	while target.y < pos.y:
		pos.y -= _window_size.y
	return pos

func _bg_at(pos: Vector2) -> bool:
	if %BGs.get_rect().has_point(pos):
		return true
	for kid in %BGs.get_children():
		if kid.get_rect().has_point(pos):
			return true
	return false

# --

# play a named sound
func sound(snd_name: String) -> AudioStreamPlayer:
	var player = %Sounds.find_child(snd_name)
	if player: player.play()
	return player

# set an interaction action for a named object
func set_interaction(obj_name: String, action):
	print("touching: ", obj_name)
	_interact_func = action
	_interact_name = obj_name

# remove the interaction action for a named object
func unset_interaction(obj_name: String):
	if _interact_name == obj_name:
		_interact_func = null
		print("touching: ---")

# perform any interaction action set
func do_interact():
	if _interact_func:
		print("interacting with: ", _interact_name)
		_interact_func.call()

# teleport to a named object
func teleport(target: String):
	print("teleporting to: ", target)
	var target_obj = %Interactions.find_child(target, false)
	if target_obj:
		sound('teleport')
		%Player.freeze()
		_action_list = {
			"main": func():
				%Player.position = target_obj.get_center()
				%Camera2D.position = _get_camera_pos_for_player(),
			"after": func():
				%Player.unfreeze()
		}
		%AnimationPlayer.play('fade-out-action-in')

# perform an animatioon action from the action list
func take_action(type: String):
	if _action_list.has(type):
		_action_list[type].call()

# set a named game state variable
func set_game_state(key: String, value):
	print("game state: ", key, " = ", value)
	_game_state[key] = value

# get a named game state variable
func game_state(key: String, default):
	if !_game_state.has(key):
		_game_state[key] = default
	return _game_state[key]

# toggle on/off an interactive object by name
func toggle_interactive(obj_name: String, on: bool):
	print("toggle: ", obj_name, " = ", "on" if on else "off")
	var obj = %Interactions.find_child(obj_name)
	if obj: obj.toggle(on)

# kill the player, horiffically
func kill_player():
	_kill_player(false)

# capture the camera focus for a named object
func capture_camera(obj_name: String, pos: Vector2):
	if _capcam_name != '__PROTECTED__':
		var campos = _get_camera_pos_for(pos)
		if campos != %Camera2D.position:
			%Camera2D.position = campos
			%Player.freeze()
			_capcam_name = obj_name
		else:
			_capcam_name = ''

# release the captured camera focus for a named object
func release_camera(obj_name: String):
	if _capcam_name == obj_name:
		_capcam_name = '__PROTECTED__'
		_action_list = {
			"main": func():
				_capcam_name = '',
			"after": func():
				%Player.unfreeze()
		}
		%AnimationPlayer.play('fade-out-action-in')

# Start a conversation
func start_chat(dialogue: Array, complete):
	%Player.freeze()
	_chat_dialogue = dialogue
	_chat_index = 0
	_chat_ready = true
	_chat_complete = complete

# Advance chat...
func advance_chat():
	_chat_index += 1
	if _chat_index >= len(_chat_dialogue):
		end_chat()
	else:
		_chat_ready = true

# End an ongoing chat
func end_chat():
	%Player.unfreeze()
	%HUD.chat_off()
	_chat_dialogue = null
	if _chat_complete:
		_chat_complete.call()

# Switch player
func switch_player():
	var pink = !%Player.is_pink()
	%Player.be_pink(pink)

# Collect cup
func collect_cup():
	%HUD.cups += 1
	set_game_state('cups', %HUD.cups)
	if %HUD.cups == 5:
		print("start congrats")
		%Player.freeze()
		%HUD.start_congrats()
		%AnimationPlayer.play('congrats')
		sound('congrats')
