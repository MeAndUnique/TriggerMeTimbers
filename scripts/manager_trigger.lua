--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

-- A Trigger consists of one or more Events and one or more Actions.
	-- When any of the events fire all of the Actions will be executed.
-- An Event consists of zero or more Conditions.
	-- All of an event's Conditions must be met in order for the event to fire.

local tEventDefinitions = {};
local tConditionDefinitions = {};
local tActionDefinitions = {};
local tRegisteredTriggers = {};
local tRegisteredEventTriggers = {};

local tInterruptedEvents = {};
local nInterruptedEvents = 0;

function onInit()
	if Session.IsHost then
		DB.createNode("activetrigger").setPublic(true);
	end

	DB.addHandler("activetrigger.*", "onChildUpdate", onActiveTriggerUpdated);
	DB.addHandler("activetrigger.*", "onDelete", onActiveTriggerDeleted);

	for _,nodeTrigger in pairs(DB.getChildren("activetrigger")) do
		registerTrigger(nodeTrigger);
	end
end

function onActiveTriggerUpdated(nodeParent, bListchanged)
	registerTrigger(nodeParent);
end

function onActiveTriggerDeleted(nodeToBeDeleted)
	unregisterTrigger(nodeToBeDeleted);
end

function defineEvent(rEvent)
	tEventDefinitions[rEvent.sName] = rEvent;
end

function getEventDefinition(sEventName)
	return tEventDefinitions[sEventName];
end

function getEventDefinitions()
	return tEventDefinitions;
end

function getParametersForEvent(vEvent)
	local rEvent = vEvent;
	if type(vEvent) == "string" then
		rEvent = tEventDefinitions[vEvent];
	end
	return rEvent.aParameters;
end

function getCommonParametersForEvents(aEvents)
	local tParameterCounts = {};
	local nEventCount = 0;
	for _,vEvent in ipairs(aEvents) do
		nEventCount = nEventCount + 1;
		local aParameters = getParametersForEvent(vEvent);
		for _,sParameter in ipairs(aParameters) do
			tParameterCounts[sParameter] = (tParameterCounts[sParameter] or 0) + 1;
		end
	end

	local aParameters = {}
	for sParameter,nCount in pairs(tParameterCounts) do
		if nCount == nEventCount then
			table.insert(aParameters, sParameter);
		end
	end
	return aParameters;
end

function defineCondition(rCondition)
	tConditionDefinitions[rCondition.sName] = rCondition;
end

function getConditionDefinition(sConditionName)
	return tConditionDefinitions[sConditionName];
end

function getConditionDefinitions()
	return tConditionDefinitions;
end

function getConditionDefinitionsForEvent(vEvent)
	return getConditionDefinitionsForEventParameters(getParametersForEvent(vEvent));
end

function getConditionDefinitionsForEventParameters(aEventParameters)
	local aConditions = {}
	for _,rConditionDefinition in pairs(tConditionDefinitions) do
		if hasRequiredParameters(rConditionDefinition.aRequiredParameters, aEventParameters) then
			table.insert(aConditions, rConditionDefinition);
		end
	end
	return aConditions;
end

function defineAction(rAction)
	tActionDefinitions[rAction.sName] = rAction;
end

function getActionDefinition(sActionName)
	return tActionDefinitions[sActionName];
end

function getActionDefinitions()
	return tActionDefinitions;
end

function getActionDefinitionsForEvents(aEvents)
	return getActionDefinitionsForCommonEventParameters(getCommonParametersForEvents(aEvents));
end

function getActionDefinitionsForEvent(vEvent)
	return getActionDefinitionsForCommonEventParameters(getParametersForEvent(vEvent));
end

function getActionDefinitionsForCommonEventParameters(aEventParameters)
	local aActions = {}
	for _,rActionDefinition in pairs(tActionDefinitions) do
		if hasRequiredParameters(rActionDefinition.aRequiredParameters, aEventParameters) then
			table.insert(aActions, rActionDefinition);
		end
	end
	return aActions;
end

function hasRequiredParameters(aRequiredParameters, aEventParameters)
	local bHasRequirements = true;
	for _,sParameterName in ipairs(aRequiredParameters or {}) do
		if not StringManager.contains(aEventParameters, sParameterName) then
			bHasRequirements = false;
			break;
		end
	end
	return bHasRequirements;
