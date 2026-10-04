LinkLuaModifier(
    "modifier_stray228_snaiping",
    "abilities/stray228_snaiping.lua",
    LUA_MODIFIER_MOTION_NONE
)

--------------------------------------------------------------------------------
-- СНАЙПИНГ: вешает на цель "трек" - цель видна на карте ВСЕМ командам
--------------------------------------------------------------------------------

stray228_snaiping = class({})

function stray228_snaiping:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target then
        return
    end

    if target:TriggerSpellAbsorb(self) then
        return
    end

    target:AddNewModifier(
        caster,
        self,
        "modifier_stray228_snaiping",
        {
            duration = self:GetSpecialValueFor("track_duration")
        }
    )

    local damage = self:GetSpecialValueFor("damage")

    if damage > 0 then
        ApplyDamage({
            victim = target,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })
    end

    EmitSoundOn("Hero_BountyHunter.Target", target)

    print("[STRAY228] Snaiping: tracking " .. target:GetUnitName())
end

--------------------------------------------------------------------------------
-- Трек
--------------------------------------------------------------------------------

modifier_stray228_snaiping = class({})

function modifier_stray228_snaiping:IsHidden()
    return false
end

function modifier_stray228_snaiping:IsDebuff()
    return true
end

function modifier_stray228_snaiping:IsPurgable()
    return true
end

function modifier_stray228_snaiping:OnCreated()
    if not IsServer() then
        return
    end

    local ability = self:GetAbility()

    self.vision_radius = ability and ability:GetSpecialValueFor("vision_radius") or 400
    self.ping_interval = ability and ability:GetSpecialValueFor("ping_interval") or 3
    self.tick = 0.5
    self.ping_timer = 0

    self:RevealToEveryone()
    self:StartIntervalThink(self.tick)
end

function modifier_stray228_snaiping:OnIntervalThink()
    self:RevealToEveryone()
end

function modifier_stray228_snaiping:RevealToEveryone()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
        return
    end

    local position = parent:GetAbsOrigin()
    local parentTeam = parent:GetTeamNumber()

    self.ping_timer = self.ping_timer - self.tick
    local doPing = self.ping_timer <= 0

    if doPing then
        self.ping_timer = self.ping_interval
    end

    for team = DOTA_TEAM_FIRST, DOTA_TEAM_COUNT - 1 do
        if team ~= parentTeam then
            -- Вижен вокруг цели для всех остальных команд
            AddFOWViewer(team, position, self.vision_radius, self.tick + 0.1, false)

            -- Пинг на миникарте, чтобы все видели где цель
            if doPing then
                MinimapEvent(
                    team,
                    parent,
                    position.x,
                    position.y,
                    DOTA_MINIMAP_EVENT_HINT_LOCATION,
                    2
                )
            end
        end
    end
end

function modifier_stray228_snaiping:CheckState()
    -- Под треком нельзя спрятаться в инвиз
    return {
        [MODIFIER_STATE_INVISIBLE] = false
    }
end

function modifier_stray228_snaiping:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
    }
end

function modifier_stray228_snaiping:GetModifierProvidesFOWVision()
    return 1
end

function modifier_stray228_snaiping:GetPriority()
    return MODIFIER_PRIORITY_HIGH
end

function modifier_stray228_snaiping:GetEffectName()
    return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_shield.vpcf"
end

function modifier_stray228_snaiping:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
