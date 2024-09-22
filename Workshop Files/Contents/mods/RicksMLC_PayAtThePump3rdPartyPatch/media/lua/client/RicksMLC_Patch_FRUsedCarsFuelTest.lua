-- RicksMLC_Patch_FRUsedCarsFuelTest.lua
-- The Filibuster Rhymes' Used Cars! Fuel Test "FuelTruck_ISRefuelFromGasPump_start.lua" file
-- has an override for the ISRefuelFromGasPump:start() which looks like test code with 
-- hard-coded values, and does not set the self.sound.  This will cause 
-- the ISRefuelFromGasPump:stop() to error when it tries to stop the sound.
--
-- Remove the FR :start() method by replacing it with the original vanilla function.

if not (getActivatedMods():contains("FRUsedCarsFT") or getActivatedMods():contains("PzkVanillaPlusCarPack")) then return end

require "Vehicles/TimedActions/ISRefuelFromGasPump"
local origVanillaStart = ISRefuelFromGasPump.start

require "Vehicles/TimedActions/FuelTruck_ISRefuelFromGasPump_start"

function ISRefuelFromGasPump:start()
    origVanillaStart(self)
end