end

function registerTrigger(nodeTrigger)
	local rTrigger = loadTriggerFromNode(nodeTrigger);
	tRegisteredTriggers[nodeTrigger] = rTrigger;

	for sEventName,_ in pairs(rTrigger.tEventLists) do
		local tEventTriggers = tRegisteredEventTriggers[sEventName];
		if not tEventTriggers then
			tEventTriggers = {};
			tRegisteredEventTriggers[sEventName] = tEventTriggers;
		end
		tEventTriggers[nodeTrigger] = rTrigger;
	end
end

function unregisterTrigger(nodeTrigger)
	local rTrigger = tRegisteredTriggers[nodeTrigger];
	if not rTrigger then
		return;
	end

	for sEventName,_ in pairs(rTrigger.tEventLists) do
		local tEventTriggers = tRegisteredEventTriggers[sEventName];
		if tEventTriggers then
			tEventTriggers[nodeTrigger] = nil;
		end
	end
	tRegisteredTriggers[nodeTrigger] = nil;
end


function loadTriggerFromNode(nodeTrigger)
	local rTrigger = {
		tEventLists = {},
		aActions = {}
	};
	for _,nodeEvent in pairs(DB.getChildren(nodeTrigger, "events")) do
		local rEvent = loadTriggerEventFromNode(nodeEvent);
		local aEvents = rTrigger.tEventLists[rEvent.sName];
		if not aEvents then
			aEvents = {};
			rTrigger.tEventLists[rEvent.sName] = aEvents;
		end
		table.insert(aEvents, rEvent);
	end
	for _,nodeAction in pairs(DB.getChildren(nodeTrigger, "actions")) do
		local rAction = loadTriggerActionFromNode(nodeAction);
		table.insert(rTrigger.aActions, rAction);
	end
	return rTrigger;
end

function loadTriggerEventFromNode(nodeEvent)
	local rEvent = {
		sName = DB.getValue(nodeEvent, "eventname", "");
		aConditions = {}
	};
	for _,nodeCondition in pairs(DB.getChildren(nodeEvent, "conditions")) do
		local rCondition = loadTriggerConditionFromNode(nodeCondition);
		table.insert(rEvent.aConditions, rCondition);
	end
	return rEvent;
end

function loadTriggerConditionFromNode(nodeCondition)
	local rCondition = {
		sName = DB.getValue(nodeCondition, "conditionname", "");
		rData = loadParametersFromNode(nodeCondition),
		bInverted = DB.getValue(nodeCondition, "inverted", 0) ~= 0,
	};
	return rCondition;
end

function loadTriggerActionFromNode(nodeAction)
	local rAction = {
		sName = DB.getValue(nodeAction, "actionname", "");
		rData = loadParametersFromNode(nodeAction)
	};
	return rAction;
end

function loadParametersFromNode(nodeContainer)
	local tParameters = {};
	for _,nodeParameter in pairs(DB.getChildren(nodeContainer, "parameters")) do
		local sName = DB.getValue(nodeParameter, "name", "");
		local vValue = DB.getValue(nodeParameter, "value");
		if DB.getValue(nodeParameter, "type") == "bool" then
			vValue = vValue ~= 0;
		end
		tParameters[sName] = vValue;
	end
	return tParameters;
end

-- TODO if supporting interruptions how does it work across triggers?
--	Other triggers are unaffected?
--		ensure other triggers are avoided when resuming
--	subsequent actions of the current trigger are skipped
--		upon resume remember which action for this trigger
--	previous in-sequence events are unaffected
--		be sure not to double dip when resuming
--	next in-sequence events are interrupted
--		make sure other triggers get to fire
function fireEvent(sEventName, rEventData)
	local tEventTriggers = tRegisteredEventTriggers[sEventName];
	local aInterruptions = {};
	for _,rTrigger in pairs(tEventTriggers or {}) do
		for _,rEvent in ipairs(rTrigger.tEventLists[sEventName]) do
			local bConditionsMet = checkConditions(rEvent, rEventData);
			if bConditionsMet then
				local rInterruption = invokeActions(rTrigger, rEventData);
				if rInterruption then
					table.insert(aInterruptions, rInterruption);
				end
			end
		end
	end
	return aInterruptions;
