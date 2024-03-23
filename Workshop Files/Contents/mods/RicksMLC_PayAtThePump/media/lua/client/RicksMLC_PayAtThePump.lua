-- Rick's MLC Pay At The Pump
-- RicksMLC_PayAtThePump.lua

-- Use PZ Moneez
-- Use Credit Cardz
-- TODO: Credit Cardz: Can add credit by powering up a bank/ATM and using a cash register?

-- TimedActions/ISTakeFuel
-- TimedActions/ISRefuelFromGasPump

-- The gameplay action can be simple (and magic) or more player interactive:
-- 1993 price was $1.17/gal => $0.26 per litre
--  1) Check the player's inventory for cash and reduce by the petrol amount ($0.26/litre?)
--  2) Player must put cash into the fuel pump
--
-- Credit Cardz: A credit card has a $ balance which reduces each time.
--
-------------------------------------
-- Now for the economic system underpinning the above code:

RicksMLC_PayAtThePump = {}

RicksMLC_PayAtThePump.PricePerLitre = SandboxVars.RicksMLC_PayAtThePump.PricePerLitre
RicksMLC_PayAtThePump.MinRandomCredit = SandboxVars.RicksMLC_PayAtThePump.MinRandomCredit
RicksMLC_PayAtThePump.MaxRandomCredit = SandboxVars.RicksMLC_PayAtThePump.MaxRandomCredit

local function findMoneyClosure(x, obj)
    local matchItem = x:getType() == "Money" or x:getType() == "CreditCard"
    if matchItem then
        return true
    end
    return false
end

local function getPlayerMoney()
    local itemContainer = getPlayer():getInventory()
    local itemList = itemContainer:getAllEval(findMoneyClosure)
    local cashOnHand = 0
    local credit = 0
    if not itemList:isEmpty() then
        for i = 0, itemList:size()-1 do 
            local itemType = itemList:get(i):getType()
            if itemType == "Money" then
                cashOnHand = cashOnHand + 1
            elseif itemType == "CreditCard" then
                local modData = itemList:get(i):getModData()["RicksMLC_CreditCardz"]
                if modData then
                    credit = credit + modData.Balance
                end
            end
        end
    end
    --DebugLog.log(DebugType.Mod, "getPlayerMoney() cash: " .. tostring(cashOnHand) .. " credit " .. tostring(credit))
    return {Cash = cashOnHand, Credit = credit}
end

local function addOrReplaceAfterColon(inputString, addString)
    local colonIndex = inputString:find(":")
    if colonIndex then
        inputString = inputString:sub(1, colonIndex - 1) 
    end
    return inputString .. ": " .. addString
end


local function changeCreditBalance(creditCard, amount)
    local modData = creditCard:getModData()["RicksMLC_CreditCardz"]
    local remainAmount = 0

    if not modData then
        modData = {Balance = 0}
        creditCard:getModData()["RicksMLC_CreditCardz"] = modData
    end

    modData.Balance = modData.Balance + amount
    if modData.Balance < 0 then
        remainAmount = math.abs(modData.Balance)
        modData.Balance = 0 
    end
    creditCard:getModData()["RicksMLC_CreditCardz"].Balance = modData.Balance

    local creditCardName = creditCard:getDisplayName()
    creditCardName = addOrReplaceAfterColon(creditCardName, "Balance $" .. string.format("%.2f", creditCard:getModData()["RicksMLC_CreditCardz"].Balance))
    creditCard:setName(creditCardName)
    creditCard:setCustomName(true)

    return remainAmount
end

local function reduceCreditBalances(amount)
    local itemContainer = getPlayer():getInventory()
    local itemList = itemContainer:getAllType("CreditCard")
    if not itemList:isEmpty() then
        for i = 0, itemList:size()-1 do 
            amount = changeCreditBalance(itemList:get(i), -amount)
            if amount <= 0 then return 0 end
        end
    end
    return amount
end

local function reduceCash(amount)
    -- Credit cards exhaused, resort to cash:
    local itemContainer = getPlayer():getInventory()
    local itemList = itemContainer:getAllType("Money")
    if not itemList:isEmpty() then
        for i = 0, itemList:size()-1 do 
            itemContainer:DoRemoveItem(itemList:get(i))
            amount = amount - 1
            if amount <= 0 then return end
        end
    end
end

local r = {1.0, 0.0,  0.75}
local g = {1.0, 0.75, 0.0}
local b = {1.0, 0.0,  0.0}
local fonts = {UIFont.AutoNormLarge, UIFont.AutoNormMedium, UIFont.AutoNormSmall, UIFont.Handwritten}
local function Think(player, thought, colourNum)
	-- colourNum 1 = white, 2 = green, 3 = red
	-- FIXME: Comment player:Say() out for now. Using the setHaloNote() needs testing "in the field" but works in test here.
	--  May be hard to read on other streamers depending on their font size settings?
	--player:Say(thought, r[colourNum], g[colourNum], b[colourNum], fonts[2], 1, "radio")
    player:setHaloNote(thought, r[colourNum] * 255, g[colourNum] * 255, b[colourNum] * 255, 250)
end

local function reduceFunds(amount)
    -- reduce the credit cards before cash:
    amount = reduceCreditBalances(amount)

    if amount <= 0 then return 0 end

    --Think(getPlayer(), "Credit Limit Exceeded... using cash reserves", 3)

    -- Cash is the last resort - can only use whole numbers
    if math.floor(amount) > 0 then
        reduceCash(math.floor(amount))
    end
    return amount - math.floor(amount) -- return the excess cents for the next charge
end

