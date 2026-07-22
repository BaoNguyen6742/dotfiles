local appearances = require("core.appearances")
local functional = require("core.functional")
local profiles = require("core.profiles")
local keymaps = require("core.keymaps")
local config = {}

appearances.apply_to_config(config)
functional.apply_to_config(config)
profiles.apply_to_config(config)
keymaps.apply_to_config(config)

print(config.launch_manu)


return config