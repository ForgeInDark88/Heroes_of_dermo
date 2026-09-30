LinkLuaModifier(
    "modifier_qop_steal_intellect",
    "abilities/qop_steal_intellect.lua",
    LUA_MODIFIER_MOTION_NONE
)

qop_steal_intellect = class({})

function qop_steal_intellect:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    print("[QOP] OnSpellStart")

    if not target then
        print("[QOP] ERROR: target is nil")
        return
    end

    if target:TriggerSpellAbsorb(self) then
        print("[QOP] Spell absorbed")
        return
    end

    -- Получаем интеллект цели
    local intellect = target:GetIntellect(false)

    print("[QOP] Target: " .. target:GetUnitName())
    print("[QOP] Target INT: " .. tostring(intellect))

    if intellect <= 0 then
        print("[QOP] Target has no INT")
        return
    end

    -- Передаём количество украденного INT модификатору
    target:AddNewModifier(
        caster,
        self,
        "modifier_qop_steal_intellect",
        {
            duration = 6,
            stolen_intellect = intellect
        }
    )

    EmitSoundOn("qopskill", target)

    print("[QOP] INT stolen for 6 seconds: " .. tostring(intellect))
end


modifier_qop_steal_intellect = class({})

function modifier_qop_steal_intellect:IsHidden()
    return false
end

function modifier_qop_steal_intellect:IsPurgable()
    return false
end

function modifier_qop_steal_intellect:OnCreated(kv)
    if not IsServer() then
        return
    end

    self.stolen_intellect = tonumber(kv.stolen_intellect) or 0

    print(
        "[QOP] Modifier created. Stolen INT: "
        .. tostring(self.stolen_intellect)
    )
end

function modifier_qop_steal_intellect:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }
end

function modifier_qop_steal_intellect:GetModifierBonusStats_Intellect()
    return -self.stolen_intellect
end

function modifier_qop_steal_intellect:OnDestroy()
    if not IsServer() then
        return
    end

    print(
        "[QOP] INT steal ended. Restoring: "
        .. tostring(self.stolen_intellect)
    )
end