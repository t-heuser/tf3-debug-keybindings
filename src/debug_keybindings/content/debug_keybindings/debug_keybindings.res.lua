-- Mounts the (invisible) installer at the game UI root (gui/main/game.tl, ModEntryPointExtension).
function data()
	return {
		type = "react-plugin ::ModEntryPointExtension",
		data = {
			filePath = "debug_keybindings_1::/debug_keybindings/debug_keybindings.script@DebugKeybindingsInstaller",
			order = 0,
		},
	}
end
