-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

rSourceHasEffectCondition = nil;
rTargetHasEffectCondition = nil;

rRemoveSourceEffectAction = nil;
rRemoveTargetEffectAction = nil;

function onInit()
	initializeConditions();
	initializeActions()
end

function initializeConditions()
	rSourceHasEffectCondition = {
		sName = "source_has_effect_condition",
		fCondition = sourceHasEffectCondition,
		aRequiredParameters = {"rSource"},
		tConfigurableParameters = {
			["sEffectName"] = {
				sName = "effect_name_parameter",
				sType = "string"
			},
		},
	};
	rTargetHasEffectCondition = {
		sName = "target_has_effect_condition",
		fCondition = targetHasEffectCondition,
		aRequiredParameters = {"rTarget"},
		tConfigurableParameters = {
			["sEffectName"] = {
				sName = "effect_name_parameter",
				sType = "string"
			},
		},
	};

	TriggerManager.defineCondition(rSourceHasEffectCondition);
	TriggerManager.defineCondition(rTargetHasEffectCondition);
end

function initializeActions()
	rRemoveSourceEffectAction = {
		sName = "remove_effect_from_source_action",
		fAction = removeSourceEffect,
		aRequiredParameters = {"rSource"},
		tConfigurableParameters = {
			["sEffectName"] = {
				sName = "effect_name_parameter",
				sType = "string"
			},
		},
	};
	rRemoveTargetEffectAction = {
		sName = "remove_effect_from_target_action",
		fAction = removeTargetEffect,
		aRequiredParameters = {"rTarget"},
		tConfigurableParameters = {
			["sEffectName"] = {
				sName = "effect_name_parameter",
				sType = "string"
			},
		},
	};

	TriggerManager.defineAction(rRemoveSourceEffectAction);
	TriggerManager.defineAction(rRemoveTargetEffectAction);
end

function sourceHasEffectCondition(rTriggerData, rEventData)
	return EffectManager.hasEffect(rEventData.rSource, rTriggerData.sEffectName);
end

function targetHasEffectCondition(rTriggerData, rEventData)
	return EffectManager.hasEffect(rEventData.rTarget, rTriggerData.sEffectName);
end

function removeSourceEffect(rTriggerData, rEventData)
	EffectManager.removeEffect(ActorManager.getCTNode(rEventData.rSource), rTriggerData.sEffectName);
end

function removeTargetEffect(rTriggerData, rEventData)
	EffectManager.removeEffect(ActorManager.getCTNode(rEventData.rTarget), rTriggerData.sEffectName);
end