extends Control

@onready var _main = get_node('/root/Main')

func _ready() -> void:
	reset()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_start_button_pressed() -> void:
	%AnimationPlayer.play("start")
	%Fade.visible = true
	enable_focus(false)

func _on_after_fade() -> void:
	_main.start_game()

# --

func reset() -> void:
	%Fade.visible = false
	enable_focus(true)
	find_children("*", "Button")[0].grab_focus()
	%AnimationPlayer.play('reset')

func enable_focus(on: bool) -> void:
	var buttons = find_children("*", "Button")
	for button in buttons:
		button.focus_mode = (FOCUS_ALL if on else FOCUS_NONE)
