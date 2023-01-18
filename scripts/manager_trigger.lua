--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

-- A Trigger consists of one or more Events and one or more Actions.
	-- When any of the events fire all of the Actions will be executed.
-- An Event consists of zero or more Conditions.
	-- All of an event's Conditions must be met in order for the event to fire.

OOB_MSGTYPE_END_INTERRUPTION = "end_trigger_interruption";

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
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_END_INTERRUPTION, handleEndTriggerInterruption);
	end

	DB.addHandler("activetrigger.*", "onChildUpdate", onActiveTriggerUpdated);
	DB.addHandler("activetrigger.*", "onDelete", onActiveTriggerDeleted);

	for _,nodeTrigger in pairs(DB.getChildren("activetrigger")) do
		registerTrigger(nodeTrigger);
	end

	for _,aEventTriggers in pairs(tRegisteredEventTriggers) do
		table.sort(aEventTriggers, sortTriggerNodes);
	end
end

function onActiveTriggerUpdated(nodeParent)
	registerTrigger(nodeParent, true);
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
	return getConditionDefinitionsForParameters(getParametersForEvent(vEvent));
end

function getConditionDefinitionsForAction(vAction)
	return getConditionDefinitionsForParameters(getParametersForAction(vAction));
end

function getConditionDefinitionsForParameters(aEventParameters)
	local aConditions = {};
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

function getParametersForAction(vAction)
	local rAction = vAction;
	if type(vAction) == "string" then
		rAction = tActionDefinitions[vAction];
	end
	return (rAction.rCreatedEvent or {}).aParameters;
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

function registerTrigger(nodeTrigger, bSort)
	unregisterTrigger(nodeTrigger); -- Ensure that changing events is handled correctly.
	local rTrigger = loadTriggerFromNode(nodeTrigger);
	tRegisteredTriggers[nodeTrigger] = rTrigger;

	for sEventName,_ in pairs(rTrigger.tEventLists) do
		local aEventTriggers = tRegisteredEventTriggers[sEventName];
		if not aEventTriggers then
			aEventTriggers = {};
			tRegisteredEventTriggers[sEventName] = aEventTriggers;
		end
		table.insert(aEventTriggers, nodeTrigger)

		if bSort then
			table.sort(aEventTriggers, sortTriggerNodes);
		end
	end
end

function sortTriggerNodes(nodeLeft, nodeRight)
	-- Sort in descending priority
	return tRegisteredTriggers[nodeRight].nPriority < tRegisteredTriggers[nodeLeft].nPriority;
end

function unregisterTrigger(nodeTrigger)
	local rTrigger = tRegisteredTriggers[nodeTrigger];
	if not rTrigger then
		return;
	end

	for sEventName,_ in pairs(rTrigger.tEventLists) do
		local aEventTriggers = tRegisteredEventTriggers[sEventName];
		for nIndex,nodeEventTrigger in ipairs(aEventTriggers) do
			if nodeEventTrigger == nodeTrigger then
				table.remove(aEventTriggers, nIndex);
				break;
			end
		end
	end
end

function loadTriggerFromNode(nodeTrigger)
	local rTrigger = {
		nodeTrigger = nodeTrigger,
		nPriority = DB.getValue(nodeTrigger, "priority", 0),
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
	for _,nodeAction in ipairs(UtilityManager.getSortedTable(DB.getChildren(nodeTrigger, "actions"))) do
		local rAction = loadTriggerActionFromNode(nodeAction);
		table.insert(rTrigger.aActions, rAction);
	end
	return rTrigger;
end

function loadTriggerEventFromNode(nodeEvent)
	local rEvent = {
		sName = DB.getValue(nodeEvent, "eventname", ""),
		aConditions = {},
	};
	for _,nodeCondition in ipairs(UtilityManager.getSortedTable(DB.getChildren(nodeEvent, "conditions"))) do
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
		rData = loadParametersFromNode(nodeAction),
		aConditions = {},
	};
	for _,nodeCondition in ipairs(UtilityManager.getSortedTable(DB.getChildren(nodeAction, "conditions"))) do
		local rCondition = loadTriggerConditionFromNode(nodeCondition);
		table.insert(rAction.aConditions, rCondition);
	end
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
function fireEvent(sEventName, rEventData, rResumedInterruption)
	-- TODO break this down some more, theres a lot of decision-making going on here.
	local aEventTriggerNodes = tRegisteredEventTriggers[sEventName];
	local rInterruptedTrigger = (rInterruptedTrigger or {}).rTrigger;
	local rInterruption;
	local bShouldTrigger = rInterruptedTrigger == nil;
	for _,nodeTrigger in ipairs(aEventTriggerNodes or {}) do
		local rTrigger = tRegisteredTriggers[nodeTrigger];
		if bShouldTrigger then
			for _,rEvent in ipairs(rTrigger.tEventLists[sEventName]) do
				local bConditionsMet = checkConditions(rEvent.aConditions, rEventData);
				if bConditionsMet then
					rInterruption = invokeActions(rTrigger, rEventData, rResumedInterruption);
					break;
				end
			end
			if rInterruption then
				break;
			end
		end
		bShouldTrigger = bShouldTrigger or rTrigger == rInterruptedTrigger;
	end
	return rInterruption;
