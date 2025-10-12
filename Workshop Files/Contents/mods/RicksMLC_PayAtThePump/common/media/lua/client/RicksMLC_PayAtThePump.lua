-- Rick's MLC Pay At The Pump
-- RicksMLC_PayAtThePump.lua

-- Use PZ Moneez
-- Use Credit Cardz
-- TODO: Credit Cardz: Can add credit by powering up a bank/ATM and using a cash register?
--
-- TimedActions/ISTakeFuel
-- TimedActions/ISRefuelFromGasPump
-- 
-- Mod Compatibility:
--      FuelAPI https://steamcommunity.com/sharedfiles/filedetails/?id=2688538916
--      Tread's Fuel Types Framework [41.65+] https://steamcommunity.com/sharedfiles/filedetails/?id=2765042813
--      Pumps Have Propane https://steamcommunity.com/sharedfiles/filedetails/?id=2739570406
--      CreditCardsPlus https://steamcommunity.com/sharedfiles/filedetails/?id=2873621032
--      Snake's Mod https://steamcommunity.com/sharedfiles/filedetails/?id=2719327441 (PremiumCreditCard)
--
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

RicksMLC_PayAtPumpAPI = {}

function RicksMLC_PayAtPumpAPI.findMoneyClosure(x, obj)
    local matchItem = ((SandboxVars.RicksMLC_PayAtThePump.AllowMoney and x:getType() == "Money")
                    or (SandboxVars.RicksMLC_PayAtThePump.AllowCreditCards and RicksMLC_PayAtThePump.findValidCreditCardClosure(x)))
    -- Note: I don't know why, but tostring(matchItem) is "true" or "false", but if I just return it it is always false (or fail)
    -- So use 'if matchItem then true end' to force it to return true/false. 
    if matchItem then
        return true
    end
    return false            
end

function RicksMLC_PayAtThePump.getPlayerMoney()
    local itemContainer = getPlayer():getInventory()
    local itemList = itemContainer:getAllEval(RicksMLC_PayAtPumpAPI.findMoneyClosure)
    if (SandboxVars.RicksMLC_PayAtThePump.AutoSearchForMoney and itemList:isEmpty()) then
        itemList = itemContainer:getAllEvalRecurse(RicksMLC_PayAtPumpAPI.findMoneyClosure)
    end
    local cashOnHand = 0
    local credit = 0
    if not itemList:isEmpty() then
        for i = 0, itemList:size()-1 do 
            local itemType = itemList:get(i):getType()
            if itemType == "Money" then
                cashOnHand = cashOnHand + 1
            elseif string.find(itemType, "CreditCard") ~= nil then
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

local function findlast(inputString, char)
    for i = #inputString, 1, -1 do
        if inputString:sub(i, i) == ":" then
            return i
        end
    end
    return nil
end

local function addOrReplaceAfterLastColon(inputString, addString)
    local lastColonIndex = findlast(inputString, ":")
    if lastColonIndex then
        local firstColonIndex = inputString:find(":")
        if firstColonIndex ~= lastColonIndex then
            -- there are two colons, so replace after the second one.
            inputString = inputString:sub(1, lastColonIndex - 1)    
        end
    end
    return inputString .. ": " .. addString
end

function RicksMLC_PayAtThePump.changeCreditBalance(creditCard, amount)
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
    creditCardName = addOrReplaceAfterLastColon(creditCardName, "Balance $" .. string.format("%.2f", creditCard:getModData()["RicksMLC_CreditCardz"].Balance))
    creditCard:setName(creditCardName)
    creditCard:setCustomName(true)

    return remainAmount
end

function RicksMLC_PayAtThePump.findValidCreditCardClosure(x)
    return (string.find(x:getType(), "CreditCard") ~= nil 
            and x:getModData()["RicksMLC_CreditCardz"]
            and x:getModData()["RicksMLC_CreditCardz"].Balance > 0)
end 

function RicksMLC_PayAtPumpAPI.reduceCreditBalances(amount)
    if not SandboxVars.RicksMLC_PayAtThePump.AllowCreditCards then return amount end

    local itemContainer = getPlayer():getInventory()
    local itemList = itemContainer:getAllEval(RicksMLC_PayAtThePump.findValidCreditCardClosure)
    if (SandboxVars.RicksMLC_PayAtThePump.AutoSearchForMoney and itemList:isEmpty()) then
        itemList = itemContainer:getAllEvalRecurse(RicksMLC_PayAtThePump.findValidCreditCardClosure)
    end
    if not itemList:isEmpty() then
        for i = 0, itemList:size()-1 do 
            amount = RicksMLC_PayAtThePump.changeCreditBalance(itemList:get(i), -amount)
            if amount <= 0 then return 0 end
        end
    end
    return amount
