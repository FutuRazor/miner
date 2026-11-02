# Game translations

The game uses Godot's built-in `TranslationServer` and gettext PO catalogs.
English is the default language; English and German are selectable. The original German messages
serve as stable translation keys; gameplay IDs, scene paths and save-data keys
must never be translated.

## Update the catalogs

```sh
python tools/update_translations.py
python tools/update_translations.py --check
python tools/check_translations.py
```

This updates `de.po` and `messages.pot`, including source references. It never
overwrites another language's translations. The extractor covers `tr()` calls,
skill metadata, building names, tutorial objectives and scene text properties.
The checker verifies complete message coverage, placeholders and line breaks in
every shipped language catalog.

Translate **before** substituting values:

```gdscript
label.text = tr("Basis: %d Geld") % money
```

Keep format placeholders (`%d`, `%s`, `%%`) and line breaks compatible with the
original. Names and descriptions in constant dictionaries are translated at the
UI boundary. Scene text uses Godot's automatic Control translation.

## Add another language

1. Copy `messages.pot` to a new locale's `.po` file, set its `Language` header,
   and fill every `msgstr`. Translators can use a gettext-compatible editor.
2. Add the new `.po` file to the translation resources in `project.godot`.
3. Add its locale to `SUPPORTED_LANGUAGES` and its native display name to
   `LANGUAGE_NAMES` in `scripts/localization.gd`.
4. `DEFAULT_LANGUAGE` controls the default for new installations. Saved user
   choices continue to take precedence.
5. Import the catalogs in Godot and test menus, tutorial messages, formatted HUD
   values, text lengths and keyboard navigation in every supported language.

The language choice is stored separately from gameplay statistics in
`user://settings.cfg`, under `[interface] language`. Missing, unreadable or
unsupported settings fall back to English. English is also the translation
fallback. German remains the source-key language; neither source strings nor
existing save data need to be renamed when switching languages.
