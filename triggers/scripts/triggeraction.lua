--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
local bUpdatingName = false;
local aEventParameters;

function onInit()
	actionname.onSelect = onActionNameSelected;
	conditions.onEntryAdded = onConditionAdded;
	DB.addHandler(getDatabaseNode().getPath("actionname"), "onUpdate", onActionNameChanged);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("actionname"), "onUpdate", onActionNameChanged);
end

function update(bReadOnly)
	actionname.setComboBoxReadOnly(bReadOnly);
	parameters.update(bReadOnly);

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

function getActionName()
	return actionname.getSelectedValue();
end

function updateEvents(aEventNames)
	aEventParameters = TriggerManager.getCommonParametersForEvents(aEventNames);
	for _,rActionDefinition in pairs(TriggerManager.getActionDefinitionsForCommonEventParameters(aEventParameters)) do
		actionname.add(rActionDefinition.sName, Interface.getString(rActionDefinition.sName));
		actionname.addTooltip(rActionDefinition.sName, Interface.getString(rActionDefinition.sDescription));
	end

	local sActionName = DB.getValue(getDatabaseNode(), "actionname");
	setActionName(sActionName, false);
end

function onConditionAdded(winCondition)
	winCondition.setActionName(getActionName());
end

function onActionNameChanged(nodeActionName)
	setActionName(nodeActionName.getValue(), true);
end

function onActionNameSelected()
	bUpdatingName = true;
	DB.deleteChild(getDatabaseNode(), "parameters");
	-- combobox defaults to display value, not data value
	DB.setValue(getDatabaseNode(), "actionname", "string", getActionName());
	bUpdatingName = false;
end

function setActionName(sActionName, bRebuild)
	if not bUpdatingName then
		if (sActionName or "") == "" then
			actionname.setListIndex(1);
			sActionName = getActionName();
			DB.setValue(getDatabaseNode(), "actionname", "string", sActionName);
		elseif actionname.hasValue(sActionName) then
			-- It would be nice if comboboxes had full support for key/value pair data.
			actionname.setListValue(Interface.getString(sActionName));
		else
			-- TODO handle known action unavailable for event
			actionname.setListValue(string.format(Interface.getString("unknown_action_error"), sActionName));
		end
	end

	rebuildParameters(sActionName, bRebuild);

	for _,winCondition in ipairs(conditions.getWindows()) do
		winCondition.setActionName(sActionName);
	end
end

function rebuildParameters(sActionName, bRebuild)
	local rAction = TriggerManager.getActionDefinition(sActionName);
	if not rAction then
		return;
	end

	parameters.initializeParameters(rAction.aConfigurableParameters, aEventParameters, bRebuild);
end