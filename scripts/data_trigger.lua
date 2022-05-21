--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

rIsSourceCondition = nil;
rIsTargetCondition = nil;

rCombatantParameter = {
	sName = "sCombatant",
	sDisplay = "combatant_parameter",
	sDescription = "combatant_parameter_description",
	sType = "combo",
	aDefinedValues = {
		{
			sValue = "source_subject",
			sDescription = "source_subject_description",
			aRequiredParameters = {"rSource"}
		},
		{
			sValue = "target_subject",
			sDescription = "target_subject_description",
			aRequiredParameters = {"rTarget"}
		},
	}
};

rComparisonParameter = {
	sName = "sComparison",
	sDisplay = "comparison_parameter",
	sType = "combo",
	aDefinedValues = {
		"equal_comparison",
		"not_equal_comparison",
		"greater_than_comparison",
		"greater_than_equal_comparison",
		"less_than_comparison",
		"less_than_equal_comparison",
	},
};

function onInit()
	initializeConditions();
end

function initializeConditions()
	rIsSourceCondition = {
		sName = "is_source_condition",
		fCondition = isSource,
		aRequiredParameters = {"rSource"}
	};
	rIsTargetCondition = {
		sName = "is_target_condition",
		fCondition = isTarget,
		aRequiredParameters = {"rTarget"}
	};

	-- TODO flesh out before re-enabling
	-- TriggerManager.defineCondition(rIsSourceCondition);
	-- TriggerManager.defineCondition(rIsTargetCondition);
end

function resolveComparison(vLeft, vRight, sComparison)
	if sComparison == "not_equal_comparison" then
		return vLeft ~= vRight;
	elseif sComparison == "greater_than_comparison" then
		return vLeft > vRight;
	elseif sComparison == "greater_than_equal_comparison" then
		return vLeft >= vRight;
	elseif sComparison == "less_than_comparison" then
		return vLeft < vRight;
	elseif sComparison == "less_than_equal_comparison" then
		return vLeft <= vRight;
	else
		return vLeft == vRight;
	end
end

function isSource(rTriggerData, rEventData)
	return rEventData.rSource and rTriggerData.sSourcePath == rEventData.rSource.sCreatureNode;
end

function isTarget(rTriggerData, rEventData)
	return rEventData.rTarget and rTriggerData.sTargetPath == rEventData.rTarget.sCreatureNode;
end