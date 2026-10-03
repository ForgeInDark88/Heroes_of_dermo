LinkLuaModifier("modifier_rumka_tolstyy", "abilities/rumka_tolstyy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rumka_tolstyy_reflect", "abilities/rumka_tolstyy", LUA_MODIFIER_MOTION_NONE)

rumka_tolstyy = class({})

function rumka_tolstyy:Precache(context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pudge.vsndevts", context)
    PrecacheResource("particle", "particles/generic_gameplay/generic_hit_blood.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_pudge/pudge_rot.vpcf", context)
end

function rumka_tolstyy:GetIntrinsicModifierName()
    return "modifier_rumka_tolstyy"
end

local function HasShard(caster)
    return caster and not caster:IsNull() and caster:HasModifier("modifier_item_aghanims_shard")
end

-- С шардом скилл становится активным
function rumka_tolstyy:GetBehavior()
    if HasShard(self:GetCaster()) then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    end
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function rumka_tolstyy:GetCooldown(level)
    if HasShard(self:GetCaster()) then
        return self:GetSpecialValueFor("shard_cooldown")
    end
    return 0
end

function rumka_tolstyy:GetManaCost(level)
    if HasShard(self:GetCaster()) then
        return self:GetSpecialValueFor("shard_mana")
    end
    return 0
end

function rumka_tolstyy:OnSpellStart()
    local caster = self:GetCaster()
    caster:RemoveModifierByName("modifier_rumka_tolstyy_reflect")
    caster:AddNewModifier(caster, self, "modifier_rumka_tolstyy_reflect", {
        duration = self:GetSpecialValueFor("shard_duration")
    })
    -- звук теперь запускается в OnCreated модификатора
end

--------------------------------------------------------------------------------
-- Пассивный блок (как было)
--------------------------------------------------------------------------------

modifier_rumka_tolstyy = class({})

function modifier_rumka_tolstyy:IsHidden() return false end
function modifier_rumka_tolstyy:IsPurgable() return false end
function modifier_rumka_tolstyy:IsDebuff() return false end

function modifier_rumka_tolstyy:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK }
end

function modifier_rumka_tolstyy:GetModifierPhysical_ConstantBlock(params)
    local parent = self:GetParent()
    if parent:PassivesDisabled() then return 0 end

    local ability = self:GetAbility()
    if not ability then return 0 end

    local chance = ability:GetSpecialValueFor("block_chance")
    local block = ability:GetSpecialValueFor("damage_block")

    if RandomInt(1, 100) <= chance then
        EmitSoundOn("Hero_Pudge.AttackHookImpact", parent)

        local fx = ParticleManager:CreateParticle(
            "particles/generic_gameplay/generic_hit_blood.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            parent
        )
        ParticleManager:SetParticleControl(fx, 0, parent:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(fx)

        return block
    end
    return 0
end

--------------------------------------------------------------------------------
-- Шард: аура говна и мочи, отражает урон
--------------------------------------------------------------------------------

modifier_rumka_tolstyy_reflect = class({})

function modifier_rumka_tolstyy_reflect:IsHidden() return false end
function modifier_rumka_tolstyy_reflect:IsPurgable() return false end
function modifier_rumka_tolstyy_reflect:GetTexture() return "pudge_rot" end

function modifier_rumka_tolstyy_reflect:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Hero_Pudge.Rot", parent)

    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_pudge/pudge_rot.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )
    ParticleManager:SetParticleControl(fx, 1, Vector(250, 0, 0))
    self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_rumka_tolstyy_reflect:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    if parent and not parent:IsNull() then
        StopSoundOn("Hero_Pudge.Rot", parent)
    end
end

function modifier_rumka_tolstyy_reflect:DeclareFunctions()
    return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_rumka_tolstyy_reflect:OnTakeDamage(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.unit ~= parent then return end

    local attacker = params.attacker
    if not attacker or attacker:IsNull() then return end
    if attacker == parent then return end
    if attacker:GetTeamNumber() == parent:GetTeamNumber() then return end
    if attacker:IsMagicImmune() then return end -- не через БКБ
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then return end
    if params.damage <= 0 then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    local pct = ability:GetSpecialValueFor("shard_reflect_pct") / 100
    local str_mult = ability:GetSpecialValueFor("shard_reflect_str_mult")

    local reflected = params.damage * pct + parent:GetStrength() * str_mult

    ApplyDamage({
        victim = attacker,
        attacker = parent,
        damage = reflected,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = ability,
    })
end