end

function checkConditions(aConditions, rEventData)
	local bConditionsMet = true;
	for _,rCondition in ipairs(aConditions) do
		local rConditionDefinition = tConditionDefinitions[rCondition.sName];
		if not (rConditionDefinition and (rCondition.bInverted ~= rConditionDefinition.fCondition(rCondition.rData, rEventData))) then
			bConditionsMet = false;
			break;
		end
	end
	return bConditionsMet;
end

function invokeActions(rTrigger, rEventData, rResumedInterruption)
	-- TODO break this down some more, theres a lot of decision-making going on here.
	local rInterruptedAction = (rResumedInterruption or {}).rAction;
	if rInterruptedAction and not checkConditions(rInterruptedAction.aConditions, rResumedInterruption.rActionEventData) then
		return;
	end
	local bShouldInvoke = rInterruptedAction == nil;
	for _,rAction in  ipairs(rTrigger.aActions) do
		if bShouldInvoke then
			local rActionDefinition = tActionDefinitions[rAction.sName];
			if rActionDefinition then
				-- TODO Allow actions to add event data?
				--	Probably need to build the system out more first; UI rework timeline likely
				local rActionEventData = rActionDefinition.fAction(rAction.rData, rEventData) or {};
				if rActionEventData.bIsInterruption then
					rActionEventData.rTrigger = rTrigger;
					rActionEventData.rAction = rAction;
					return rActionEventData;
				end
				if not checkConditions(rAction.aConditions, rActionEventData) then
					return;
				end
			end
		end
		bShouldInvoke = bShouldInvoke or rAction == rInterruptedAction;
	end
end

function fireInterruption(sEventName, rEventData, rInterruption)
	if not rInterruption then
		return;
	end

	local sInterruptionKey = generateInterruptionKey();
	local rEventDefinition = getEventDefinition(sEventName)
	local rInterruptedEvent = beginTrackingInterruptedEvent(sInterruptionKey, rEventDefinition, rEventData, rInterruption);

	rInterruptedEvent.nPendingInterruptions = rInterruption.fAction(sInterruptionKey, rInterruption.rData, rEventData) or 1;
end

local nKeyCounter = 0;
function generateInterruptionKey()
	local sDecoration = "";
	if Session.IsHost then
		sDecoration = "(Host)";
	end
	nKeyCounter = nKeyCounter + 1;
	return string.format("%s%s: %d", Session.UserName, sDecoration, nKeyCounter);
end

function beginTrackingInterruptedEvent(sInterruptionKey, rEventDefinition, rEventData, rInterruption)
	local rInterruptedEvent = {
		rEventDefinition = rEventDefinition,
		rEventData = rEventData,
		rInterruption = rInterruption
	};
	tInterruptedEvents[sInterruptionKey] = rInterruptedEvent;

	nInterruptedEvents = nInterruptedEvents + 1;
	while nInterruptedEvents > 100 do
		-- TODO configurable count?
		dropOldestEvent();
	end

	return rInterruptedEvent;
end

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

function notifyEndTriggerInterruption(sInterruptionKey, msgOOB)
	msgOOB.type = OOB_MSGTYPE_END_INTERRUPTION;
	msgOOB.sInterruptionKey = sInterruptionKey;
	-- Send to all clients since the interruption will only be stored for the originator.
	Comm.deliverOOBMessage(msgOOB);
end

function handleEndTriggerInterruption(msgOOB)
	endTriggerInterruption(msgOOB.sInterruptionKey, msgOOB)
end

function endTriggerInterruption(sInterruptionKey, msgOOB)
	local rInterruptedEvent = tInterruptedEvents[sInterruptionKey];
	if not rInterruptedEvent then
		return;
	end

	rInterruptedEvent.nPendingInterruptions = rInterruptedEvent.nPendingInterruptions - 1;
	if rInterruptedEvent.nPendingInterruptions <= 0 then
		-- TODO if ever using multiple interruptions from a single action, figure out event data on resume.
		local rActionDefinition = tActionDefinitions[rInterruptedEvent.rInterruption.rAction.sName];
		rInterruptedEvent.rInterruption.rActionEventData = rActionDefinition.fDecodeEventOOB(msgOOB);
		resumeEvent(sInterruptionKey, rInterruptedEvent);
	end
end

function resumeEvent(sInterruptionKey, rInterruptedEvent)
	tInterruptedEvents[sInterruptionKey] = nil;
	nInterruptedEvents = nInterruptedEvents - 1;

	rInterruptedEvent.rEventDefinition.fResume(rInterruptedEvent.rEventData, rInterruptedEvent.rInterruption);
end