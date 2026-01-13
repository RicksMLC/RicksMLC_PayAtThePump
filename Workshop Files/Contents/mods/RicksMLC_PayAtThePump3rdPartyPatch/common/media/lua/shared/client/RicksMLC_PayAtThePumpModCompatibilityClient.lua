---------------------------------------------------------------------------------
-- Compatibility for Pzk's Vanilla Plus Car Pack
if getActivatedMods():contains("\\PzkVanillaPlusCarPack") then
    -- NOTE: Require not needed as the .lua does not return a module(?)
    -- require "Vehicles/TimedActions/FuelTruck_ISRefuelFromGasPump_start"

    Events.OnGameBoot.Add(function()
        if not ISRefuelFromGasPumpPZK then
            print("[RicksMLC_PayAtThePump] ERROR: ISRefuelFromGasPumpPZK not found")
            return
        end

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

        -- Restore inheritance if needed
        if not ISRefuelFromGasPumpPZK.serverStop then
            ISRefuelFromGasPumpPZK.serverStop = ISBaseTimedAction.serverStop
        end
        local overrideServerStop = ISRefuelFromGasPumpPZK.serverStop
        function ISRefuelFromGasPumpPZK.serverStop(self)
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideServerStop(self)
        end
        
        local overrideStop = ISRefuelFromGasPumpPZK.stop
        function ISRefuelFromGasPumpPZK.stop(self)
            RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
            overrideStop(self)
        end
    end )
end