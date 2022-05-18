-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rConditionData = {};
local aEventParameters;

function onInit()
	conditionname.onSelect = onConditionNameSelected;
	DB.addHandler(getDatabaseNode().getPath("conditionname"), "onUpdate", onConditionNameChanged);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("conditionname"), "onUpdate", onConditionNameChanged);
end

function update(bReadOnly)
	conditionname.setComboBoxReadOnly(bReadOnly);
	inverted.setReadOnly(bReadOnly);
	parameters.update(bReadOnly);
end

function setEventName(sEventName)
	aEventParameters = TriggerManager.getParametersForEvent(sEventName)
	for _,rConditionDefinition in pairs(TriggerManager.getConditionDefinitionsForEventParameters(aEventParameters)) do
		conditionname.add(rConditionDefinition.sName, Interface.getString(rConditionDefinition.sName));
		conditionname.addTooltip(rConditionDefinition.sName, Interface.getString(rConditionDefinition.sDescription));
	end

	local sConditionName = DB.getValue(getDatabaseNode(), "conditionname");
	setConditionName(sConditionName);
end

function onConditionNameChanged(nodeConditionName)
	setConditionName(nodeConditionName.getValue(), true);
end

function onConditionNameSelected(sSelection)
	bUpdatingName = true;
	-- combobox defaults to display value, not data value
	DB.setValue(getDatabaseNode(), "conditionname", "string", conditionname.getSelectedValue());
	bUpdatingName = false;
end

function setConditionName(sConditionName, bRebuild)
	if not bUpdatingName then
		if (sConditionName or "") == "" then
			conditionname.setListIndex(1);
			sConditionName = conditionname.getSelectedValue();
			DB.setValue(getDatabaseNode(), "conditionname", "string", sConditionName);
		elseif conditionname.hasValue(sConditionName) then
			-- It would be nice if comboboxes had full support for key/value pair data.
			conditionname.setListValue(Interface.getString(sConditionName));
		else
			-- TODO handle known condition unavailable for event
			conditionname.setListValue(string.format(Interface.getString("unknown_condition_error"), sConditionName));
		end
	end

	rebuildParameters(sConditionName, bRebuild);
end

function rebuildParameters(sConditionName, bRebuild)
	local rCondition = TriggerManager.getConditionDefinition(sConditionName);
	if not rCondition then
		return;
	end

	parameters.initializeParameters(rCondition.aConfigurableParameters, aEventParameters, bRebuild)
end