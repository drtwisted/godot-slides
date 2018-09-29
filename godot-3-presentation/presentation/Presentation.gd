extends Node

signal language_changed()

onready var slides = $Slides
export(String, 'en', 'ja') var LANGUAGE_MAIN = 'en'
export(String, 'en', 'ja') var LANGUAGE_SECOND = 'en'

func _ready():
	TranslationServer.set_locale(LANGUAGE)
	slides.initialize()
#	save_as_csv(get_translatable_strings()) # Use this to save the presentation as CSV

func _input(event):
	if event.is_action_pressed('ui_next'):
		slides.display(slides.NEXT)
		update_translations()
	if event.is_action_pressed('ui_previous'):
		slides.display(slides.PREVIOUS)
		update_translations()
	if LANGUAGE_MAIN == LANGUAGE_SECOND:
		return
	if event.is_action_pressed('change_language'):
		if TranslationServer.get_locale() == LANGUAGE_MAIN:
			change_language(LANGUAGE_SECOND)
		else:
			change_language(LANGUAGE_MAIN)

func change_language(locale):
	TranslationServer.set_locale(locale)
	update_translations()

func update_translations():
	for node in get_tree().get_nodes_in_group("translate"):
		var node_uid = get_translation_uid(node)
		var translatable_properties = node.get_translation_data()
		for key in translatable_properties:
			var string_uid = node_uid + "_" + key
			node.set(key, tr(string_uid))
		if node.has_method('translate'):
			node.translate()

func get_translation_uid(node):
	return node.owner.name + "_" + str(node.owner.get_path_to(node)).replace("/", "_")

func _on_SwipeDetector_swiped(direction):
	if direction.x == 1:
		slides.display(slides.NEXT)
	if direction.x == -1:
		slides.display(slides.PREVIOUS)

func _on_TouchControls_slide_change_requested(direction):
	slides.display(direction)

func get_translatable_strings():
	"""
	Returns a dictionary with a list of { translatable_string_uid: string }
	and the version of the project in which the data was generated
	"""
	var data = []
	for node in get_tree().get_nodes_in_group("translate"):
		var src_data = node.get_translation_data()
		var node_uid = get_translation_uid(node)
		for key in src_data:
			var string_uid = node_uid + "_" + key
			data.append({ string_uid: src_data[key] })
	return {
			'data': data,
			'version': ProjectSettings.get_setting("application/config/version"),
		}

func save_as_csv(translation_data):
	"""
	Saves translation data from get_translatable_strings() to
	this scene's folder, as scene_name.csv
	"""
	var folder_path = filename.left(filename.rfind("/") + 1)
	var save_path = folder_path + name + ".csv"
	var file = File.new()
	
	file.open(save_path, File.WRITE)
	if not file.is_open():
		print("Error saving translation data: could not open file %s" % save_path)
		return

	file.store_line("id,en")
	var data_list = translation_data['data']
	var csv_list = []
	for dict in data_list:
		for key in dict:
			var as_csv = key + "," +  "\"" + dict[key] + "\""
			csv_list.append(as_csv)
	for line in csv_list:
		file.store_line(line)
	file.close()
