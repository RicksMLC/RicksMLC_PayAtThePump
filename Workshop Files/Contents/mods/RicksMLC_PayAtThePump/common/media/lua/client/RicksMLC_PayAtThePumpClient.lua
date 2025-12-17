-- RicksMLC_PayAtThePumpClient.lua
-- 

require "TimedActions/ISInventoryTransferAction"

local origTransferFn = ISInventoryTransferAction.perform
function ISInventoryTransferAction.perform(self)
    origTransferFn(self)

    if not SandboxVars.RicksMLC_PayAtThePump.AllowCreditCards then return end

    -- Only check if adding to the charcter inventory.  We don't care about removing things from the character
    -- or transferring from one container to another (eg inventory -> backpack)
    if self.srcContainer == self.character:getInventory() or self.srcContainer:isInCharacterInventory(self.character) then
        return
    end
    -- Check if the destination container is the character
    if self.destContainer == self.character:getInventory() or self.destContainer:isInCharacterInventory(self.character) then
        if isClient() then
            -- The server must establish the credit card data and send to all clients.
            sendClientCommand(self.character, "RicksMLC_PayAtThePump", "InitCreditCards", {})
        else
            RicksMLC_PayAtPumpAPI.InitAnyCreditCards(self.character)
        end
    end
end