local function AddRandomCredit(n)
    local itemContainer = getPlayer():getInventory()
    local itemList = itemContainer:getAllTypeRecurse("CreditCard")
    local thought = "New Balance:"
    if not itemList:isEmpty() then
        for i = 0, itemList:size()-1 do 
            local creditCard = itemList:get(i)
            changeCreditBalance(creditCard, ZombRand(1, n))
            thought = thought .. " " .. tostring(creditCard:getModData()["RicksMLC_CreditCardz"].Balance)
        end
    end
    Think(getPlayer(), thought, 1)
    local money = getPlayerMoney()
    DebugLog.log(DebugType.Mod, "AddRandomCredit() Money avail: Cash: " .. tostring(money.Cash) .. " Credit: " .. tostring(money.Credit))
end


local function AddCredit(key)
    if key == Keyboard.KEY_Q then
        -- Shout us some more credit
        AddRandomCredit(10)
    end

end
--Events.OnKeyPressed.Add(AddCredit)

--------------------------------------------
-- Detect if a credit card is picked up.
-- Override the ISInventoryTransferAction:transferItem(item) (or something) so I can detect placing the treasure into the player inventory.

require "TimedActions/ISInventoryTransferAction"

local function detectNewCreditCardClosure(x)
    return (x:getType() == "CreditCard" and x:getModData()["RicksMLC_CreditCardz"] == nil)
end 

local function InitAnyCreditCards(character)
    local itemContainer = character:getInventory()
    local itemList = itemContainer:getAllEvalRecurse(detectNewCreditCardClosure)
    if not itemList then return end
    for i = 0, itemList:size()-1 do 
        changeCreditBalance(itemList:get(i), ZombRand(RicksMLC_PayAtThePump.MinRandomCredit, RicksMLC_PayAtThePump.MaxRandomCredit))
    end
end

local origTransferFn = ISInventoryTransferAction.perform
function ISInventoryTransferAction.perform(self)
    origTransferFn(self)

    -- Only check if adding to the charcter inventory.  We don't care about removing things from the character
    -- or transferring from one container to another (eg inventory -> backpack)
    if self.srcContainer == self.character:getInventory() or self.srcContainer:isInCharacterInventory(self.character) then
        return
    end
    -- Check if the destination container is the character
    if self.destContainer == self.character:getInventory() or self.destContainer:isInCharacterInventory(self.character) then
        InitAnyCreditCards(self.character)
    end
end

--------------------------------------------
-- The actual RefuelFromGasPump code is quite small compared to the economic system above.

require "TimedActions/ISRefuelFromGasPump"

local function roundMoney(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function PayForFuel(self)
    local cost = roundMoney(self.deltaFuel * RicksMLC_PayAtThePump.PricePerLitre, 2)
    if math.floor(cost * 100) > 0 then
        local change = reduceFunds(cost)
        self.deltaFuel = self.deltaFuel - (cost - change) -- not really change, but we can't split Money, so this will reduce every whole dollar.
        local money = getPlayerMoney()
        if money.Cash + money.Credit <= 0 then
            self:forceStop()
        end
    end    
end

local function HandleEmergencyStop(self)
    if self.deltaFuel > 0 then
        local cost = roundMoney(self.deltaFuel * RicksMLC_PayAtThePump.PricePerLitre, 2)
        if cost > 0.01 then
            local change = reduceFunds(cost)
            if change > 0 then
                local money = getPlayerMoney()
                if money.Cash > 0 then
                    reduceFunds(1) -- no freebies.
                end
            end
        end
    end
end

local overrideISRefuelFromGasPumpNew = ISRefuelFromGasPump.new
function ISRefuelFromGasPump:new(character, part, fuelStation, time)
    local this = overrideISRefuelFromGasPumpNew(self, character, part, fuelStation, time)
    this.fuelPurchased = 0
    this.prevFuelPurchased = 0
    this.deltaFuel = 0
    return this
end

local overrideISRefuelFromGasPumpUpdate = ISRefuelFromGasPump.update
function ISRefuelFromGasPump.update(self)
    overrideISRefuelFromGasPumpUpdate(self)
	self.fuelPurchased = (self.tankTarget - self.tankStart) * self:getJobDelta()
    self.deltaFuel = self.deltaFuel + self.fuelPurchased - self.prevFuelPurchased
    self.prevFuelPurchased = self.fuelPurchased
    PayForFuel(self)
end

local overrideStop = ISRefuelFromGasPump.stop
function ISRefuelFromGasPump.stop(self)
    HandleEmergencyStop(self)
    overrideStop(self)
end

----------------------------------------------
require "TimedActions/ISTakeFuel"

local overrideISTakeFuelNew = ISTakeFuel.new
function ISTakeFuel:new(character, fuelStation, petrolCan, time)
    local this = overrideISTakeFuelNew(self, character, fuelStation, petrolCan, time)
    this.fuelPurchased = 0
    this.prevFuelPurchased = 0
    this.deltaFuel = 0
    return this
end

local overrideTakeFuelUpdate = ISTakeFuel.update
function ISTakeFuel.update(self)
    overrideTakeFuelUpdate(self)
	self.fuelPurchased = math.floor(self.itemStart + (self.itemTarget - self.itemStart) * self:getJobDelta() + 0.001)
    self.deltaFuel = self.deltaFuel + self.fuelPurchased - self.prevFuelPurchased
    self.prevFuelPurchased = self.fuelPurchased
    PayForFuel(self)
end

local overrideISTakeFuelStop = ISTakeFuel.stop
function ISTakeFuel.stop(self)
    HandleEmergencyStop(self)
    overrideISTakeFuelStop(self)
end


