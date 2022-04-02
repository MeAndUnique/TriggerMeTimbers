-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DesktopManager.registerSidebarToolButton({
		tooltipres = "sidebar_tooltip_triggers",
		class = "triggers", -- TODO or "triggers"
		path = "activetriggers",
	});
end