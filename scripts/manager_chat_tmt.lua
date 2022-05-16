-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

rSendChatMessageAction = nil;

function onInit()
    initializeActions();
end

function initializeActions()
    rSendChatMessageAction = {
        sName = "send_chat_message_action",
        fAction = sendChatMessage,
        aConfigurableParameters = {
            {
                sName = "sMessage",
                sDisplay = "chat_message_parameter",
                sType = "string"   
            }
        }
    }

    TriggerManager.defineAction(rSendChatMessageAction);
end

function sendChatMessage(rTriggerData, rEventData)
    local msg = {
        sender = "",
        font = "msgfont",
        text = rTriggerData.sMessage,
        icon = "TriggerMeTimbers"
    }
    Comm.deliverChatMessage(msg);
end