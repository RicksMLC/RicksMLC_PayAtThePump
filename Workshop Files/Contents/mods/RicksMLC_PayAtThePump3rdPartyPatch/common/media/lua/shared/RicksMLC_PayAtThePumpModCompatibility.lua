-- RicksMLC_PayAtThePumpModCompatibility.lua
-- Adds compatibility with other mods that add fuel handling actions.
-- Requires RicksMLC_PayAtThePump.lua

-----------------------------------------
-- Note for modders: To add mod support for your fuel handling there are three API methods to call:
--   RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
--      Call in :new().
--      Checks the source is a fuel pump and initialise the pay amounts.
--   RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.tankStart, self.tankTarget)
--      Call in :update().
--      Checks the funds balance and reduce any credit card funds by the delta fuel amount.
--      Note that the :perform() is not needed as the funds balance checking and reducing is handled in updateFuelPurchase.
--   RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
--      Call in :stop() and :serverStop().
--      Handles the take fuel action abort state by finishing the payment of the final amount.
-----------------------------------------

---------------------------------------------
-- Commented out code: debug logging of active mods to check the name of mods to add compatibility for
-- IGNORE ---
-- local modList = getActivatedMods()
-- DebugLog.log(DebugType.Mod, "RicksMLC_PayAtThePump: Active Mods: ")
-- for i = 0, modList:size()-1 do
--     DebugLog.log(DebugType.Mod, "   RicksMLC_PayAtThePump: '" .. tostring(modList:get(i)) .. "'")
-- end      
-- DebugLog.log(DebugType.Mod, "RicksMLC_PayAtThePump: Active Mods: End")
---------------------------------------------

require "RicksMLC_PayAtThePump"

----------------------------------------------
if getActivatedMods():contains("\\TreadsFuelTypesFramework") then
    -- [+] RS_FuelTypesAPI_ISTakeFuel.lua -- This is from the FuelAPI compatibility sub-mod
    require "TimedActions/RS_FuelTypesAPI_ISTakeFuel"
    local overrideFuelAPI_ISTakeFuelNew = ISTakeFuel.new
    function ISTakeFuel:new(character, fuelStation, petrolCan, time, fuelType)
        local this = overrideFuelAPI_ISTakeFuelNew(self, character, fuelStation, petrolCan, time, fuelType)
        RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
        return this
    end
    -- Commented out as this is now in FuelAPI compatibility sub-mod.  The below code is in the vanilla RicksMLC_PayAtThePump.lua
-- else
--     require "TimedActions/ISTakeFuel"
--     local overrideISTakeFuelNew = ISTakeFuel.new
--     function ISTakeFuel:new(character, fuelStation, petrolCan, time)
--         local this = overrideISTakeFuelNew(self, character, fuelStation, petrolCan, time)
--         RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
--         return this
--     end
end

-- FIXME: Remove as these are in the vanilla code.
-- local overrideTakeFuelUpdate = ISTakeFuel.update
-- function ISTakeFuel.update(self)
--     overrideTakeFuelUpdate(self)
--     RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.itemStart, self.itemTarget)
-- end

-- local overrideServerStop = ISTakeFuel.serverStop
-- function ISTakeFuel.serverStop(self)
--     RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
--     overrideServerStop(self)
-- end

-- local overrideISTakeFuelStop = ISTakeFuel.stop
-- function ISTakeFuel.stop(self)
--     RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
--     overrideISTakeFuelStop(self)
-- end


-------------------------------------------------------------------
-- Compatibility for Tread's Fuel Types Framework [41.65+]
-- [?] RS_FuelTypesAPI_PumpFuelToBarrel.lua - Unable to test - no barrels have right click option to fill from pump?
-- [+] RS_FuelTypesAPI_RefuellFromPump.lua
-- [+] RS_FuelTypesAPI_ISTakeFuel.lua

