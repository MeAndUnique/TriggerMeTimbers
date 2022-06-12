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

function onInit()
	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomTurnEnd(onTurnEnd);

	TriggerManager.defineEvent(rRoundStartEvent);
	TriggerManager.defineEvent(rTurnStartEvent);
	TriggerManager.defineEvent(rTurnEndEvent);
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