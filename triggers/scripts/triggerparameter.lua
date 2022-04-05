-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rParameterInfo;
local aEventParameters;

function update(bReadOnly)
	-- TODO consider making a window script for comboboxed parameters
	if value.setComboBoxReadOnly then
		value.setComboBoxReadOnly(bReadOnly);
	else
		value.setReadOnly(bReadOnly);
	end
end

function configure(rNewParameterInfo, sNewEventParameters)
	rParameterInfo = rNewParameterInfo;
	aEventParameters = sNewEventParameters;
	label.setValue(Interface.getString(rParameterInfo.sDisplay));
	if value.configure then
		value.configure(rParameterInfo, aEventParameters);
	end
	value.onValueChanged = windowlist.window.onParameterChanged;
end

function getNameAndValue()
	local vValue;
	if value.getSelectedValue then
		vValue = value.getSelectedValue();
	else
		vValue = value.getValue();
	end
	return rParameterInfo.sName, vValue;
end

function shouldBeVisible(rConditionData)
	return (rParameterInfo.fCheckVisibility == nil) or rParameterInfo.fCheckVisibility(rConditionData);
end