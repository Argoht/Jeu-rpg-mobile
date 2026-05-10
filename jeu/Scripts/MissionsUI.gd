extends MarginContainer

# On récupère le conteneur principal de la scène
@onready var mission_vbox = VBoxContainer.new()

func _ready():
	# Configuration de base du conteneur
	add_theme_constant_override("margin_left", 15)
	add_theme_constant_override("margin_right", 15)
	add_theme_constant_override("margin_bottom", 15)
	
	mission_vbox.name = "MissionVBox"
	mission_vbox.add_theme_constant_override("separation", 15)
	add_child(mission_vbox)
	
	# On génère la liste dès l'apparition
	_display_missions_list()

func _display_missions_list():
	# Nettoyage : On renomme les enfants avant de les détruire
	for child in mission_vbox.get_children():
		child.name = child.name + "_A_Detruire"
		child.queue_free()

	var rank_val = GlobalEngine.get_rank_by_level(GlobalEngine.lvl)
	
	# Label du Rang
	var rank_label = Label.new()
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.text = "STATUT : RANG " + rank_val
	var rank_color = Color("#00f2ff")
	if rank_val == "S": rank_color = Color("#ff00ff")
	elif rank_val == "A": rank_color = Color("#ff4444")
	rank_label.add_theme_color_override("font_color", rank_color)
	rank_label.add_theme_font_size_override("font_size", 22)
	mission_vbox.add_child(rank_label)
	
	# Label du Timer
	var timer_lbl = Label.new()
	timer_lbl.name = "UI_Timer_Label"
	timer_lbl.text = "SYNC DANS : " + GlobalEngine.get_time_string() 
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_color_override("font_color", Color("#00f2ff"))
	mission_vbox.add_child(timer_lbl)
	
	mission_vbox.add_child(HSeparator.new())
	
	# Génération des cartes de mission
	for m in GlobalEngine.available_missions:
		var card = _create_mission_card(m)
		mission_vbox.add_child(card)

func _create_mission_card(m: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var s = StyleBoxFlat.new()
	
	s.bg_color = Color("#081a2b") 
	s.border_width_left = 4
	s.border_color = Color("#00f2ff") if m.status == "available" else Color("#444444")
	card.add_theme_stylebox_override("panel", s)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 12)
	
	var text_margin = MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 30) 
	
	var text_vbox = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "[" + m.id + "] " + m.titre.to_upper()
	title.add_theme_color_override("font_color", Color("#00f2ff"))
	text_vbox.add_child(title)
	
	var task = Label.new()
	task.text = m.desc
	task.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_vbox.add_child(task)
	
	text_margin.add_child(text_vbox)
	v.add_child(text_margin)

	var btn = Button.new()
	var stat_val = int(GlobalEngine.stats.get(m.stat.to_lower(), 0))
	
	if m.status != "available":
		btn.disabled = true
		btn.text = m.status.to_upper()
	elif stat_val < int(m.valeur_requise):
		btn.disabled = true
		btn.text = "REQUIS : " + m.stat.to_upper() + " " + str(m.valeur_requise)
	else:
		btn.text = "S'ENGAGER [" + str(m.end_cost) + " END]"

	btn.pressed.connect(_show_mission_dialog.bind(m))
	v.add_child(btn)
	margin.add_child(v)
	card.add_child(margin)
	return card

func _show_mission_dialog(mission: Dictionary):
	var confirm = ConfirmationDialog.new()
	confirm.title = "SYSTÈME"
	confirm.dialog_text = "Accepter cette mission ?"
	confirm.ok_button_text = "ACCEPTER"
	confirm.cancel_button_text = "REFUSER"
	confirm.confirmed.connect(func(): _show_outcome_choice(mission))
	add_child(confirm)
	confirm.popup_centered()

func _show_outcome_choice(mission: Dictionary):
	var outcome = ConfirmationDialog.new()
	outcome.title = "RÉSULTAT"
	outcome.dialog_text = "Objectif accompli ?"
	
	# MODIFICATION ICI : On change le texte des boutons
	outcome.ok_button_text = "RÉUSSITE"
	outcome.cancel_button_text = "ÉCHEC"
	
	outcome.confirmed.connect(func(): 
		GlobalEngine.process_mission_result(mission, true)
		_display_missions_list()
	)
	outcome.canceled.connect(func(): 
		GlobalEngine.process_mission_result(mission, false)
		_display_missions_list()
	)
	add_child(outcome)
	outcome.popup_centered()

func _process(_delta):
	var timer_lbl = mission_vbox.get_node_or_null("UI_Timer_Label")
	if timer_lbl:
		timer_lbl.text = "SYNC DANS : " + GlobalEngine.get_time_string()
