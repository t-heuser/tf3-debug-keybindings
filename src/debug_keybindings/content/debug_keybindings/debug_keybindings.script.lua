-- Lists the engine's debug input actions (IA_DEBUG_*, IA_GAME_DEBUG_*) in the key bindings of the settings page,
-- so they can be rebound like any other action. The engine gives them no uiCategory, and settings_page.tl skips
-- actions without one (and draws only its fixed list of categories), so they are put into "game".
--
-- Done by wrapping app.getInputActionRep, whose only caller is the settings page. Rebinding goes through the
-- settings page's own key listener, conflict dialog and saving (settings_keys_v3.lua), so a new binding stays
-- when the mod is removed. The key listener records what the game actually receives, e.g. Ctrl + Right Alt for
-- AltGr under Proton/Wine.

local react = ug_require "::/gui/main/react.lua"
local builtin = ug_require "::/gui/main/builtin.lua"

local LOG = "[debug_keybindings] "
local CATEGORY = "game"
local ORDER = 100000  -- after the game's own entries

-- IA_GAME_DEBUG_TOGGLE_DEBUG_WINDOW -> "Debug: toggle debug window" (the engine has no display names for them)
local function displayName(ia)
	local rest = ia:gsub("^IA_GAME_DEBUG_", ""):gsub("^IA_DEBUG_", ""):gsub("_", " "):lower()
	return "Debug: " .. rest
end

local function install()
	local orig = app.getInputActionRep
	local rep = orig()
	-- the key listener reads appConfig.keyCmdDefinitions[ia], so only actions present there are listed
	local defs = api.util.getAppConfig().keyCmdDefinitions
	local debugActions = {}
	for _, ia in ipairs(rep:getAll()) do
		if ia:find("DEBUG", 1, true) and defs[ia] ~= nil and rep:get(ia).uiCategory == "" then
			debugActions[#debugActions + 1] = ia
		end
	end
	table.sort(debugActions)
	local order = {}
	for i, ia in ipairs(debugActions) do order[ia] = ORDER + i end

	app.getInputActionRep = function()
		local r = orig()
		return {
			getAll = function(_) return r:getAll() end,
			get = function(_, ia)
				local d = r:get(ia)
				if order[ia] == nil then return d end
				return {
					uiName = (d.uiName ~= nil and d.uiName ~= "") and d.uiName or displayName(ia),
					uiCategory = CATEGORY,
					uiOrder = order[ia],
					type = d.type,
					defaultBindings = d.defaultBindings,
					modifierOnly = d.modifierOnly,
					duplicateOf = d.duplicateOf,
					duplicatedKeybindings = d.duplicatedKeybindings,
				}
			end,
		}
	end
	print(LOG .. #debugActions .. " debug actions listed in the key bindings (" .. CATEGORY .. ")")
end

local installed = false
local DebugKeybindingsInstaller = react.RegisterRecipe("DebugKeybindingsInstaller", function()
	react.onMount(function()
		if installed then return end
		installed = true
		local ok, err = pcall(install)
		if not ok then print(LOG .. "failed: " .. tostring(err)) end
	end)
	return builtin.BoxLayout {}  -- a recipe must return a layout ("Recipe child must be a layout")
end)

-- .script.lua resources expose their exports through data(), not a return value
function data()
	return { DebugKeybindingsInstaller = DebugKeybindingsInstaller }
end
