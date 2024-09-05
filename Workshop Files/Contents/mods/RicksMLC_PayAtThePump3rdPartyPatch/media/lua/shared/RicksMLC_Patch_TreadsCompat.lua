-- RicksMLC_Patch_TreadsCompat.lua
--
if not SandboxVars.FuelAPI then return end

-- SandboxVars.FuelAPI.BarrelDefaultQuantity
if not SandboxVars.FuelAPI.BarrelDefaultQuantity then
    SandboxVars.FuelAPI.BarrelDefaultQuantity = SandboxVars.FuelAPI.BarrelMaxCapacity
end



