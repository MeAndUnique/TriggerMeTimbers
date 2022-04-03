-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local tParameterControls = {};
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
	for _,rControlInfo in pairs(tParameterControls) do
		rControlInfo.field.setReadOnly(bReadOnly);
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

	-- The combobox list is lazily created, after which point new parameteres would be drawn overtop.
	if conditionname_cblist then
		conditionname.bringToFront();
		conditionname_cbbutton.bringToFront();
		conditionname_cblist.bringToFront();
		conditionname_cblistscroll.bringToFront();
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

function buildParameters(sConditionName)
	-- TODO include parameters based on available event parameters
	local rCondition = TriggerManager.getConditionDefinition(sConditionName);
	if not rCondition then
		return;
	end

	local nodeParameters = DB.createChild(getDatabaseNode(), "parameters");
	for _,rParameterInfo in ipairs(rCondition.aConfigurableParameters or {}) do
		local label = createControl("label_triggerparameter", "label_" .. rParameterInfo.sName);
		local field = createControl("triggerparameter_" .. rParameterInfo.sType, rParameterInfo.sName, "parameters." .. rParameterInfo.sName);
		label.setValue(Interface.getString(rParameterInfo.sDisplay));
		if field.configure then
			field.configure(rParameterInfo, aEventParameters);
		end
		field.onValueChanged = onParameterChanged;
		tParameterControls[rParameterInfo.sName] = {field = field, label = label, rParameterInfo = rParameterInfo};
	end

	onParameterChanged();
end

function onParameterChanged()
	local rConditionData = {};
	for sParameterName,controls in pairs(tParameterControls) do
		if controls.field.getSelectedValue then
			rConditionData[sParameterName] = controls.field.getSelectedValue();
		else
			rConditionData[sParameterName] = controls.field.getValue();
		end
	end
	for _,controls in pairs(tParameterControls) do
		if controls.rParameterInfo.fCheckVisibility then
			controls.label.setVisible(controls.rParameterInfo.fCheckVisibility(rConditionData));
			controls.field.setVisible(controls.rParameterInfo.fCheckVisibility(rConditionData));
		end
	end
end