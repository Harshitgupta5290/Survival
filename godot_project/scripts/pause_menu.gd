extends Control

@onready var btn_resume  : Button = $VBox/BtnResume
@onready var btn_restart : Button = $VBox/BtnRestart
@onready var btn_menu    : Button = $VBox/BtnMenu
@onready var music_slider: HSlider = $VBox/MusicSlider
@onready var sfx_slider  : HSlider = $VBox/SFXSlider

func _ready() -> void:
	btn_resume.pressed.connect(func(): get_tree().current_scene.resume_game())
	btn_restart.pressed.connect(func(): get_tree().current_scene.restart_game())
	btn_menu.pressed.connect(func(): get_tree().current_scene.go_to_menu())
	music_slider.value = AudioManager.music_volume * 100
	sfx_slider.value   = AudioManager.sfx_volume * 100
	music_slider.value_changed.connect(func(v): AudioManager.set_music_volume(v / 100.0))
	sfx_slider.value_changed.connect(func(v): AudioManager.set_sfx_volume(v / 100.0))
