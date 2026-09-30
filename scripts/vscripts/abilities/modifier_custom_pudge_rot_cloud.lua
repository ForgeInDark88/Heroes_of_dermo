modifier_custom_pudge_rot_cloud = class({})

function modifier_custom_pudge_rot_cloud:IsHidden() return true end

function modifier_custom_pudge_rot_cloud:OnCreated()
    if not IsServer() then return end
    
    local ability = self:GetAbility()
    self.radius = ability and ability:GetSpecialValueFor("shard_rot_radius") or 800

    -- Эффект ВОНИ
    self.pfx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_pudge/pudge_rot.vpcf", 
        PATTACH_WORLDORIGIN, 
        nil
    )
    ParticleManager:SetParticleControl(self.pfx, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx, 1, Vector(self.radius, 1, self.radius))

    -- Запуск регулярной проверки врагов в области каждые 0.1 сек
    self:StartIntervalThink(0.1)
end

function modifier_custom_pudge_rot_cloud:OnIntervalThink()
    if not IsServer() then return end
    
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    
    if not caster or caster:IsNull() then return end

    -- Находим всех врагов кастера в радиусе облака
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        parent:GetAbsOrigin(),
        nil,
        self.radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and enemy:IsAlive() then
            enemy:AddNewModifier(caster, ability, "modifier_custom_pudge_rot_debuff", { duration = 0.3 })
        end
    end
end

function modifier_custom_pudge_rot_cloud:OnDestroy()
    if not IsServer() then return end
    if self.pfx then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
        self.pfx = nil
    end
end