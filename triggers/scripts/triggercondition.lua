-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aParameterControls = {};

function onInit()
	conditionname.onSelect = onConditionNameSelected;
	DB.addHandler(getDatabaseNode().getPath("conditionname"), "onUpdate", onConditionNameChanged);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("conditionname"), "onUpdate", onConditionNameChanged);
end

function update(bReadOnly)
	conditionname.setComboBoxReadOnly(bReadOnly);
	for _,rControlInfo in ipairs(aParameterControls) do
		rControlInfo.control.setReadOnly(bReadOnly);
	end
end

function setEventName(sEventName)
	for _,rConditionDefinition in pairs(TriggerManager.getConditionDefinitionsForEvent(sEventName)) do
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
		if sConditionName == nil then
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

	-- The combobox list is lazily created, after which point new parameteres would be drawn overtop.
	if conditionname_cblist then
		conditionname_cblist.bringToFront();
		conditionname_cblistscroll.bringToFront();
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

function buildParameters(sConditionName)
	local rCondition = TriggerManager.getConditionDefinition(sConditionName);
	if not rCondition then
		return;
	end

	local nodeParameters = DB.createChild(getDatabaseNode(), "parameters");
	for sParameterName,rParameterInfo in pairs(rCondition.tConfigurableParameters or {}) do
		local label = createControl("label_triggerparameter", "label_" .. sParameterName);
		local field = createControl("triggerparameter_" .. rParameterInfo.sType, sParameterName, "parameters." .. sParameterName);
		label.setValue(Interface.getString(rParameterInfo.sName));
		if field.configure then
			field.configure(rParameterInfo)
		end
		table.insert(aParameterControls, {field = field, label = label});
	end
end