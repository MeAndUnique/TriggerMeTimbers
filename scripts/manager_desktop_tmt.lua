--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		DesktopManager.registerSidebarToolButton({
			tooltipres = "sidebar_tooltip_active_triggers",
			class = "masterindex",
			path = "activetrigger",
			sIcon = "active_trigger",
		});
	end
end