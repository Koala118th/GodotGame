extends Control

@export var web_socket_url = "wss://nrq93719di.execute-api.ap-southeast-2.amazonaws.com/production/"	

var _client: WebSocketPeer = WebSocketPeer.new()
var _last_state = WebSocketPeer.STATE_CLOSED

#Nodes
@onready var label = $VBox/HBox2/Label

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	_client.poll()
	
	var state = _client.get_ready_state()
	
	if state != _last_state:
		match state:
			WebSocketPeer.STATE_CONNECTING:
				print("STATE_CONNECTING") 
			WebSocketPeer.STATE_OPEN:
				print("STATE_OPEN") 
				send_message({"type" : "finding_match"})
				$VBox/HBox2/Disconnect.disabled = false
			WebSocketPeer.STATE_CLOSING:	
				print("STATE_CLOSING") 
			WebSocketPeer.STATE_CLOSED:
				print("STATE_CLOSED") 
				$VBox/HBox2/Connect.disabled = false
		_last_state = state
	
	while _client.get_available_packet_count() > 0:
		var packet = _client.get_packet()
		var text = packet.get_string_from_utf8()
		var msg = JSON.parse_string(text)
		decode_message(msg)

func decode_message(msg: Dictionary) -> void:
	if !msg.has("type"):
		return
	
	match msg.type:
		"waiting_for_opponent":
			print("Waiting for the opponent")
			label.text = "Searching for opponent, please wait"
		"match_found":
			enable_buttons()

func _on_rock_button_press() -> void:
	send_message({
		"type" : "choice",
		"choice": "rock"
	})
	
func _on_paper_button_press() -> void:
	send_message({
		"type" : "choice",
		"choice": "paper"
	})

func _on_scissor_button_press() -> void:
	send_message({
		"type" : "choice",
		"choice": "scissor"
	})

func _on_connect_button_press() -> void:
	var connection: = _client.connect_to_url(web_socket_url)
	if connection != OK:
		print("Fail to connect: Errpr %s", connection)
	else:
		print("Connestion initiated")
		$VBox/HBox2/Connect.disabled = true

func _on_disconnect_button_press() -> void:
	_client.close()
	$VBox/HBox2/Disconnect.disabled = true
	disable_button()

#Helpers 
func enable_buttons() -> void:
	$VBox/HBox/Rock.disabled = false
	$VBox/HBox/Paper.disabled = false
	$VBox/HBox/Scissor.disabled = false
	
func disable_button() -> void:
	$VBox/HBox/Rock.disabled = true
	$VBox/HBox/Paper.disabled = true
	$VBox/HBox/Scissor.disabled = true
	
func send_message(msg: Dictionary) -> void:
	if _client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_str = JSON.stringify(msg)
		_client.send_text(json_str)
		