end

function RicksMLC_PayAtPumpAPI.reduceCash(amount)
    -- Credit cards exhaused, resort to cash:
    if not SandboxVars.RicksMLC_PayAtThePump.AllowMoney then return end

    local itemContainer = getPlayer():getInventory()
    local itemList = itemContainer:getAllType("Money")
    if (SandboxVars.RicksMLC_PayAtThePump.AutoSearchForMoney and itemList:isEmpty()) then
        itemList = itemContainer:getAllTypeRecurse("Money")
    end    
    if not itemList:isEmpty() then
        for i = 0, itemList:size()-1 do
            local item = itemList:get(i) 
            local realItemContainer = item:getContainer() -- The actual container may be a subcontainer like a bag in the inventory
            realItemContainer:DoRemoveItem(item)
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
	-- May be hard to read on other streamers depending on their font size settings?
    player:setHaloNote(thought, r[colourNum] * 255, g[colourNum] * 255, b[colourNum] * 255, 250)
end

function RicksMLC_PayAtPumpAPI.reduceFunds(amount)
    -- reduce the credit cards before cash:
    amount = RicksMLC_PayAtPumpAPI.reduceCreditBalances(amount)

    if amount <= 0 then return 0 end

    --Think(getPlayer(), "Credit Limit Exceeded... using cash reserves", 3)

    -- Cash is the last resort - can only use whole numbers
    if math.floor(amount) > 0 then
        RicksMLC_PayAtPumpAPI.reduceCash(math.floor(amount))
    end
    return amount - math.floor(amount) -- return the excess cents for the next charge
end

function RicksMLC_PayAtPumpAPI.AddRandomCredit(n)
    if not SandboxVars.RicksMLC_PayAtThePump.AllowCreditCards then return end

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
    local money = RicksMLC_PayAtThePump.getPlayerMoney()
    --DebugLog.log(DebugType.Mod, "AddRandomCredit() Money avail: Cash: " .. tostring(money.Cash) .. " Credit: " .. tostring(money.Credit))
end


function RicksMLC_PayAtPumpAPI.AddCredit(key)
    if key == Keyboard.KEY_Q then
        -- Shout us some more credit
        RicksMLC_PayAtPumpAPI.AddRandomCredit(10)
    end
end
--Events.OnKeyPressed.Add(RicksMLC_PayAtPumpAPI.AddCredit)

--------------------------------------------
-- Detect if a credit card is picked up.

require "TimedActions/ISInventoryTransferAction"

function RicksMLC_PayAtPumpAPI.adjustValueByOtherModsCardType(creditCard, initAmount)
    -- CreditCardPlus compatibility: silver < black < gold
    if creditCard:getType() == "CreditCard3" then return initAmount * 0.50 end -- silver
    if creditCard:getType() == "CreditCard4" then return initAmount * 2.75 end -- gold
    --"CreditCard2" is black => same as vanilla credit card so no change

    -- PremiumCreditCard from 
    if creditCard:getType() == "PremiumCreditCard" then return initAmount * 1.25 end

    return initAmount
end

function RicksMLC_PayAtPumpAPI.detectNewCreditCardClosure(x)
    return (string.find(x:getType(), "CreditCard") ~= nil and x:getModData()["RicksMLC_CreditCardz"] == nil)
end 

function RicksMLC_PayAtPumpAPI.InitAnyCreditCards(character)
    local itemContainer = character:getInventory()
    local itemList = itemContainer:getAllEvalRecurse(RicksMLC_PayAtPumpAPI.detectNewCreditCardClosure)
    if not itemList then return end
    for i = 0, itemList:size()-1 do 
        local initBalance = ZombRand(SandboxVars.RicksMLC_PayAtThePump.MinRandomCredit, SandboxVars.RicksMLC_PayAtThePump.MaxRandomCredit)
        RicksMLC_PayAtPumpAPI.adjustValueByOtherModsCardType(itemList:get(i), initBalance)
        RicksMLC_PayAtThePump.changeCreditBalance(itemList:get(i), initBalance)
    end
end

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
        RicksMLC_PayAtPumpAPI.InitAnyCreditCards(self.character)
    end
end

--------------------------------------------
-- The actual RefuelFromGasPump code is quite small compared to the economic system above.

-- General init and update handlers
function RicksMLC_PayAtPumpAPI.initPurchaseFuel(self)
    local textureName = self.fuelStation:getTextureName()
    -- Vanilla gas pump textures eg:
    -- location_shop_fossoil_01_14
    -- location_shop_gas2go_01_12
    if string.find(textureName, "fossoil") or string.find(textureName, "gas2go") then
        self.isFuelPump = true
    else
        -- This is not a fuel pump.  It may be a barrel from FuelAPI.
        self.isFuelPump = false
    end
    self.fuelPurchased = 0
    self.prevFuelPurchased = 0
    self.deltaFuel = 0
    return self