if getActivatedMods():contains("\\TreadsFuelTypesFramework") then

    -- [?] RS_FuelTypesAPI_PumpFuelToBarrel.lua 
    require "Vehicles/TimedActions/RS_FuelTypesAPI_PumpFuelToBarrel"
    if ISPumpFuelToBarrel then
        local ovrrideISPumpFuelToBarrelNew = ISPumpFuelToBarrel.new
        function ISPumpFuelToBarrel:new(character, part, fuelStation, time)
            local this = ovrrideISPumpFuelToBarrelNew(self, character, part, fuelStation, time)
            RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
            return this
        end

        local ovrrideISPumpFuelToBarrelUpdate = ISPumpFuelToBarrel.update
        function ISPumpFuelToBarrel.update(self)
            overrideTakeFuelUpdate(self)
            RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.barrelStart, self.barrelTarget)
        end

        local ovrrideISPumpFuelToBarrelStop = ISPumpFuelToBarrel.serverStop
        function ISPumpFuelToBarrel.serverStop(self)
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            ovrrideISPumpFuelToBarrelStop(self)
        end

        local ovrrideISPumpFuelToBarrelStop = ISPumpFuelToBarrel.stop
        function ISPumpFuelToBarrel.stop(self)
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            ovrrideISPumpFuelToBarrelStop(self)
        end
    end

    -- [+] RS_FuelTypesAPI_RefuellFromPump.lua
    require "Vehicles/TimedActions/RS_FuelTypesAPI_RefuellFromPump"
    if ISRefuelFromGasPumpRSFuel then
        local overrideISRefuelFromGasPumpRSFuelNew = ISRefuelFromGasPumpRSFuel.new
        function ISRefuelFromGasPumpRSFuel:new(character, part, fuelStation, fuelType, time)
            local this = overrideISRefuelFromGasPumpRSFuelNew(self, character, part, fuelStation, fuelType, time)
            RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
            return this
        end

        local overrideISRefuelFromGasPumpRSFuelUpdate = ISRefuelFromGasPumpRSFuel.update
        function ISRefuelFromGasPumpRSFuel:update()
            overrideISRefuelFromGasPumpRSFuelUpdate(self)
            RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.tankStart, self.tankTarget)
        end

        local overrideISRefuelFromGasPumpRSFuelStop = ISRefuelFromGasPumpRSFuel.serverStop
        function ISRefuelFromGasPumpRSFuel:serverStop()
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideISRefuelFromGasPumpRSFuelStop(self)
        end

        local overrideISRefuelFromGasPumpRSFuelStop = ISRefuelFromGasPumpRSFuel.stop
        function ISRefuelFromGasPumpRSFuel:stop()
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideISRefuelFromGasPumpRSFuelStop(self)
        end
    end
end

-------------------------------------------------------------------
-- Compatibility for Pumps Have Propane
if getActivatedMods():contains("\\ugPHP") then

    -- TODO: Uncomment when I find a large tank to test this
    -- require "TimedActions/UGFillLargeTank"
    -- require "IGUI/UGTakePropaneMenu"
    -- if UGFillLargeTank then
    --     local overrideUGFillLargeTankNew = UGFillLargeTank.new
    --     function UGFillLargeTank:new(propanetankobject, character, time)
    --         local this = overrideUGFillLargeTankNew(self, propanetankobject, character, time)
    --         this.fuelStation = FindNearbyGasPump(propanetankobject) -- This function is defined in ISUI/UGTakePropaneMenu
    --         RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
    --         return this
    --     end
    --
    --     local overrideUGFillLargeTankUpdate = UGFillLargeTank.update
    --     function UGFillLargeTank:update()
    --         local tankStart = self.propanetankobjectdata.PropaneContent
    --         overrideUGFillLargeTankUpdate(self)
    --         local tankNew = self.propanetankobjectdata.PropaneContent
    --         if tankNew > tankStart then
    --             RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, tankNew - tankStart)
    --         end
    --     end
    --
    --     local overrideUGFillLargeTankStop = UGFillLargeTank.stop
    --     function UGFillLargeTank:stop()
    --         RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
    --         overrideUGFillLargeTankStop(self)
    --     end
    -- end

    require "TimedActions/UGFillPropaneTruck"
    if UGFillPropaneTruck then
        local overrideUGFillPropaneTruckNew = UGFillPropaneTruck.new
        function UGFillPropaneTruck:new(part, character, time)
            local this = overrideUGFillPropaneTruckNew(self, part, character, time)
            this.fuelStation = ISVehiclePartMenu.getNearbyFuelPump(part:getVehicle())
            this.fuelType = "Propane"
            RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
            return this
        end

        local overrideUGFillPropaneTruckUpdate = UGFillPropaneTruck.update
        function UGFillPropaneTruck:update()
            overrideUGFillPropaneTruckUpdate(self)
            RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.part:getContainerContentAmount() - self.tankStart)
        end

        local overrideUGFillPropaneTruckStop = UGFillPropaneTruck.serverStop
        function UGFillPropaneTruck:serverStop()
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideUGFillPropaneTruckStop(self)
        end

        local overrideUGFillPropaneTruckStop = UGFillPropaneTruck.stop
        function UGFillPropaneTruck:stop()
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideUGFillPropaneTruckStop(self)
        end
    end

    require "TimedActions/UGTakePropane"
    if UGTakePropane then
        local overrideUGTakePropaneNew = UGTakePropane.new
        function UGTakePropane:new(pump, tank, player, time, duration, istorch)
            local this = overrideUGTakePropaneNew(self, pump, tank, player, time, duration, istorch)
            this.fuelStation = pump -- The UGTakePropane does not inherit from ISTakeFuel therefore is missing its self.fuelStation
            this.fuelType = "Propane"
            RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
            return this
        end

        local overrideUGTakePropaneUpdate = UGTakePropane.update
        function UGTakePropane:update()
            overrideUGTakePropaneUpdate(self)
            RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.itemStart, self.itemTarget)
        end

        local overrideUGTakePropaneStop = UGTakePropane.serverStop
        function UGTakePropane:serverStop()
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideUGTakePropaneStop(self)
        end

        local overrideUGTakePropaneStop = UGTakePropane.stop
        function UGTakePropane:stop()
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideUGTakePropaneStop(self)
        end
    end
