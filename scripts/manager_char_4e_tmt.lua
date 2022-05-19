--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

rPowerContainsDataCondition = nil;
rPowerUsedEvent = {
	sName = "power_used_event",
	aParameters = {
		"rSource",
		"rPower"
	};
};

function onInit()
	TriggerManager.defineEvent(rPowerUsedEvent);
	initializeConditions();
end

function initializeConditions()
	rPowerContainsDataCondition = {
		sName = "power_used_contains_data",
		fCondition  = powerContainsDataCondition,
		aRequiredParameters = {
			"rSource",
			"rPower"
		},
		aConfigurableParameters = {
			{
				sName = "sPowerProperty",
				sDisplay = "power_used_property_parameter",
				sType = "combo",
				aDefinedValues = {
					"power_used_property_name",
					"power_used_property_keywords",
					"power_used_property_recharge",
					"power_used_property_action",
					"power_used_property_range",
				}
			},
			{
				sName = "sPowerContains",
				sDisplay = "power_used_contains_parameter",
				sType = "string"
			}
		}
	}

	TriggerManager.defineCondition(rPowerContainsDataCondition);
end

function powerContainsDataCondition(rTriggerData, rEventData)
	local sData = "";
	if rTriggerData.sPowerProperty == "power_used_property_name" then
		sData = rEventData.rPower.sName;
	elseif rTriggerData.sPowerProperty == "power_used_property_keywords" then
		sData = rEventData.rPower.sKeywords;
	elseif rTriggerData.sPowerProperty == "power_used_property_recharge" then
		sData = rEventData.rPower.sRecharge;
	elseif rTriggerData.sPowerProperty == "power_used_property_action" then
		sData = rEventData.rPower.sAction;
	elseif rTriggerData.sPowerProperty == "power_used_property_range" then
		sData = rEventData.rPower.sRange;
	end
	if string.find(sData:lower(), rTriggerData.sPowerContains:lower()) then
		return true;
	end
	return false;
end