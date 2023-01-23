--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

rRoundStartEvent = {
	sName = "round_start_event",
	aParameters = {
		"nRound",
	};
};

rTurnStartEvent = {
	sName = "turn_start_event",
	aParameters = {
		"rSource",
	};
};

rTurnEndEvent = {
	sName = "turn_end_event",
	aParameters = {
		"rSource",
	};
};

rReactionAvailableCondition = nil;

rUseReactionAction = nil;

function onInit()
	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomTurnEnd(onTurnEnd);

	TriggerManager.defineEvent(rRoundStartEvent);
	TriggerManager.defineEvent(rTurnStartEvent);
	TriggerManager.defineEvent(rTurnEndEvent);
	initializeConditions();
	initializeActions();
end

function initializeConditions()
	rReactionAvailableCondition = {
		sName = "reaaction_available_condition",
		sDescription = "reaaction_available_condition_descritpion",
		fCondition = reactionAvailable,
		aRequiredParameters = {},
		aConfigurableParameters = {
			TriggerData.rCombatantParameter,
		},
	};

	TriggerManager.defineCondition(rReactionAvailableCondition);
end

function initializeActions()
	rUseReactionAction = {
		sName = "use_reaction_action",
		sDescription = "use_reaction_action_description",
		fAction = useReaction,
		aConfigurableParameters = {
			TriggerData.rCombatantParameter,
		},
	};

	TriggerManager.defineAction(rUseReactionAction);
end

function onRoundStart(nCurRound)
	local rEventData = {nRound=nCurRound};
	TriggerManager.fireEvent(rRoundStartEvent.sName, rEventData);
end

function onTurnStart(nodeCT)
	local rActor = ActorManager.resolveActor(nodeCT);
	local rEventData = {rSource=rActor};
	TriggerManager.fireEvent(rTurnStartEvent.sName, rEventData);
end

function onTurnEnd(nodeCT)
	local rActor = ActorManager.resolveActor(nodeCT);
	local rEventData = {rSource=rActor};
	TriggerManager.fireEvent(rTurnEndEvent.sName, rEventData);
end

function reactionAvailable(rTriggerData, rEventData)
	local bResult = false;
	local rCombatant = TriggerData.resolveCombatant(rTriggerData, rEventData);
	local nodeCombatant = ActorManager.getCTNode(rCombatant);
	if nodeCombatant then
		bResult = DB.getValue(nodeCombatant, "reaction", 0) == 1;
	end

	return bResult;
end

function useReaction(rTriggerData, rEventData)
	local rCombatant = TriggerData.resolveCombatant(rTriggerData, rEventData);
	local nodeCombatant = ActorManager.getCTNode(rCombatant);
	if nodeCombatant then
		DB.setValue(nodeCombatant, "reaction", "number", 1);
	end
end