end

---------------------------------------------------------------------------------
-- Compatibility for Pzk's Vanilla Plus Car Pack
if getActivatedMods():contains("\\PzkVanillaPlusCarPack") then
    require "Vehicles/TimedActions/FuelTruck_ISRefuelFromGasPump_start"

    local overrideISRefuelFromGasPumpPZKNew = ISRefuelFromGasPumpPZK.new
    function ISRefuelFromGasPumpPZK:new(character, part, fuelStation, time)
        local this = overrideISRefuelFromGasPumpPZKNew(self, character, part, fuelStation, time)
        RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
        return this
    end

    local overrideISRefuelFromGasPumpPZKUpdate = ISRefuelFromGasPumpPZK.update
    function ISRefuelFromGasPumpPZK.update(self)
        overrideISRefuelFromGasPumpPZKUpdate(self)
        RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.tankStart, self.tankTarget)
    end

    local overrideStop = ISRefuelFromGasPumpPZK.serverStop
    function ISRefuelFromGasPumpPZK.serverStop(self)
        RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
        overrideStop(self)
    end
    
    local overrideStop = ISRefuelFromGasPumpPZK.stop
    function ISRefuelFromGasPumpPZK.stop(self)
        RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
        overrideStop(self)
    end
end

---------------------------------------------------------------------------------
if getActivatedMods():contains("\\SimpleOverhaulTraitsAndOccupations") then

    require "SOTimedActions/SORefuelerTrait"

    local function adjustForGasManagement(character, time)
        if character:HasTrait("GasManagement") then return time * 0.75 end
        return time
    end

    require "TimedActions/ISTakeFuel"
    function ISTakeFuel:calcTimeToPump()
        -- UGH: Copied from the Vanilla ISTakeFuel:start(). I don't like copying internal fn code, esp with magic numbers in them
        local pumpCurrent = tonumber(self.fuelStation:getPipedFuelAmount())
        local itemCurrent = math.floor(self.petrolCan:getUsedDelta() / self.petrolCan:getUseDelta() + 0.001)
        local itemMax = math.floor(1 / self.petrolCan:getUseDelta() + 0.001)
        local take = math.min(pumpCurrent, itemMax - itemCurrent)
        local fuelRate = 50
        if getActivatedMods():contains("\\FuelAPI") then
            local Utils = require("FuelAPI/Utils")
            fuelRate = Utils.GetSandboxFuelTransferSpeed()
        end
        return take * fuelRate
    end

    local overrideISTakeFuelStart = ISTakeFuel.start
    function ISTakeFuel:start()
        overrideISTakeFuelStart(self)
        self.action:setTime(adjustForGasManagement(self.character, self:calcTimeToPump()))
    end

    require "TimedActions/ISAddGasolineToVehicle"
    function ISAddGasolineToVehicle:calcTimeToPump()
        -- UGH: Copied from the Vanilla ISAddGasolineToVehicle:start().
        local add = self.part:getContainerCapacity() - self.tankStart
        local take = math.min(add, self.itemStart * self.JerryCanLitres)
        return take * 50
    end

    local overrideISAddGasolineToVehicleStart = ISAddGasolineToVehicle.start
    function ISAddGasolineToVehicle:start()
        overrideISAddGasolineToVehicleStart(self)
        self.action:setTime(adjustForGasManagement(self.character, self:calcTimeToPump()))
    end

    require "Vehicles/TimedActions/ISTakeGasolineFromVehicle"
    function ISTakeGasolineFromVehicle:calcTimeToPump()
        local add = (1.0 - self.itemStart) * self.JerryCanLitres
        local take = math.min(add, self.tankStart)
        return take * 50
    end

    local overrideISTakeGasolineFromVehicleStart = ISTakeGasolineFromVehicle.start
    function ISTakeGasolineFromVehicle:start()
        overrideISTakeGasolineFromVehicleStart(self)
        self.action:setTime(adjustForGasManagement(self.character, self:calcTimeToPump()))
    end

    require "Vehicles/TimedActions/ISRefuelFromGasPump"
    function ISRefuelFromGasPump:calcTimeToPump()
        -- UGH: Copied from the Vanilla ISRefuelFromGasPump:start().
        local pumpLitresAvail = self.pumpStart * (Vehicles.JerryCanLitres / 8)
        local tankLitresFree = self.part:getContainerCapacity() - self.tankStart
        local takeLitres = math.min(tankLitresFree, pumpLitresAvail)
        return takeLitres * 50
    end

    local overrideISRefuelFromGasPumpStart = ISRefuelFromGasPump.start
    function ISRefuelFromGasPump:start()
        overrideISRefuelFromGasPumpStart(self)
        self.action:setTime(adjustForGasManagement(self.character, self:calcTimeToPump()))
    end
end