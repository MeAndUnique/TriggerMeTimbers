-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;

function onInit()
	actions.onEntryAdded = onActionAdded;
	bInitialized = true;
	-- onEventChanged();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	
	if bReadOnly then
		if events_iedit then
			events_iedit.setValue(0);
			events_iedit.setVisible(false);
			events_iadd.setVisible(false);
		end
		if actions_iedit then
			actions_iedit.setValue(0);
			actions_iedit.setVisible(false);
			actions_iadd.setVisible(false);
		end
	else
		if events_iedit then
			events_iedit.setVisible(true);
			events_iadd.setVisible(true);
		end
		if actions_iedit then
			actions_iedit.setVisible(true);
			actions_iadd.setVisible(true);
		end
	end
end

function onEventChanged()
	if not bInitialized then
		return;
	end

	aEvents = getEvents();
	for _,winAction in ipairs(actions.getWindows()) do
		winAction.updateEvents(aEvents);
	end
end

function getEvents()
	aEvents = {};
	for _,winEvent in ipairs(events.getWindows()) do
		table.insert(aEvents, winEvent.getEventName());
	end
	return aEvents;
end

function onActionAdded(winAction)
	aEvents = getEvents();
	winAction.updateEvents(aEvents);
end