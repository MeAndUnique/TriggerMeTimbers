-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DesktopManager.registerSidebarToolButton({
		tooltipres = "sidebar_tooltip_triggers",
		class = "masterindex", -- TODO or "triggers"
		path = "activetrigger",
	});
end