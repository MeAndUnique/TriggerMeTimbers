-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

rAfterAttackRollEvent = {
    sName = "after_attack_event",
    aParameters = {
        "rSource",
        "rTarget",
        "nAttack",
        "sDesc",
        "sResults"
    }
}
rAttackResultCondition = nil;

local fApplyAttackOriginal;

function onInit()
    fApplyAttackOriginal = ActionAttack.applyAttack;
    ActionAttack.applyAttack = applyAttack;

    initializeConditions();
    TriggerManager.defineEvent(rAfterAttackRollEvent);
end

function initializeConditions()
    rAttackResultCondition = {
        sName = "attack_result_condition",
        fCondition = attackMatchesResultCondition,
        aRequriedParameters = {
            "rSource",
            "rTarget",
            "nAttack",
            "sResults"
        },
        aConfigurableParameters = {
            {
                sName = "sAttackResult",
                sDisplay = "attack_result_property_parameter",
                sType = "combo",
                aDefinedValues = {
                    "attack_result_property_hit",
                    "attack_result_property_miss",
                    "attack_result_property_critical",
                    "attack_result_property_fumble"
                }
            }
        }
    }

    TriggerManager.defineCondition(rAttackResultCondition);
end

function attackMatchesResultCondition(rTriggerData, rEventData)
    if rTriggerData.sAttackResult == "attack_result_property_hit" then
        return string.match(rEventData.sResults, "%[HIT%]") ~= nil or string.match(rEventData.sResults, "%[AUTOMATIC HIT%]") ~= nil;
    elseif rTriggerData.sAttackResult == "attack_result_property_critical" then
        return string.match(rEventData.sResults, "%[CRITICAL HIT%]") ~= nil;
    elseif rTriggerData.sAttackResult == "attack_result_property_miss" then
        return string.match(rEventData.sResults, "%[MISS%]") ~= nil
    elseif rTriggerData.sAttackResult == "attack_result_property_fumble" then
        return string.match(rEventData.sResults, "%[AUTOMATIC MISS%]") ~= nil or string.match(rEventData.sResults, "%[FUMBLE%]") ~= nil
    end

    return false;
end

function applyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
    fApplyAttackOriginal(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults);

    local rEventData = {
        rSource = rSource,
        rTarget = rTarget,
        nAttack = nTotal,
        sDesc = sDesc,
        sResults = sResults
    }
    TriggerManager.fireEvent(rAfterAttackRollEvent.sName, rEventData);
end