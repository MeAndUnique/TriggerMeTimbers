-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rConditionData = {};
local aEventParameters;

function onInit()
	conditionname.onSelect = onConditionNameSelected;
	parameters.onFilter = onFilterParameters;
	DB.addHandler(getDatabaseNode().getPath("conditionname"), "onUpdate", onConditionNameChanged);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("conditionname"), "onUpdate", onConditionNameChanged);
end

function update(bReadOnly)
	conditionname.setComboBoxReadOnly(bReadOnly);
	for _,winParameter in ipairs(parameters.getWindows()) do
		winParameter.update(bReadOnly);
	end
end

function setEventName(sEventName)
	aEventParameters = TriggerManager.getParametersForEvent(sEventName)
	for _,rConditionDefinition in pairs(TriggerManager.getConditionDefinitionsForEventParameters(aEventParameters)) do
		conditionname.add(rConditionDefinition.sName, Interface.getString(rConditionDefinition.sName));
	end

	local sConditionName = DB.getValue(getDatabaseNode(), "conditionname");
	setConditionName(sConditionName);
end

function onConditionNameChanged(nodeConditionName)
	setConditionName(nodeConditionName.getValue());
end

function onConditionNameSelected(sSelection)
	bUpdatingName = true;
	-- combobox defaults to display value, not data value
	DB.setValue(getDatabaseNode(), "conditionname", "string", conditionname.getSelectedValue());
	bUpdatingName = false;
end

function setConditionName(sConditionName)
	if not bUpdatingName then
		if (sConditionName or "") == "" then
			conditionname.setListIndex(1);
			sConditionName = conditionname.getSelectedValue();
			DB.setValue(getDatabaseNode(), "eventname", "string", sConditionName);
		elseif conditionname.hasValue(sConditionName) then
			-- It would be nice if comboboxes had full support for key/value pair data.
			conditionname.setListValue(Interface.getString(sConditionName));
		else
			-- TODO handle known condition unavailable for event
			conditionname.setListValue(string.format(Interface.getString("unknown_condition_error"), sConditionName));
		end
	end

	rebuildParameters(sConditionName);
end

function rebuildParameters(sConditionName)
	clearParameters();
	buildParameters(sConditionName);
end

function clearParameters()
	rConditionData = {};
	DB.deleteChild(getDatabaseNode(), "parameters");
end

function buildParameters(sConditionName)
	local rCondition = TriggerManager.getConditionDefinition(sConditionName);
	if not rCondition then
		return;
	end

	local nodeParameters = DB.createChild(getDatabaseNode(), "parameters");
	for _,rParameterInfo in ipairs(rCondition.aConfigurableParameters or {}) do
		local nodeParameter = nodeParameters.createChild();
		local winParameter = parameters.createWindowWithClass("trigger_parameter_" .. rParameterInfo.sType, nodeParameter);
		winParameter.configure(rParameterInfo, aEventParameters);
	end

	onParameterChanged();
end

function onParameterChanged()
	for _,winParameter in pairs(parameters.getWindows()) do
		local sParameterName, vValue = winParameter.getNameAndValue();
		rConditionData[sParameterName] = vValue;
	end
	parameters.applyFilter();
end

function onFilterParameters(winParameter)
	return winParameter.shouldBeVisible(rConditionData);
end