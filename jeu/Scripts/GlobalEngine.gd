extends Node

signal stats_updated
signal leveled_up(new_level)
signal tab_changed(tab_name) # Signal pour notifier l'UI du changement d'onglet

const SAVE_PATH = "user://save_game.dat"

# --- DONNÉES JOUEUR ---
var hp: int = 100
var max_hp: int = 100
var end: int = 100
var max_end: int = 100
var xp: int = 0
var next_xp: int = 100 
var lvl: int = 1
var stat_points: int = 0 

# --- STATS DE COMBAT ---
var atk: int = 12
var def: int = 6

# --- INVENTAIRE ET NAVIGATION ---
var inventory: Array = []
var items_per_page: int = 45 
var current_inventory_page: int = 0
var current_tab: String = "missions" # Pour suivre l'onglet actif

# --- CYCLE DU SYSTÈME ---
var reset_duration: float = 21600.0 # 6 heures
var time_until_reset: float = reset_duration 
var auto_save_timer: float = 0.0

# --- STATS INITIALES ---
var stats: Dictionary = {
	"str": 1, "dex": 1, "vit": 1, "int": 1,
	"wis": 1, "per": 1, "cha": 1, "wil": 1, 
	"spd": 100, "lck": 1
}

# --- CATALOGUE COMPLET ---
var mission_catalog = {
	"F": [
		{"id":"F-01","titre":"Initialisation","stat":"vit","desc":"Marcher 2 km sans interruption."},
		{"id":"F-02","titre":"Activation Physique","stat":"str","desc":"Faire 20 squats."},
		{"id":"F-03","titre":"Concentration Basique","stat":"int","desc":"Lire 10 pages d’un livre."},
		{"id":"F-04","titre":"Routine Stable","stat":"wis","desc":"Ranger ton espace de travail."},
		{"id":"F-05","titre":"Réflexes Naissants","stat":"dex","desc":"Faire rebondir une balle 50 fois."},
		{"id":"F-06","titre":"Vision du Joueur","stat":"per","desc":"Mémoriser 10 objets dans un lieu public."},
		{"id":"F-07","titre":"Barrière Mentale","stat":"wil","desc":"Douche froide de 30 secondes."},
		{"id":"F-08","titre":"Premier Contact","stat":"cha","desc":"Parler à une nouvelle personne."},
		{"id":"F-09","titre":"Respiration Stable","stat":"vit","desc":"5 min de respiration contrôlée."},
		{"id":"F-10","titre":"Validation du Système","stat":"wis","desc":"Compléter 3 missions aujourd'hui."}
	],
	"E": [
		{"id":"E-01","titre":"Corps en Éveil","stat":"str","desc":"50 pompes cumulées."},
		{"id":"E-02","titre":"Marche du Survivant","stat":"vit","desc":"Marcher 5 km."},
		{"id":"E-03","titre":"Analyse Tactique","stat":"int","desc":"Apprendre une compétence (20 min)."},
		{"id":"E-04","titre":"Rythme du Combat","stat":"dex","desc":"3 séries de corde à sauter."},
		{"id":"E-05","titre":"Présence du Joueur","stat":"cha","desc":"Contact visuel assuré (3 conv)."},
		{"id":"E-06","titre":"Concentration Totale","stat":"wil","desc":"1h sans réseaux sociaux."},
		{"id":"E-07","titre":"Vision Accrue","stat":"per","desc":"Décrire un lieu mémorisé."},
		{"id":"E-08","titre":"Routine du Joueur","stat":"wis","desc":"Réveil à l'heure (3 jours)."},
		{"id":"E-09","titre":"Impact Contrôlé","stat":"str","desc":"100 squats cumulés."},
		{"id":"E-10","titre":"Adaptation Rapide","stat":"dex","desc":"Tester une activité physique."}
	],
	"D": [
		{"id":"D-01","titre":"Épreuve de Résistance","stat":"vit","desc":"Courir 3 km."},
		{"id":"D-02","titre":"Force Croissante","stat":"str","desc":"100 pompes cumulées."},
		{"id":"D-03","titre":"Lecture du Terrain","stat":"per","desc":"Trouver 5 optimisations."},
		{"id":"D-04","titre":"Discipline de Fer","stat":"wis","desc":"Tâches prévues complétées."},
		{"id":"D-05","titre":"Esprit Calculateur","stat":"int","desc":"Puzzle (30 min)."},
		{"id":"D-06","titre":"Déplacement Fantôme","stat":"dex","desc":"HIIT de 15 minutes."},
		{"id":"D-07","titre":"Volonté Acérée","stat":"wil","desc":"Tâche sans interruption."},
		{"id":"D-08","titre":"Présence du Joueur","stat":"cha","desc":"Parler devant un groupe."},
		{"id":"D-09","titre":"Charge Continue","stat":"vit","desc":"10 000 pas dans la journée."},
		{"id":"D-10","titre":"Entraînement Double","stat":"str","desc":"Deux séances de sport."}
	],
	"C": [
		{"id":"C-01","titre":"Corps d’Acier","stat":"str","desc":"200 squats cumulés."},
		{"id":"C-02","titre":"Respiration du Prédateur","stat":"vit","desc":"5 km sans pause."},
		{"id":"C-03","titre":"Réaction Instantanée","stat":"dex","desc":"Agilité (20 min)."},
		{"id":"C-04","titre":"Analyse Supérieure","stat":"int","desc":"Étude complexe (1h)."},
		{"id":"C-05","titre":"Regard du Joueur","stat":"per","desc":"Identifier 10 comportements."},
		{"id":"C-06","titre":"Présence Dominante","stat":"cha","desc":"Mener une réunion."},
		{"id":"C-07","titre":"Mental Renforcé","stat":"wil","desc":"24h sans sucre."},
		{"id":"C-08","titre":"Routine Parfaite","stat":"wis","desc":"Routine matinale (7 jours)."},
		{"id":"C-09","titre":"Enchaînement Continu","stat":"vit","desc":"45 min d'effort."},
		{"id":"C-10","titre":"Force Explosive","stat":"str","desc":"20 burpees + 500m sprint."}
	],
	"B": [
		{"id":"B-01","titre":"Joueur Confirmé","stat":"str","desc":"150 pompes cumulées."},
		{"id":"B-02","titre":"Endurance d’Élite","stat":"vit","desc":"Courir 8 km."},
		{"id":"B-03","titre":"Instinct de Combat","stat":"dex","desc":"Réflexes (30 min)."},
		{"id":"B-04","titre":"Esprit du Stratège","stat":"int","desc":"Lire et résumer un livre."},
		{"id":"B-05","titre":"Volonté Inflexible","stat":"wil","desc":"Réveil avant 6h (5 j)."},
		{"id":"B-06","titre":"Perception Totale","stat":"per","desc":"Marche sans téléphone."},
		{"id":"B-07","titre":"Influence du Leader","stat":"cha","desc":"Activité de groupe."},
		{"id":"B-08","titre":"Discipline Absolue","stat":"wis","desc":"Routine sans échec (14 jours)."},
		{"id":"B-09","titre":"Charge Maximale","stat":"str","desc":"Porter charges lourdes."},
		{"id":"B-10","titre":"Marathon Mental","stat":"int","desc":"Travail intense (3h)."}
	],
	"A": [
		{"id":"A-01","titre":"Limiteur Brisé","stat":"str","desc":"Entraînement intense (1h)."},
		{"id":"A-02","titre":"Souffle Inépuisable","stat":"vit","desc":"Courir 12 km."},
		{"id":"A-03","titre":"Réaction Ultime","stat":"dex","desc":"Sprint + Agilité explosif."},
		{"id":"A-04","titre":"Calcul de Bataille","stat":"int","desc":"Compétence avancée (2h)."},
		{"id":"A-05","titre":"Volonté du Prédateur","stat":"wil","desc":"Action repoussée accomplie."},
		{"id":"A-06","titre":"Sixième Sens","stat":"per","desc":"24h sans distraction numérique."},
		{"id":"A-07","titre":"Présence Dominante","stat":"cha","desc":"Diriger projet."},
		{"id":"A-08","titre":"Routine Inébranlable","stat":"wis","desc":"Routine ok (30 jours)."},
		{"id":"A-09","titre":"Corps en Surcharge","stat":"vit","desc":"90 min sport continu."},
		{"id":"A-10","titre":"Force du Boss","stat":"str","desc":"Record personnel battu."}
	],
	"S": [
		{"id":"S-01","titre":"Éveil du Ascendant","stat":"wil","desc":"7 jours sport sans abandon."},
		{"id":"S-02","titre":"Corps Transcendant","stat":"str","desc":"Défi physique extrême."},
		{"id":"S-03","titre":"Endurance Infinie","stat":"vit","desc":"20 km sur une journée."},
		{"id":"S-04","titre":"Précision Absolue","stat":"dex","desc":"Entraînement technique (1h)."},
		{"id":"S-05","titre":"Esprit du Ascendant","stat":"int","desc":"Plan 90 jours amélioration."},
		{"id":"S-06","titre":"Instinct Ultime","stat":"per","desc":"Journée pleine conscience."},
		{"id":"S-07","titre":"Présence du Roi","stat":"cha","desc":"Coacher quelqu'un."},
		{"id":"S-08","titre":"Discipline Absolue","stat":"wis","desc":"Habitudes ok (60 jours)."},
		{"id":"S-09","titre":"Survie Extrême","stat":"wil","desc":"24h sans confort."},
		{"id":"S-10","titre":"Synchronisation Finale","stat":"str","desc":"1 mission/stat par semaine."}
	]
}

