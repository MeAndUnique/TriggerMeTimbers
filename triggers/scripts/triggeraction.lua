-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local rActionData = {};
local aEventParameters;

function onInit()
	actionname.onSelect = onActionNameSelected;
	DB.addHandler(getDatabaseNode().getPath("actionname"), "onUpdate", onActionNameChanged);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("actionname"), "onUpdate", onActionNameChanged);
end

function update(bReadOnly)
	actionname.setComboBoxReadOnly(bReadOnly);
	for _,winParameter in ipairs(parameters.getWindows()) do
		winParameter.update(bReadOnly);
	end
end

function updateEvents(aEventNames)
	aEventParameters = TriggerManager.getCommonParametersForEvents(aEventNames);
	for _,rActionDefinition in pairs(TriggerManager.getActionDefinitionsForCommonEventParameters(aEventParameters)) do
		actionname.add(rActionDefinition.sName, Interface.getString(rActionDefinition.sName));
	end

	local sActionName = DB.getValue(getDatabaseNode(), "actionname");
	setActionName(sActionName);
end

function onActionNameChanged(nodeActionName)
	setActionName(nodeActionName.getValue());
end

function onActionNameSelected(sSelection)
	bUpdatingName = true;
	-- combobox defaults to display value, not data value
	DB.setValue(getDatabaseNode(), "actionname", "string", actionname.getSelectedValue());
	bUpdatingName = false;
end

function setActionName(sActionName)
	if not bUpdatingName then
		if (sActionName or "") == "" then
			actionname.setListIndex(1);
			sActionName = actionname.getSelectedValue();
			DB.setValue(getDatabaseNode(), "eventname", "string", sActionName);
		elseif actionname.hasValue(sActionName) then
			-- It would be nice if comboboxes had full support for key/value pair data.
			actionname.setListValue(Interface.getString(sActionName));
		else
			-- TODO handle known action unavailable for event
			actionname.setListValue(string.format(Interface.getString("unknown_action_error"), sActionName));
		end
	end

	rebuildParameters(sActionName);
end

function rebuildParameters(sActionName)
	clearParameters();
	buildParameters(sActionName);
end

function clearParameters()
	rActionData = {};
	DB.deleteChild(getDatabaseNode(), "parameters");
end

function buildParameters(sActionName)
	local rAction = TriggerManager.getActionDefinition(sActionName);
	if not rAction then
		return;
	end

	local nodeParameters = DB.createChild(getDatabaseNode(), "parameters");
	for _,rParameterInfo in ipairs(rAction.aConfigurableParameters or {}) do
		local nodeParameter = nodeParameters.createChild();
		local winParameter = parameters.createWindowWithClass("trigger_parameter_" .. rParameterInfo.sType, nodeParameter);
		winParameter.configure(rParameterInfo, aEventParameters);
	end

	onParameterChanged();
end

function onParameterChanged()
	for _,winParameter in pairs(parameters.getWindows()) do
		local sParameterName, vValue = winParameter.getNameAndValue();
		rActionData[sParameterName] = vValue;
	end
	parameters.applyFilter();
end

function onFilterParameters(winParameter)
	return winParameter.shouldBeVisible(rActionData);
end