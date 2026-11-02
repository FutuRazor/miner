extends Node

signal language_changed(locale: String)

# Add a locale here only after its translation has been completed and tested.
# Changing DEFAULT_LANGUAGE later affects new installations, not saved choices.
const DEFAULT_LANGUAGE := "en"
const SUPPORTED_LANGUAGES := ["en", "de"]
const LANGUAGE_NAMES := {"de": "Deutsch", "en": "English"}
var language := DEFAULT_LANGUAGE
var storage_path := "user://settings.cfg"
var persistence_enabled := true
var save_error := OK

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var settings := ConfigFile.new()
	var selected := DEFAULT_LANGUAGE
	if settings.load(storage_path) == OK:
		selected = str(settings.get_value("interface", "language", DEFAULT_LANGUAGE))
	language = selected if SUPPORTED_LANGUAGES.has(selected) else DEFAULT_LANGUAGE
	TranslationServer.set_locale(language)
	language_changed.emit(language)

func set_language(locale: String) -> bool:
	if not SUPPORTED_LANGUAGES.has(locale):
		return false
	language = locale
	TranslationServer.set_locale(language)
	language_changed.emit(language)
	save_error = OK
	if persistence_enabled:
		var settings := ConfigFile.new()
		# Preserve future options stored in this same file.
		settings.load(storage_path)
		settings.set_value("interface", "language", language)
		save_error = settings.save(storage_path)
	return save_error == OK
