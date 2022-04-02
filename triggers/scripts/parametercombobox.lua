-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local node;
local bUpdating = false;

function onInit()
	self.onSelect = onValueSelected;
	node = window.getDatabaseNode().getChild(getName());
	DB.addHandler(node.getPath(), "onUpdate", onNodeUpdate);
end

function configure(rParameterInfo)
	for _,sDefinition in ipairs(rParameterInfo.aDefinedValues) do
		add(sDefinition, Interface.getString(sDefinition));
	end
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
	if not bUpdatingName then
		if sValue == nil then
			setListIndex(1);
			sValue = getSelectedValue();
			DB.setValue(node.getPath(), "string", sValue);
		elseif hasValue(sValue) then
			-- It would be nice if comboboxes had full support for key/value pair data.
			setListValue(Interface.getString(sValue)); -- TODO interface alternative.
		else
			conditionname.setListValue(string.format(Interface.getString("unknown_parameter_error"), sValue));
		end
	end
end