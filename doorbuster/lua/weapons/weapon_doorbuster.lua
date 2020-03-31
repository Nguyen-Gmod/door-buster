AddCSLuaFile()
--Created by Nguyen-Gmod
SWEP.Instructions	= "Shoot a door to blow it down."
if (engine.ActiveGamemode() == "terrortown") then
	SWEP.Base = "weapon_tttbase"
	SWEP.Kind = WEAPON_EQUIP1
	SWEP.AmmoEnt = "item_box_buckshot_ttt"
	SWEP.Icon = "entities/weapon_doorbuster_ttt"
	SWEP.CanBuy = {ROLE_TRAITOR}
	SWEP.InLoadoutFor = nil
	SWEP.LimitedStock = false
	SWEP.AllowDrop = false
	SWEP.EquipMenuData = {
	   type = "Door Buster",
	   desc = "A shotgun that shoots down doors."
	}
else
	SWEP.Base			= "weapon_base"
end
SWEP.Spawnable			= true
SWEP.AdminOnly			= true
SWEP.UseHands			= true

SWEP.ViewModel			= "models/weapons/v_shot_m3super90.mdl"
SWEP.WorldModel			= "models/weapons/w_shot_m3super90.mdl"

SWEP.Primary.ClipSize		= 8
SWEP.Primary.DefaultClip	= 8
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "Buckshot"
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= true
SWEP.AutoSwitchFrom		= false

SWEP.PrintName			= "Leone 12 Gauge Super"
SWEP.Slot				= 3
SWEP.SlotPos			= 1
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true
SWEP.HoldType			= "ar2"
SWEP.ViewModelFlip 		= true
SWEP.Doors				= {"prop_door_rotating"/*/,"func_door_rotating"/*/} --Remove both /*/ if you want to bust ALL doors, garage doors, elevator, etc...

util.PrecacheSound("slow.wav")

if (CLIENT) then
	SWEP.CSMuzzleFlashes = true
end

local ShootSound = Sound("weapons/m3/m3-1.wav")
local DeploySound = Sound("weapons/m3/m3_pump.wav")

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetNextPrimaryFire(CurTime()+.75)
	return true
end

function SWEP:Initialize()
	self.m_bInitialized = true
	self:SetHoldType(self.HoldType)
end

function SWEP:Think()
	if ( not self.m_bInitialized ) then
		self:Initialize()
	end
	if (!self.Owner:Alive()) then
		if (timer.Exists(self.Owner:SteamID().."_buster_reload")) then
			timer.Destroy(self.Owner:SteamID().."_buster_reload")
		end
		if (timer.Exists(self.Owner:SteamID().."_buster_cock")) then
			timer.Destroy(self.Owner:SteamID().."_buster_cock")
		end		
	end
end

function SWEP:Think()
	self:ShouldDrawViewModel()
end

function SWEP:PrimaryAttack()
	if ( !self:CanPrimaryAttack() ) then return end
	self:ShootBullet(50, 8, .03, self.Primary.Ammo, 1, 1 )
	self:EmitSound(ShootSound)
	self:SetNextPrimaryFire(CurTime()+.7)
	self:TakePrimaryAmmo(1) 
	self:BlowDoor()
end

function SWEP:CanPrimaryAttack()
	if ( self.Weapon:Clip1() <= 0 ) then
		return false
	else
		return true
	end
	return true
end

function SWEP:SecondaryAttack()
	self.Owner:EmitSound("npc/combine_soldier/vo/readyweapons.wav")
end

function SWEP:ShouldDrawViewModel()
	return true
end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:Reload()
	--if self.ReloadingTime and CurTime() <= self.ReloadingTime then return end
 
	if ( self:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
		local ranout = false
		local ammoleft = self.Primary.ClipSize - self:Clip1()
		timer.Create(self.Owner:SteamID().."_buster_reload", .4, ammoleft, function()
			if (!self.Owner:Alive()) then timer.Destroy(self.Owner:SteamID().."_buster_reload") return end
			if (self:Ammo1() <= 0) then
				ranout = true
				self:SendWeaponAnim(ACT_VM_DRAW)
				timer.Destroy(self.Owner:SteamID().."_buster_reload")
			else
				self:SendWeaponAnim(ACT_VM_RELOAD)
				self:SetClip1(self:Clip1() + 1)
				self.Owner:RemoveAmmo(1, self.Weapon:GetPrimaryAmmoType())
			end
		end)
		timer.Create(self.Owner:SteamID().."_buster_cock", .45*ammoleft, 1, function()
			if (!self.Owner:Alive()) then timer.Destroy(self.Owner:SteamID().."_buster_cock") return end
			if ranout == false then
				self:SendWeaponAnim(ACT_VM_DRAW)
			end
		end)
		self:SetNextPrimaryFire(.55*ammoleft)
	end
end

function SWEP:BlowDoor()
	local trace = self.Owner:GetEyeTrace().Entity
	if (table.HasValue(self.Doors, trace:GetClass())) then
		if (self.Owner:GetPos():DistToSqr(trace:GetPos()) > (400*400)) then return end
		if (trace:GetSaveTable().m_eDoorState != 0) then return end
		local newDoor = ents.Create("prop_physics")
		newDoor:SetModel(trace:GetModel())
		newDoor:SetMaterial(trace:GetMaterial())
		newDoor:SetSkin(trace:GetSkin())
		newDoor:SetPos(trace:GetPos())
		newDoor:SetAngles(trace:GetAngles())
		local doorData = {}
		local doorOwner = {false, NULL}
		if (engine.ActiveGamemode() == "darkrp") then
			if trace:isKeysOwned() then
				doorData = trace:getDoorData()
				doorOwner[1] = true
				doorOwner[2] = trace:getDoorOwner()
			end
		end
		self:CreateDoorRespawn(trace:GetClass(), trace:GetModel(), trace:GetMaterial(), trace:GetSkin(), trace:GetPos(), trace:GetAngles(), trace:EntIndex(), newDoor, doorData, doorOwner)
		trace:Remove()
		newDoor:Spawn()
		phys = newDoor:GetPhysicsObject()
		phys:SetVelocity(self.Owner:GetAimVector()*250)
		if (game.SinglePlayer()) then
			self.Owner:EmitSound("slow.wav")
			game.SetTimeScale(.25)
			timer.Create("buster_slow", 1.5, 1, function()
				game.SetTimeScale(1)
			end)
		end
	end
end

function SWEP:CreateDoorRespawn(door, model, material, skin, pos, ang, index, new, data, owner)
	timer.Create(index.."_buster_respawn", 300, 1, function()
		local oldDoor = ents.Create(door)
		oldDoor:SetModel(model)
		oldDoor:SetMaterial(material)
		oldDoor:SetSkin(skin)
		oldDoor:SetPos(pos)
		oldDoor:SetAngles(ang)
		new:Remove()
		oldDoor:Spawn()
		if (engine.ActiveGamemode() == "darkrp") then
			if (owner[1] == true) then
				oldDoor:addKeysDoorOwner(owner[2])
				oldDoor.DoorData = data
			end
		end
	end)
end