var available_missions: Array = []

func _ready():
	load_game()
	update_derived_stats()
	if available_missions.is_empty():
		generate_daily_missions()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()

func _process(delta):
	if time_until_reset > 0:
		time_until_reset -= delta
	else:
		reset_daily_missions()
	
	auto_save_timer += delta
	if auto_save_timer >= 30.0:
		auto_save_timer = 0.0
		save_game()

# --- GESTION DE LA NAVIGATION (ONGLETS ET PAGES) ---

func change_tab(new_tab: String):
	current_tab = new_tab
	tab_changed.emit(new_tab)
	stats_updated.emit()

func next_inventory_page():
	var max_pages = ceil(float(inventory.size()) / items_per_page)
	if current_inventory_page < max_pages - 1:
		current_inventory_page += 1
		stats_updated.emit()

func prev_inventory_page():
	if current_inventory_page > 0:
		current_inventory_page -= 1
		stats_updated.emit()

func get_current_page_items() -> Array:
	var start = current_inventory_page * items_per_page
	return inventory.slice(start, start + items_per_page)

# --- CALCUL DES STATS ---
func update_derived_stats():
	atk = 10 + (int(stats.get("str", 1)) * 2)
	def = 5 + (int(stats.get("vit", 1)) * 1.5)

# --- SAUVEGARDE ET TEMPS ---

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_data = {
			"hp": hp, "max_hp": max_hp,
			"end": end, "max_end": max_end,
			"xp": xp, "lvl": lvl,
			"stat_points": stat_points,
			"stats": stats,
			"inventory": inventory,
			"available_missions": available_missions,
			"time_until_reset": time_until_reset,
			"last_save_time": Time.get_unix_time_from_system() 
		}
		file.store_string(JSON.stringify(save_data))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(content)
	if typeof(save_data) == TYPE_DICTIONARY:
		hp = int(save_data.get("hp", 100))
		max_hp = int(save_data.get("max_hp", 100))
		end = int(save_data.get("end", 100))
		max_end = int(save_data.get("max_end", 100))
		xp = int(save_data.get("xp", 0))
		lvl = int(save_data.get("lvl", 1))
		stat_points = int(save_data.get("stat_points", 0))
		
		if save_data.has("stats"):
			var saved_stats = save_data["stats"]
			for key in saved_stats.keys():
				stats[key] = int(saved_stats[key])
		
		available_missions = save_data.get("available_missions", [])
		
		# TEMPS
		var saved_timer = float(save_data.get("time_until_reset", reset_duration))
		if save_data.has("last_save_time"):
			var last_time = float(save_data["last_save_time"])
			var current_time = Time.get_unix_time_from_system()
			var elapsed = current_time - last_time
			time_until_reset = max(0, saved_timer - elapsed)
		else:
			time_until_reset = saved_timer

		if time_until_reset <= 0:
			reset_daily_missions()
		
		update_derived_stats()
		stats_updated.emit()

