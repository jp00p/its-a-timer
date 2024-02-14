extends Node2D

var timers = [
    {
        "name": "Fun",
        "minutes":15,
        "seconds":0,
        "color":Color("Purple"),
    },
]

var current_timer_idx = 0 : set = set_timer_idx
@onready var timer:Timer = %Timer
@onready var progress:ProgressBar = %Progress
@onready var label:RichTextLabel = %TextLabel
@onready var time_remaining:RichTextLabel = %TimerText
@onready var audio:AudioStreamPlayer2D = %Audio
@onready var popup:Window = %Window
@onready var reward:TextureRect = %Reward
@onready var add_timer:Window = %AddTimer

var current_timer:Dictionary
var styles:StyleBoxFlat
var rewards:Array = []
var local_path:String = OS.get_executable_path().get_base_dir()
var rewards_folder_name:String = "/rewards/"

func _ready():
    randomize()
    popup.hide()
    load_rewards()
    set_current_timer()

## Load reward images from the directory
## Create directory if it doesn't exist
## TODO: Live reload reward images
func load_rewards():
    var rewards_path = local_path + rewards_folder_name
    var rewards_source = "res://rewards/"
    var dir = DirAccess.open(rewards_path)
    if !dir:
        dir = DirAccess.make_dir_absolute(rewards_path)

    for reward in dir_contents(rewards_path):
        var reward_image = Image.load_from_file(reward)
        rewards.push_front(ImageTexture.create_from_image(reward_image))

## Set the active timer (based on current_timer_idx)
func set_current_timer():
    current_timer = timers[current_timer_idx]
    var timer_total_time = max(1, (current_timer["minutes"] * 60 + current_timer["seconds"]))
    timer.wait_time = timer_total_time
    styles = progress.get_theme_stylebox("fill")
    styles.bg_color = current_timer["color"]
    timer.start()
    timer.paused = true
    update_text()
    progress.max_value = timer_total_time
    progress.value = timer_total_time
    if rewards.size() > 0:
        reward.texture = rewards.pick_random()

## Update text in the UI
## Also updates progress bar
func update_text() -> void:
    label.text = "%s" % current_timer["name"]
    time_remaining.text = "Time remaining: %02d:%02d" % [int(timer.time_left/60), (int(timer.time_left) % 60)]
    progress.value = timer.time_left

## Every frame
func _process(_delta) -> void:
    update_text()
    %RemoveTimer.disabled = timers.size() <= 1

## Listen for user input
## F1 will perform a sound test
func _input(_event) -> void:
    if Input.is_action_just_pressed("soundtest"):
        audio.play()

## When play/pause button is pressed
func _on_play_pressed() -> void:
    if timer.is_stopped():
        timer.start()
    else:
        timer.paused = !timer.paused

## When stop is pressed
func _on_stop_pressed() -> void:
    audio.stop()
    timer.stop()

## When next is pressed
func _on_next_pressed() -> void:
    popup.hide()
    audio.stop()
    timer.stop()
    self.current_timer_idx += 1
    set_current_timer()

## Set timer index
## Wrap around size of timers list
func set_timer_idx(val:int) -> void:
    current_timer_idx = wrapi(val, 0, len(timers))

## When timer finishes
func _on_timer_timeout() -> void:
    self.current_timer_idx += 1
    audio.play()
    set_current_timer()
    get_viewport().request_attention()
    if rewards.size() > 0:
        popup.show()

## Rewards window close button
func _on_window_close_requested() -> void:
    popup.hide()

## Finalize creating new timer
func _on_add_timer_pressed() -> void:
    var timer_name = "Unnamed Timer"
    if %TimerName.text != "":
        timer_name = %TimerName.text
    var timer_details = {
        "name": timer_name,
        "minutes":max(0,int(%TimerMinutes.text)),
        "seconds":max(0, int(%TimerSeconds.text)),
        "color":%ChooseColor.color,
    }
    timers.push_back(timer_details)
    self.current_timer_idx = timers.size()-1
    set_current_timer()
    add_timer.hide()
    %TimerName.text = ""
    %TimerMinutes.text = ""
    %TimerSeconds.text = ""

## List directory contents
## Returns array of filenames
func dir_contents(path:String) -> Array:
    var dir = DirAccess.open(path)
    var files = []
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if !dir.current_is_dir() and file_name.get_extension() != "import":
                files.push_front(path + file_name)
            file_name = dir.get_next()
    else:
        print("An error occurred when trying to access the path: %s" % path)
    return files

## Close "add timer" popup
func _on_add_timer_close_requested() -> void:
    add_timer.hide()

## Click "add timer" button
func _on_add_new_timer_pressed() -> void:
    %ChooseColor.color = Color(randi(), 1.0)
    add_timer.show()

## Click "remove timer" button
## Only works if there's more than 1 timer
func _on_remove_timer_pressed() -> void:
    if timers.size() <= 1:
        return
    audio.stop()
    timer.stop()
    timers.remove_at(current_timer_idx)
    self.current_timer_idx = 0
    set_current_timer()