end

function RicksMLC_PayAtPumpAPI.roundMoney(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function RicksMLC_PayAtPumpAPI.getPricePerLitre(self)
    if not self.fuelType then return SandboxVars.RicksMLC_PayAtThePump.PricePerLitrePetrol end
    if self.fuelType == "Gasoline" then return SandboxVars.RicksMLC_PayAtThePump.PricePerLitrePetrol end
    if self.fuelType == "Diesel" then return SandboxVars.RicksMLC_PayAtThePump.PricePerLitreDiesel end
    if self.fuelType == "LPG" then return SandboxVars.RicksMLC_PayAtThePump.PricePerLitreLPG end
    if self.fuelType == "Propane" then return SandboxVars.RicksMLC_PayAtThePump.PricePerLitrePropane end

    -- Default to the petrol price
    return SandboxVars.RicksMLC_PayAtThePump.PricePerLitrePetrol
end

function RicksMLC_PayAtPumpAPI.payForFuel(self)
    local price = RicksMLC_PayAtPumpAPI.getPricePerLitre(self)
    local cost = RicksMLC_PayAtPumpAPI.roundMoney(self.deltaFuel * price, 2)
    if math.floor(cost * 100) > 0 then
        local change = RicksMLC_PayAtPumpAPI.reduceFunds(cost)
        self.deltaFuel = self.deltaFuel - ((cost - change) / price) -- not really change, but we can't split Money, so this will reduce every whole dollar.
        local money = RicksMLC_PayAtThePump.getPlayerMoney()
        if money.Cash + money.Credit <= 0 then
            self:forceStop()
        end
    end    
end

-- RicksMLC_PayAtPumpAPI.updateFuelPurchase
-- @param self  TimedAction object
-- @param startOrAmt Start amount of fuel / fuel in this update if target is nil
-- @param target Target amount of fuel.
-- The amount of fuel purchased is calculated from the start amount in the tank and the target amount at the end of the TA
-- and the time so far (getJobDelta()).  
-- If target is nil, the startOrAmt is the amount purchased in this update call.
function RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, startOrAmt, target)
    if not self.isFuelPump then return end

    if target then
        self.fuelPurchased = (target - startOrAmt) * self:getJobDelta()
    else
        self.fuelPurchased = startOrAmt
    end
    self.deltaFuel = self.deltaFuel + self.fuelPurchased - self.prevFuelPurchased
    self.prevFuelPurchased = self.fuelPurchased
    RicksMLC_PayAtPumpAPI.payForFuel(self)
end

function RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
    if not self.isFuelPump then return end

    if self.deltaFuel > 0 then
        local price = RicksMLC_PayAtPumpAPI.getPricePerLitre(self)
        local cost = RicksMLC_PayAtPumpAPI.roundMoney(self.deltaFuel * price, 2)
        if cost > 0.01 then
            local change = RicksMLC_PayAtPumpAPI.reduceFunds(cost)
            if change > 0 then
                local money = RicksMLC_PayAtThePump.getPlayerMoney()
                if money.Cash > 0 then
                    RicksMLC_PayAtPumpAPI.reduceFunds(1) -- no freebies.
                end
            end
        end
    end
end

-----------------------------------------
-- Note for modders: To add mod support for your fuel handling there are three API methods to call:
--   RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
--      Call in :new(). Checks the source is a fuel pump and initialise the pay amounts.
--   RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.tankStart, self.tankTarget)
--      Call in :update(). Checks the funds balance and reduce any credit card funds by the delta fuel amount.
--      Note that the :perform() is not needed as the funds balance checking and reducing is handled in updateFuelPurchase.
--   RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
--      Call in :stop().   Handles the take fuel action abort state by finishing the payment of the final amount.
-- The following code is also an example of the same functions to implement the overrides for the vanilla ISRefuelFromGasPump.
-----------------------------------------
require "Vehicles/TimedActions/ISRefuelFromGasPump"

local overrideISRefuelFromGasPumpNew = ISRefuelFromGasPump.new
function ISRefuelFromGasPump:new(character, part, fuelStation, time)
    local this = overrideISRefuelFromGasPumpNew(self, character, part, fuelStation, time)
    RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
    return this
end

local overrideISRefuelFromGasPumpUpdate = ISRefuelFromGasPump.update
function ISRefuelFromGasPump.update(self)
    overrideISRefuelFromGasPumpUpdate(self)
    RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.tankStart, self.tankTarget)
end

local overrideStop = ISRefuelFromGasPump.stop
function ISRefuelFromGasPump.stop(self)
    RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
    overrideStop(self)
end


