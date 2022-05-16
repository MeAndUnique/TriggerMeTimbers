-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

rCreatureHasTraitCondition = nil;
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
	rCreatureHasTraitCondition = {
		sName = "creature_has_trait_condition",
		fCondition = creatureHasTraitCondition,
		aRequiredParameters = {},
		aConfigurableParameters = {
			{
				sName = "sCreature",
				sDisplay = "creature_parameter",
				sType = "combo",
				aDefinedValues = {
					{
						sValue = "source_subject",
						aRequiredParameters = {"rSource"}
					},
					{
						sValue = "target_subject",
						aRequiredParameters = {"rTarget"}
					},
				}
			},
			{
				sName = "sTraitName",
				sDisplay = "trait_name_parameter",
				sType = "string"
			},
			{
				sName="sType",
				sDisplay = "trait_type_parameter",
				sType = "combo",
				aDefinedValues = {
					"trait_type_all",
					"trait_type_feat",
					"trait_type_feature",
					"trait_type_trait",
				}
			},
		},
	};

	TriggerManager.defineCondition(rCreatureHasTraitCondition);

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
                    "power_used_property_level",
                    "power_used_property_school",
                    "power_used_property_castingtime",
					"power_used_property_components",
					"power_used_property_duration",
					"power_used_property_group",
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

function creatureHasTraitCondition(rTriggerData, rEventData)
	if rTriggerData.sCreature == "source_subject" then
		return hasTrait(rEventData.rSource, rTriggerData.sTraitName);
	elseif rTriggerData.sCreature == "target_subject" then
		return hasTrait(rEventData.rTarget, rTriggerData.sTraitName);
	end

	return false;
end

function hasTrait(rActor, sTrait)
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return false;
	end

	if sType == "pc" then
		if sType == "trait_feat" then
			return sType == CharManager.hasFeat(nodeActor, sTrait);
		elseif sType == "trait_feature" then
			return sType == CharManager.hasFeature(nodeActor, sTrait);
		elseif sType == "trait_trait" then
			return sType == CharManager.hasTrait(nodeActor, sTrait);
		else
			return CharManager.hasFeat(nodeActor, sTrait) or
				CharManager.hasFeature(nodeActor, sTrait) or
				CharManager.hasTrait(nodeActor, sTrait);
		end
	else
		local sTraitLower = StringManager.trim(sTrait):lower();
		for _,v in pairs(DB.getChildren(nodeActor, "traits")) do
			if StringManager.trim(DB.getValue(v, "name", "")):lower() == sTraitLower then
				return true;
			end
		end
		return false;
	end
end

function powerContainsDataCondition(rTriggerData, rEventData)
    -- If contain property is empty, return true
    if (rTriggerData.sPowerContains or "") == "" then
        return true;
    end

    local sData = "";
    if rTriggerData.sPowerProperty == "power_used_property_name" then
        sData = rEventData.rPower.sName;
    elseif rTriggerData.sPowerProperty == "power_used_property_level" then
        sData = tostring(rEventData.rPower.nLevel);
    elseif rTriggerData.sPowerProperty == "power_used_property_school" then
        sData = rEventData.rPower.sSchool;
    elseif rTriggerData.sPowerProperty == "power_used_property_castingtime" then
        sData = rEventData.rPower.sCastingTime;
	elseif rTriggerData.sPowerProperty == "power_used_property_components" then
		sData = rEventData.rPower.sComponents;
	elseif rTriggerData.sPowerProperty == "power_used_property_duration" then
		sData = rEventData.rPower.sDuration;
	elseif rTriggerData.sPowerProperty == "power_used_property_group" then
		sData = rEventData.rPower.sGroup;
    elseif rTriggerData.sPowerProperty == "power_used_property_range" then
        sData = rEventData.rPower.sRange;
    end
    if string.find(sData:lower(), rTriggerData.sPowerContains:lower()) then
        return true;
    end

    return false;
end