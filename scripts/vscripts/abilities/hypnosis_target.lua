hypnosis_target = class({})
LinkLuaModifier("modifier_hypnosis_target", "abilities/hypnosis_target", LUA_MODIFIER_MOTION_NONE)

function hypnosis_target:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_hypnosis_target", { duration = duration })
    
    -- Звуковой эффект при применении
    target:EmitSound("musordrop")
end

--------------------------------------------------------------------------------

modifier_hypnosis_target = class({})

function modifier_hypnosis_target:IsHidden() return false end
function modifier_hypnosis_target:IsDebuff() return true end
function modifier_hypnosis_target:IsStunDebuff() return true end
function modifier_hypnosis_target:IsPurgable() return true end

function modifier_hypnosis_target:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    
    self.damage_per_sec = ability:GetSpecialValueFor("damage_per_sec")
    self.slow_pct = ability:GetSpecialValueFor("move_speed_slow_pct")

    -- Принуждаем цель двигаться за кастером
    self.parent:MoveToNPC(self.caster)

    -- Таймер для урона и обновления движения (10 раз в секунду для плавности)
    self.interval = 0.1
    self:StartIntervalThink(self.interval)
end

function modifier_hypnosis_target:OnIntervalThink()
    if not IsServer() then return end

    -- Если кастер или цель погибли — снимаем модификатор
    if not self.caster:IsAlive() or not self.parent:IsAlive() then
        self:Destroy()
        return
    end

    -- Периодически обновляем команду движения за кастером
    self.parent:MoveToNPC(self.caster)

    -- Наносим урон
    local damage = self.damage_per_sec * self.interval
    ApplyDamage({
        victim = self.parent,
        attacker = self.caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })
end

function modifier_hypnosis_target:OnDestroy()
    if not IsServer() then return end
    -- Очищаем приказы после завершения гипноза
    self.parent:Stop()
end

function modifier_hypnosis_target:CheckState()
    return {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true, -- Запрещает игроку управлять юнитом
        [MODIFIER_STATE_SILENCED]           = true, -- Запрещает магию
        [MODIFIER_STATE_MUTED]              = true, -- Запрещает предметы
    }
end

function modifier_hypnosis_target:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_hypnosis_target:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow_pct
end

function modifier_hypnosis_target:GetEffectName()
    return "particles/units/heroes/hero_lich/lich_gaze.vpcf"
end

function modifier_hypnosis_target:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end