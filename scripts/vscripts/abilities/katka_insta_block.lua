-- Катька: 3. Инста блок
-- Катька блокирует вражеского героя: он получает магический урон в процентах
-- от своего максимального здоровья и обезоружен на время.
-- Шард: блок ещё и накладывает безмолвие на то же время.

katka_insta_block = class({})

LinkLuaModifier("modifier_katka_insta_block", "abilities/katka_insta_block", LUA_MODIFIER_MOTION_NONE)

local function HasShard(caster)
    return caster and not caster:IsNull() and caster:HasModifier("modifier_item_aghanims_shard")
end

function katka_insta_block:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    if target:TriggerSpellAbsorb(self) then return end

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = target:GetMaxHealth() * self:GetSpecialValueFor("damage_pct") / 100,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self,
    })

    target:AddNewModifier(caster, self, "modifier_katka_insta_block", {
        duration = self:GetSpecialValueFor("block_duration")
    })

    target:EmitSound("Hero_Silencer.LastWord.Damage")
end

modifier_katka_insta_block = class({})

function modifier_katka_insta_block:IsHidden() return false end
function modifier_katka_insta_block:IsDebuff() return true end
function modifier_katka_insta_block:IsPurgable() return true end

function modifier_katka_insta_block:OnCreated()
    if not IsServer() then return end
    -- Шард учитываем на момент блока; клиенту передаём флаг стаками
    self:SetStackCount(HasShard(self:GetCaster()) and 1 or 0)
end

function modifier_katka_insta_block:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_SILENCED] = self:GetStackCount() == 1,
    }
end

function modifier_katka_insta_block:GetEffectName()
    return "particles/items2_fx/heavens_halberd_debuff.vpcf"
end

function modifier_katka_insta_block:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
