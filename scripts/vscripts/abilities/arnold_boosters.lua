-- Арнольд: 3. Бустеры
-- Арнольд ненадолго испаряется (неуязвим), затем рядом появляются
-- иллюзии-бустеры. С шардом каст ещё и применяет к Арнольду
-- обычное развеивание.

arnold_boosters = class({})

LinkLuaModifier("modifier_arnold_boosters_vanish", "abilities/arnold_boosters", LUA_MODIFIER_MOTION_NONE)

function arnold_boosters:OnSpellStart()
    local caster = self:GetCaster()

    -- Шард: обычное развеивание с Арнольда
    if caster:HasModifier("modifier_item_aghanims_shard") then
        caster:Purge(false, true, false, false, false)
    end

    caster:AddNewModifier(caster, self, "modifier_arnold_boosters_vanish", {
        duration = self:GetSpecialValueFor("vanish_duration")
    })

    caster:EmitSound("DOTA_Item.Manta.Activate")
end

function arnold_boosters:SpawnBoosters()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() or not caster:IsAlive() then return end

    local illusions = CreateIllusions(caster, caster, {
        outgoing_damage = self:GetSpecialValueFor("outgoing_damage") - 100,
        incoming_damage = self:GetSpecialValueFor("incoming_damage") - 100,
        bounty_base = 0,
        bounty_growth = 0,
        duration = self:GetSpecialValueFor("illusion_duration"),
    }, self:GetSpecialValueFor("images_count"), 108, true, true)

    for _, illusion in pairs(illusions or {}) do
        illusion:SetForwardVector(caster:GetForwardVector())
    end
end

--------------------------------------------------------------------------------
-- ИСПАРЕНИЕ
--------------------------------------------------------------------------------

modifier_arnold_boosters_vanish = class({})

function modifier_arnold_boosters_vanish:IsHidden() return true end
function modifier_arnold_boosters_vanish:IsPurgable() return false end

function modifier_arnold_boosters_vanish:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local fx = ParticleManager:CreateParticle(
        "particles/items2_fx/manta_phase.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )
    ParticleManager:ReleaseParticleIndex(fx)

    parent:AddNoDraw()
end

function modifier_arnold_boosters_vanish:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    if parent and not parent:IsNull() then
        parent:RemoveNoDraw()
    end

    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        ability:SpawnBoosters()
    end
end

function modifier_arnold_boosters_vanish:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end
