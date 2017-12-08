# Localisation

A localisation or i18n module

## Example code

locales.json:
```JSON
{
  "en": {
    "greeting": "hello"
  },
  "de": {
    "greeting": "Hallo"
  },
  "fr": {
    "greeting": "Bonjour"
  },
  "ru": {
    "greeting": "привет"
  }
}
```

moduleInfo.json:
```JSON
{
    "name": "HelloWorld",
    "author": "John Doe",
    "version": "0.0.1",
    "dependencies": {
        "Core": ">=0.0.1",
        "Localisation": ">=0.0.1"
    }
}
```

main.lua
```Lua
JsonInterface = require("jsonInterface")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")

Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   player:message(Data._(player, locales, "greeting"), false)
                   return true
end)
```
