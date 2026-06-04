extends Control

@export var web_socket_url = "wss://nrq93719di.execute-api.ap-southeast-2.amazonaws.com/production/"

var _client: WebSocketPeer = WebSocketPeer.new()
var _last_state = WebSocketPeer.STATE_CLOSED

# ─── Node references ─────────────────────────────────────────────────────────

@onready var label           = $VBox/HBox2/Label
@onready var connect_btn     = $VBox/HBox2/Connect
@onready var disconnect_btn  = $VBox/HBox2/Disconnect
@onready var choice_buttons  = [$VBox/HBox/Rock, $VBox/HBox/Paper, $VBox/HBox/Scissor]

# ─── Lifecycle ───────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	_client.poll()

	var state = _client.get_ready_state()

	if state != _last_state:
		_last_state = state
		match state:
			WebSocketPeer.STATE_CONNECTING:
				disconnect_btn.disabled = false
			WebSocketPeer.STATE_OPEN:
				send_message({"type" : "finding_match"})
			WebSocketPeer.STATE_CLOSED:
				connect_btn.disabled = false

	while _client.get_available_packet_count() > 0:
		var text = _client.get_packet().get_string_from_utf8()
		var msg  = JSON.parse_string(text)
		_on_message(msg)

# ─── Message handling ─────────────────────────────────────────────────────────

func _on_message(msg: Dictionary) -> void:
	if not msg.has("type"):
		return

	match msg.type:
		"waiting_for_opponent":
			label.text = "Searching for opponent, please wait..."
		"match_found":
			label.text = "Opponent found! Choose your move."
			set_choice_buttons(false)
		"waiting_for_opponent_choice":
			label.text = "Waiting for opponent to choose..."
		"opponent_disconnected":
			label.text = "You win — your opponent left!"
			set_choice_buttons(true)
		"result":
			match msg.result:
				"win":  label.text = "You win!"
				"lose": label.text = "You lose!"
				"draw": label.text = "It's a draw!"
			await get_tree().create_timer(5.0).timeout
			_on_disconnect_button_press()

# ─── Button handlers ─────────────────────────────────────────────────────────

func _on_rock_button_press()    -> void: _send_choice("rock")
func _on_paper_button_press()   -> void: _send_choice("paper")
func _on_scissor_button_press() -> void: _send_choice("scissor")

func _send_choice(choice: String) -> void:
	send_message({ "type": "choice", "choice": choice })
	set_choice_buttons(true)

func _on_connect_button_press() -> void:
	if _client.connect_to_url(web_socket_url) == OK:
		connect_btn.disabled = true
	else:
		label.text = "Failed to connect."

func _on_disconnect_button_press() -> void:
	_client.close()
	disconnect_btn.disabled = true
	set_choice_buttons(true)

# ─── Helpers ─────────────────────────────────────────────────────────────────

func set_choice_buttons(disabled: bool) -> void:
	for btn in choice_buttons:
		btn.disabled = disabled

func send_message(msg: Dictionary) -> void:
	if _client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_client.send_text(JSON.stringify(msg))
