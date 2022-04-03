-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local node;
local bUpdating = false;

function onInit()
	self.onSelect = onValueSelected;
	node = window.getDatabaseNode().createChild(getName(), "string");
	DB.addHandler(node.getPath(), "onUpdate", onNodeUpdate);
end

function configure(rParameterInfo, aEventParameters)
	for _,vDefinition in ipairs(rParameterInfo.aDefinedValues) do
		if type(vDefinition) == "string" then
			add(vDefinition, Interface.getString(vDefinition));
		else
			if TriggerManager.hasRequiredParameters(vDefinition.aRequiredParameters or {}, aEventParameters) then
				add(vDefinition.sValue, Interface.getString(vDefinition.sValue));
			end
		end
	end
	setComboValue(node.getValue());
end

function onClose()
	DB.removeHandler(node.getPath(), "onUpdate", onNodeUpdate);
end

function onValueSelected()
	bUpdating = true;
	-- combobox defaults to display value, not data value
	DB.setValue(node.getPath(), "string", getSelectedValue());
	bUpdating = false;
end

function onNodeUpdate()
	setComboValue(node.getValue());
end

function setComboValue(sValue)
	if not bUpdating then
		if (sValue or "") == "" then
			setListIndex(1);
			sValue = getSelectedValue();
			DB.setValue(node.getPath(), "string", sValue);
		elseif hasValue(sValue) then
			-- It would be nice if comboboxes had full support for key/value pair data.
			setListValue(Interface.getString(sValue)); -- TODO interface alternative.
		else
			setListValue(string.format(Interface.getString("unknown_parameter_error"), sValue));
		end
	end
end