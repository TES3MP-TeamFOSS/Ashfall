# BabelFish

An experimental translation module to send and receive messages in a preferred language using the [BabelFish Google translate API in nodeJS](../../web/BabelFish).

## Configuration

```Lua
config.url = "http://localhost:8000/"
```
The following settings can be used to integrate BabelFish into your own module. But you have to make sure that the BabelFish module is loaded first. The translated string is stored in the global Data table: `Data.BabelFishMessage`.
```Lua
config.forceSpecificTranslation = false
config.forcedLanguage = "en"
```

## Screenshots

### English
[![English](screenshots/screenshot-english-tn.jpg)](screenshots/screenshot-english.jpg?raw=true "English")

### French
[![French](screenshots/screenshot-french-tn.jpg)](screenshots/screenshot-french.jpg?raw=true "French")

### German
[![German](screenshots/screenshot-german-tn.jpg)](screenshots/screenshot-german.jpg?raw=true "German")
