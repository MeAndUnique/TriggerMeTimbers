-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local tParameterControls = {};
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
	for _,rControlInfo in pairs(tParameterControls) do
		rControlInfo.field.setReadOnly(bReadOnly);
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

	-- The combobox list is lazily created, after which point new parameteres would be drawn overtop.
	if actionname_cblist then
		actionname.bringToFront();
		actionname_cbbutton.bringToFront();
		actionname_cblist.bringToFront();
		actionname_cblistscroll.bringToFront();
	end
end

function clearParameters()
	for _,controls in pairs(tParameterControls) do
		controls.label.destroy();
		controls.field.destroy();
	end
	tParameterControls = {};

	DB.deleteChild(getDatabaseNode(), "parameters");
end

function buildParameters(sActionName)
	-- TODO include parameters based on available event parameters
	local rAction = TriggerManager.getActionDefinition(sActionName);
	if not rAction then
		return;
	end

	local nodeParameters = DB.createChild(getDatabaseNode(), "parameters");
	for _,rParameterInfo in ipairs(rAction.aConfigurableParameters or {}) do
		local label = createControl("label_triggerparameter", "label_" .. rParameterInfo.sName);
		local field = createControl("triggerparameter_" .. rParameterInfo.sType, rParameterInfo.sName, "parameters." .. rParameterInfo.sName);
		label.setValue(Interface.getString(rParameterInfo.sDisplay));
		if field.configure then
			field.configure(rParameterInfo, aEventParameters)
		end
		field.onValueChanged = onParameterChanged;
		tParameterControls[rParameterInfo.sName] = {field = field, label = label, rParameterInfo = rParameterInfo};
	end
end

function onParameterChanged()
	local rActionData = {};
	for sParameterName,controls in pairs(tParameterControls) do
		if controls.field.getSelectedValue then
			rActionData[sParameterName] = controls.field.getSelectedValue();
		else
			rActionData[sParameterName] = controls.field.getValue();
		end
	end
	for _,controls in pairs(tParameterControls) do
		if controls.rParameterInfo.fCheckVisibility then
			controls.label.setVisible(controls.rParameterInfo.fCheckVisibility(rActionData));
			controls.field.setVisible(controls.rParameterInfo.fCheckVisibility(rActionData));
		end
	end
end