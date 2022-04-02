-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aParameterControls = {};

function onInit()
	actionname.onSelect = onActionNameSelected;
	DB.addHandler(getDatabaseNode().getPath("actionname"), "onUpdate", onActionNameChanged);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("actionname"), "onUpdate", onActionNameChanged);
end

function update(bReadOnly)
	actionname.setComboBoxReadOnly(bReadOnly);
	for _,rControlInfo in ipairs(aParameterControls) do
		rControlInfo.control.setReadOnly(bReadOnly);
	end
end

function updateEvents(aEventNames)
	for _,rActionDefinition in pairs(TriggerManager.getActionDefinitionsForEvents(aEventNames)) do
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
		if sActionName == nil then
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
		actionname_cblist.bringToFront();
		actionname_cblistscroll.bringToFront();
	end
end

function clearParameters()
	for _,controls in ipairs(aParameterControls) do
		controls.label.destroy();
		controls.field.destroy();
	end
	aParameterControls = {};

	DB.deleteChild(getDatabaseNode(), "parameters");
end

function buildParameters(sActionName)
	local rAction = TriggerManager.getActionDefinition(sActionName);
	if not rAction then
		return;
	end

	local nodeParameters = DB.createChild(getDatabaseNode(), "parameters");
	for sParameterName,rParameterInfo in pairs(rAction.tConfigurableParameters or {}) do
		local label = createControl("label_triggerparameter", "label_" .. sParameterName);
		local field = createControl("triggerparameter_" .. rParameterInfo.sType, sParameterName, "parameters." .. sParameterName);
		label.setValue(Interface.getString(rParameterInfo.sName));
		if field.configure then
			field.configure(rParameterInfo)
		end
		table.insert(aParameterControls, {field = field, label = label});
	end
end