end

function checkConditions(rEvent, rEventData)
	local bConditionsMet = true;
	for _,rCondition in ipairs(rEvent.aConditions) do
		local rConditionDefinition = tConditionDefinitions[rCondition.sName];
		if not (rConditionDefinition and (rCondition.bInverted ~= rConditionDefinition.fCondition(rCondition.rData, rEventData))) then
			bConditionsMet = false;
			break;
		end
	end
	return bConditionsMet;
end

function invokeActions(rTrigger, rEventData)
	for nIndex,rAction in ipairs(rTrigger.aActions or {}) do
		local rActionDefinition = tActionDefinitions[rAction.sName];
		if rActionDefinition then
			local rInterruption = rActionDefinition.fAction(rAction.rData, rEventData);
			if rInterruption then
				-- TODO multiple triggers can interrupt the same event, and some interruptions may actually block
				--	interruption actions should actually fire in their own loop
				--	the event itself should be responsible for defining how to resume from interruption
				--	the above info concerning sequence handling applies the same
				return {rInterruption = rInterruption, rTrigger = rTrigger, nActionIndex = nIndex};
			end
		end
	end
end

function fireInterruptions(sEventName, rEventData, aInterruptions)
	if #aInterruptions == 0 then
		return;
	end

	local rEventDefinition = getEventDefinition(sEventName)
	local sInterruptionKey = ""; -- TODO generate unique key from event
	local rInterruptedEvent = beginTrackingInterruptedEvent(sInterruptionKey, rEventDefinition, rEventData)

	for _,rInterruptionData in ipairs(aInterruptions) do
		table.insert(rInterruptedEvent.aInterruptedTriggers, {
			rTrigger = rInterruptionData.rTrigger,
			nActionIndex = rInterruptionData.nActionIndex
		});
		rInterruptedEvent.nTriggerCount = rInterruptedEvent.nTriggerCount + 1;
	end

	for _,rInterruptionData in ipairs(aInterruptions) do
		rInterruptionData.rInterruption.fAction(sInterruptionKey, rInterruptionData.rInterruption.rData);
	end
end

function beginTrackingInterruptedEvent(sInterruptionKey, rEventDefinition, rEventData)
	local rInterruptedEvent = {
		rEventDefinition = rEventDefinition,
		rEventData = rEventData,
		nTriggerCount = 0,
		aInterruptedTriggers = {}
	};
	tInterruptedEvents[sInterruptionKey] = rInterruptedEvent;

	nInterruptedEvents = nInterruptedEvents + 1;
	if nInterruptedEvents > 100 then
		-- TODO configurable count?
		dropOldestEvent();
	end

	return rInterruptedEvent;
end

-- TODO maybe this logic can be consolidated for use with flags as well?
function dropOldestEvent()
	local nEarliest = math.huge;
	local sEarliest;
	for sInterruptionKey, rInterruptionData in pairs(tInterruptedEvents) do
		if rInterruptionData.nCreated < nEarliest then
			nEarliest = rInterruptionData.nCreated;
			sEarliest = sInterruptionKey;
		end
	end
	if sEarliest then
		tInterruptedEvents[sEarliest] = nil;
		nInterruptedEvents = nInterruptedEvents - 1;
	end
end

function endTriggerInterruption(sInterruptionKey)
	local rInterruptedEvent = tInterruptedEvents[sInterruptionKey];
	if not rInterruptedEvent then
		return;
	end

	rInterruptedEvent.nTriggerCount = rInterruptedEvent.nTriggerCount - 1;
	if rInterruptedEvent.nTriggerCount == 0 then
		resumeEvent(sInterruptionKey, rInterruptedEvent);
	end
end

function resumeEvent(sInterruptionKey, rInterruptedEvent)
	tInterruptedEvents[sInterruptionKey] = nil;
	nInterruptedEvents = nInterruptedEvents - 1;

	rInterruptedEvent.rEventDefinition.fResume(rInterruptedEvent.rEventData);
	--TODO how to deal with trigger and index data?
	--	best to avoid stateful globals where possible and maintain an execution chain.
	--	perhaps optional variables that get passed on through to fireEvent?
end