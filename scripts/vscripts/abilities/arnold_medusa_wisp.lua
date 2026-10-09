-- Арнольд: врождёнка "Медуза + Висп"
-- Как релокейт Виспа: после короткой задержки Арнольд переносится к своему
-- фонтану, восстанавливает здоровье и ману и через несколько секунд
-- возвращается туда, откуда улетел. Если Арнольд умирает — возврата нет.

arnold_medusa_wisp = class({})

LinkLuaModifier("modifier_arnold_medusa_wisp_delay", "abilities/arnold_medusa_wisp", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arnold_medusa_wisp_return", "abilities/arnold_medusa_wisp", LUA_MODIFIER_MOTION_NONE)

local function DestroyFxLater(fx, delay)
    Timers:CreateTimer(delay, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)
end

local function TeleportFx(position)
    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(fx, 0, position)
    DestroyFxLater(fx, 2.0)
end

function arnold_medusa_wisp:Spawn()
    if IsServer() and self:GetLevel() == 0 then
        self:SetLevel(1)
    end
end

function arnold_medusa_wisp:OnOwnerSpawned()
    if IsServer() and self:GetLevel() == 0 then
        self:SetLevel(1)
    end
end

function arnold_medusa_wisp:GetCooldown(level)
    return self:GetSpecialValueFor("cooldown")
end

function arnold_medusa_wisp:FindFountain()
    local team = self:GetCaster():GetTeamNumber()
    for _, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
        if fountain:GetTeamNumber() == team then
            return fountain
        end
    end
    return nil
end

function arnold_medusa_wisp:OnSpellStart()
    local caster = self:GetCaster()

    if not self:FindFountain() then
        print("[ARNOLD] Medusa + Wisp: fountain not found")
        self:EndCooldown()
        return
    end

    caster:AddNewModifier(caster, self, "modifier_arnold_medusa_wisp_delay", {
        duration = self:GetSpecialValueFor("delay")
    })
    caster:EmitSound("Hero_Wisp.Relocate")
end

function arnold_medusa_wisp:Relocate()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() or not caster:IsAlive() then return end

    local fountain = self:FindFountain()
    if not fountain then return end

    local return_point = caster:GetAbsOrigin()
    TeleportFx(return_point)

    ProjectileManager:ProjectileDodge(caster)
    caster:Stop()
    FindClearSpaceForUnit(caster, fountain:GetAbsOrigin(), true)
    TeleportFx(caster:GetAbsOrigin())

    local heal = caster:GetMaxHealth() * self:GetSpecialValueFor("restore_pct") / 100
    local mana = caster:GetMaxMana() * self:GetSpecialValueFor("restore_pct") / 100
    caster:Heal(heal, self)
    caster:GiveMana(mana)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, heal, nil)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, caster, mana, nil)

    local bottle_fx = ParticleManager:CreateParticle("particles/items_fx/bottle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    DestroyFxLater(bottle_fx, 2.0)

    caster:EmitSound("Hero_Wisp.Return")

    caster:AddNewModifier(caster, self, "modifier_arnold_medusa_wisp_return", {
        duration = self:GetSpecialValueFor("return_time"),
        x = return_point.x,
        y = return_point.y,
        z = return_point.z,
    })
end

--------------------------------------------------------------------------------
-- ЗАДЕРЖКА ПЕРЕД ПЕРЕНОСОМ (Висп тянет)
--------------------------------------------------------------------------------

modifier_arnold_medusa_wisp_delay = class({})

function modifier_arnold_medusa_wisp_delay:IsHidden() return false end
function modifier_arnold_medusa_wisp_delay:IsPurgable() return false end
function modifier_arnold_medusa_wisp_delay:GetTexture() return "wisp_relocate" end

function modifier_arnold_medusa_wisp_delay:OnCreated()
    if not IsServer() then return end

    self.fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_wisp/wisp_relocate_channel.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        self:GetParent()
    )
end

function modifier_arnold_medusa_wisp_delay:OnDestroy()
    if not IsServer() then return end

    if self.fx then
        ParticleManager:DestroyParticle(self.fx, false)
        ParticleManager:ReleaseParticleIndex(self.fx)
        self.fx = nil
    end

    -- Модификатор снимается смертью раньше времени — тогда никуда не летим
    if self:GetRemainingTime() > 0.05 then return end

    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        ability:Relocate()
    end
end

--------------------------------------------------------------------------------
-- НА ФОНТАНЕ: через return_time возвращает Арнольда обратно
--------------------------------------------------------------------------------

modifier_arnold_medusa_wisp_return = class({})

function modifier_arnold_medusa_wisp_return:IsHidden() return false end
function modifier_arnold_medusa_wisp_return:IsPurgable() return false end
function modifier_arnold_medusa_wisp_return:GetTexture() return "wisp_relocate" end

function modifier_arnold_medusa_wisp_return:OnCreated(kv)
    if not IsServer() then return end

    self.return_point = Vector(kv.x, kv.y, kv.z)

    -- Отметка, куда Арнольд вернётся
    self.marker_fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_wisp/wisp_relocate_marker.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.marker_fx, 0, self.return_point)
end

function modifier_arnold_medusa_wisp_return:OnDestroy()
    if not IsServer() then return end

    if self.marker_fx then
        ParticleManager:DestroyParticle(self.marker_fx, false)
        ParticleManager:ReleaseParticleIndex(self.marker_fx)
        self.marker_fx = nil
    end

    local parent = self:GetParent()
    if not parent or parent:IsNull() or not parent:IsAlive() then return end

    TeleportFx(parent:GetAbsOrigin())
    ProjectileManager:ProjectileDodge(parent)
    parent:Stop()
    FindClearSpaceForUnit(parent, self.return_point, true)
    TeleportFx(parent:GetAbsOrigin())
    parent:EmitSound("Hero_Wisp.Return")
end