# --- MÉTHODES SYSTÈME ---

func generate_daily_missions():
	available_missions.clear()
	var rank = get_rank_by_level(lvl)
	var pool = mission_catalog.get(rank, mission_catalog["F"]).duplicate()
	pool.shuffle()
	for i in range(min(4, pool.size())):
		var m = pool[i].duplicate()
		m["status"] = "available"
		m["end_cost"] = int(10 + (lvl * 1.5))
		m["xp_reward"] = int(25 + (lvl * 4))
		m["valeur_requise"] = int(1 + (lvl / 2))
		available_missions.append(m)
	save_game()
	stats_updated.emit()

func add_stat(stat_name: String):
	if stat_points > 0 and stats.has(stat_name):
		stats[stat_name] += 1
		stat_points -= 1
		update_derived_stats()
		save_game()
		stats_updated.emit()

func process_mission_result(mission: Dictionary, success: bool):
	if success:
		if end >= mission.get("end_cost", 10):
			end -= mission.get("end_cost", 10)
			xp += mission.get("xp_reward", 25)
			mission["status"] = "completed"
			check_level_up()
	else:
		hp = max(0, hp - 20)
		mission["status"] = "failed"
	
	save_game()
	stats_updated.emit()

func reset_daily_missions():
	hp = max_hp
	end = max_end
	time_until_reset = reset_duration
	generate_daily_missions()

func check_level_up():
	while xp >= (lvl * 100):
		xp -= (lvl * 100)
		lvl += 1
		stat_points += 3
		leveled_up.emit(lvl)
	save_game()

func get_time_string() -> String:
	var ts = int(max(0, time_until_reset))
	return "%02d:%02d:%02d" % [ts / 3600, (ts % 3600) / 60, ts % 60]

func get_rank_by_level(l) -> String:
	if l <= 10: return "F"
	elif l <= 25: return "E"
	elif l <= 40: return "D"
	elif l <= 55: return "C"
	elif l <= 70: return "B"
	elif l <= 85: return "A"
	else: return "S"
