-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

rCreatureHasTraitCondition = nil;

function onInit()
	initializeConditions();
end

function initializeConditions()
	rCreatureHasTraitCondition = {
		sName = "source_has_trait_condition",
		fCondition = sourceHasTraitCondition,
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