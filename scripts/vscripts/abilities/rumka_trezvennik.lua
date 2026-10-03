LinkLuaModifier(
    "modifier_rumka_trezvennik",
    "abilities/rumka_trezvennik",
    LUA_MODIFIER_MOTION_NONE
)

rumka_trezvennik = class({})

function rumka_trezvennik:Precache(context)

    PrecacheResource(
        "particle",
        "particles/items_fx/black_king_bar_avatar.vpcf",
        context
    )

    PrecacheResource(
        "soundfile",
        "soundevents/game_sounds_heroes/game_sounds_pudge.vsndevts",
        context
    )
end

function rumka_trezvennik:OnSpellStart()

    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    local talent = caster:FindAbilityByName("special_bonus_unique_rumka_trezvennik_dispel")
    if talent and talent:GetLevel() > 0 then
        -- сильный диспел: только дебаффы, со станами
        caster:Purge(false, true, false, true, true)
    end

    --------------------------------------------------
    -- МОДИФИКАТОР
    --------------------------------------------------

    caster:AddNewModifier(
        caster,
        self,
        "modifier_rumka_trezvennik",
        {
            duration = duration
        }
    )

    --------------------------------------------------
    -- ЗВУК
    --------------------------------------------------

    EmitSoundOn(
        "mog",
        caster
    )
end


--------------------------------------------------
-- MODIFIER
--------------------------------------------------

modifier_rumka_trezvennik = class({})

function modifier_rumka_trezvennik:IsHidden() return false end
function modifier_rumka_trezvennik:IsPurgable() return false end

function modifier_rumka_trezvennik:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }
end

function modifier_rumka_trezvennik:GetAbsoluteNoDamageMagical() return 1 end
function modifier_rumka_trezvennik:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_rumka_trezvennik:GetAbsoluteNoDamagePure() return 1 end


--------------------------------------------------
-- EFFECT
--------------------------------------------------

function modifier_rumka_trezvennik:OnCreated()

    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    self.trezvennik_fx = ParticleManager:CreateParticle(
        "particles/items_fx/black_king_bar_avatar.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )

    self:AddParticle(
        self.trezvennik_fx,
        false,
        false,
        -1,
        false,
        false
    )
end


--------------------------------------------------
-- DESTROY
--------------------------------------------------

function modifier_rumka_trezvennik:OnDestroy()

    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    StopSoundOn(
        "mog",
        parent
    )
end