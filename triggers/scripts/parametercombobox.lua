-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local node;
local bUpdating = false;

function onInit()
	super.onInit();
	self.onSelect = onValueSelected;
	node = window.getDatabaseNode().createChild(getName(), "string");
	DB.addHandler(node.getPath(), "onUpdate", onNodeUpdate);
end

function configure(rParameterInfo, aEventParameters)
	for _,vDefinition in ipairs(rParameterInfo.aDefinedValues) do
		if type(vDefinition) == "string" then
			addValue(vDefinition);
		else
			if TriggerManager.hasRequiredParameters(vDefinition.aRequiredParameters or {}, aEventParameters) then
				addValue(vDefinition.sValue);
			end
		end
	end
	Debug.chat("configure", rParameterInfo, aEventParameters, node.getValue());
	setComboValue(node.getValue());
end

function addValue(sValue)
	-- TODO potentially add parameter info to be explicit about intent
	local sResource = Interface.getString(sValue);
	if sResource == "" then
		sResource = nil;
	end
	add(sValue, sResource);
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
			for nIndex,sKnownValue in ipairs(getValues()) do
				if sValue == sKnownValue then
					setListIndex(nIndex);
				end
			end
		else
			setListValue(string.format(Interface.getString("unknown_parameter_error"), sValue));
		end
	end
end