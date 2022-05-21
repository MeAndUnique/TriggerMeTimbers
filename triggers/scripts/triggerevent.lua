--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local bUpdatingName = false;

function onInit()
	initializeEventList();
	conditions.onEntryAdded = onConditionAdded;
	DB.addHandler(getDatabaseNode().getPath("eventname"), "onUpdate", onEventNameChanged);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("eventname"), "onUpdate", onEventNameChanged);
end

function update(bReadOnly)
	eventname.setComboBoxReadOnly(bReadOnly);
	if bReadOnly then
		if conditions_iedit then
			conditions_iedit.setValue(0);
			conditions_iedit.setVisible(false);
			conditions_iadd.setVisible(false);
		end
	else
		if conditions_iedit then
			conditions_iedit.setVisible(true);
			conditions_iadd.setVisible(true);
		end
	end

	conditions.setReadOnly(bReadOnly);
	for _,winCondition in ipairs(conditions.getWindows()) do
		winCondition.update(bReadOnly);
	end
end

function getEventName()
	return eventname.getSelectedValue();
end

function initializeEventList()
	for _,rEvent in pairs(TriggerManager.getEventDefinitions()) do
		eventname.add(rEvent.sName, Interface.getString(rEvent.sName));
		eventname.addTooltip(rEvent.sName, Interface.getString(rEvent.sDescription))
	end

	local sEventName = DB.getValue(getDatabaseNode(), "eventname");
	setEventName(sEventName);

	eventname.onSelect = onEventNameSelected;
end

function onConditionAdded(winCondition)
	winCondition.setEventName(getEventName());
end

function onEventNameChanged(nodeEventName)
	setEventName(nodeEventName.getValue());
end

function setEventName(sEventName)
	if not bUpdatingName then
		if (sEventName or "") == "" then
			eventname.setListIndex(1);
			sEventName = getEventName();
			DB.setValue(getDatabaseNode(), "eventname", "string", sEventName);
		elseif eventname.hasValue(sEventName) then
			-- It would be nice if comboboxes had full support for key/value pair data.
			eventname.setListValue(Interface.getString(sEventName));
		else
			eventname.setListValue(string.format(Interface.getString("unknown_event_error"), sEventName));
		end
	end

	for _,winCondition in ipairs(conditions.getWindows()) do
		winCondition.setEventName(sEventName);
	end
	windowlist.window.onEventChanged();
end

function onEventNameSelected()
	bUpdatingName = true;
	-- combobox defaults to display value, not data value
	DB.setValue(getDatabaseNode(), "eventname", "string", getEventName());
	refreshConditions();
	refreshTrigger();
	bUpdatingName = false;
end

function refreshConditions()
	-- TODO check for conditions that are no longer applicable to the selected event
end

function refreshTrigger()
	-- TODO ensure that the TriggerManager has an up to date trigger
	-- potentially this might be best handled by having the manager itself add DB handlers
end