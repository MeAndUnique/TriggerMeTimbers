--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local bInitialized = false;

function onInit()
	actions.onEntryAdded = onActionAdded;
	bInitialized = true;
	onEventChanged();
	update();
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

	events.setReadOnly(bReadOnly);
	for _,winEvent in ipairs(events.getWindows()) do
		winEvent.update(bReadOnly);
	end

	actions.setReadOnly(bReadOnly);
	for _,winAction in ipairs(actions.getWindows()) do
		winAction.update(bReadOnly);
	end
end

function onEventChanged()
	if not bInitialized then
		return;
	end

	local aEvents = getEvents();
	for _,winAction in ipairs(actions.getWindows()) do
		winAction.updateEvents(aEvents);
	end
end

function getEvents()
	local aEvents = {};
	for _,winEvent in ipairs(events.getWindows()) do
		table.insert(aEvents, winEvent.getEventName());
	end
	return aEvents;
end

function onActionAdded(winAction)
	local aEvents = getEvents();
	winAction.updateEvents(aEvents);
end