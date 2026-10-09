-- Main entry point for the custom game.
-- Keep the startup path simple so the gamemode can initialize reliably.

require('internal/util')
print('[CUSTOM_GAME] loading gamemode.lua')
require('gamemode')
print('[CUSTOM_GAME] gamemode.lua loaded')

function Precache(context)
    print('[CUSTOM_GAME] Precache()')

    -- Original Barebones/custom-game precache restored.
    PrecacheResource("particle", "particles/econ/items/pudge/hungry_clown/hungry_clown_rot_body.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)

    PrecacheResource("particle", "particles/units/heroes/hero_razor/razor_ambient_g.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_razor/razor_static_link.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_morphling/morphling_waveform.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_pudge/pudge_rot.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf", context)

    PrecacheResource("model", "models/items/invoker/dark_artistry/dark_artistry_hair_model.vmdl", context)

    PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf", context)
    PrecacheResource("model", "models/creeps/neutral_creeps/n_creep_gnoll/n_creep_gnoll_frost.vmdl", context)
    PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_suicide.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_lich/lich_gaze.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_tinker/tinker_laser.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf", context)
    
    PrecacheResource("particle", "particles/items3_fx/mango_consume.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_furion/furion_sprout_damage_aoe.vpcf", context)
    
    PrecacheResource("particle", "particles/econ/items/dark_seer/dark_seer_imperious/dark_seer_imperious_back_flashes_glow_b.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_sandking/sandking_epicenter_ambient.vpcf", context)
    
    PrecacheResource("particle", "particles/econ/items/tuskarr/tusk_ti9_immortal/tusk_ti9_walruspunch_start_fishes.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_enigma/enigma_base_attack.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero_mid.vpcf", context)

    PrecacheResource("particle", "particles/items_fx/ogre_seal_totem_smash_flash.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_venomancer/venomancer_venomous_gale_mouth.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_rage_bkb01.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_marci/marci_rebound.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf", context)
    
  
    PrecacheResource("particle", "particles/units/heroes/hero_marci/marci_companion_run.vpcf", context)
    PrecacheResource("particle",   "particles/units/heroes/hero_marci/marci_unleash.vpcf", context)
   
    PrecacheResource("model",  "models/heroes/queenofpain/queenofpain.vmdl", context)
    
    PrecacheResource("model",  "models/heroes/enigma/eidelon.vmdl", context)

    PrecacheResource(
    "particle",
    "particles/econ/generic/generic_buff_1/generic_buff_1.vpcf",
    context
    )

    -- Эффекты и звуки способностей героев (балансные изменения)
    local hero_particles = {
        "particles/generic_gameplay/generic_break.vpcf",
        "particles/generic_gameplay/generic_disarm.vpcf",
        "particles/generic_gameplay/generic_hit_blood.vpcf",
        "particles/generic_gameplay/generic_silence.vpcf",
        "particles/generic_gameplay/generic_stunned.vpcf",
        "particles/items2_fx/teleport_end.vpcf",
        "particles/items_fx/black_king_bar_avatar.vpcf",
        "particles/units/heroes/hero_brewmaster/brewmaster_cinder_brew_debuff.vpcf",
        "particles/units/heroes/hero_phoenix/phoenix_supernova_rebirth.vpcf",
        "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf",
        "particles/units/heroes/hero_razor/razor_rain_storm.vpcf",
        "particles/units/heroes/hero_siren/siren_net.vpcf",

        -- Предметы
        "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf",
        "particles/items2_fx/veil_of_discord.vpcf",
        "particles/items2_fx/veil_of_discord_debuff.vpcf",
        "particles/items3_fx/octarine_core_lifesteal.vpcf",
        "particles/items_fx/bottle.vpcf",

        -- Арнольд
        "particles/generic_gameplay/generic_manaburn.vpcf",
        "particles/units/heroes/hero_mars/mars_spear.vpcf",
        "particles/units/heroes/hero_mars/mars_spear_impact_debuff.vpcf",
        "particles/items4_fx/nullifier_mute_debuff.vpcf",
        "particles/items2_fx/manta_phase.vpcf",
        "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf",
        "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf",
        "particles/units/heroes/hero_wisp/wisp_relocate_channel.vpcf",
        "particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf",
        "particles/units/heroes/hero_wisp/wisp_relocate_marker.vpcf",

        -- Русик
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_base_attack.vpcf",
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison.vpcf",
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison_end_dmg.vpcf",
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf",
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf",
        "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf",
        "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf",
        "particles/status_fx/status_effect_medusa_stone_gaze.vpcf",
        "particles/units/heroes/hero_mars/mars_arena_of_blood.vpcf",
        "particles/generic_gameplay/lasthit_coins.vpcf",
        "particles/items3_fx/warmage.vpcf",
        "particles/items3_fx/warmage_recipient.vpcf",
        "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_debuff.vpcf",
        "particles/status_fx/status_effect_dark_willow_wisp_fear.vpcf",
    }
    for _, particle in ipairs(hero_particles) do
        PrecacheResource("particle", particle, context)
    end

    local hero_sounds = {
        "soundevents/game_sounds_heroes/game_sounds_windrunner.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_leshrac.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_mars.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_queenofpain.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_tiny.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_venomancer.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_marci.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_pudge.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_axe.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_antimage.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_wisp.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_obsidian_destroyer.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_medusa.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_huskar.vsndevts",
        "soundevents/game_sounds_items.vsndevts",
    }
    for _, sound in ipairs(hero_sounds) do
        PrecacheResource("soundfile", sound, context)
    end

    -- Юниты, которых создают способности героев
    PrecacheUnitByNameSync("npc_dota_creature_cat", context)          -- Котик Супрунова
    PrecacheUnitByNameSync("npc_dota_custom_creeper1", context)       -- Ебанный брат Попчика
    PrecacheUnitByNameSync("npc_suprunov_ender_eidolon", context)     -- Эндер Вася
    PrecacheUnitByNameSync("npc_alko_guild", context)                 -- Гильдия алкашей
    PrecacheResource("model", "models/props_structures/radiant_ranged_barracks001.vmdl", context)
    PrecacheResource("particle", "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf", context)
    PrecacheResource("model", "models/creeps/neutral_creeps/n_creep_worg_small/n_creep_worg_small.vmdl", context)

    -- STRAY228 + ивент Теневого правительства
    PrecacheUnitByNameSync("npc_stray228_boss", context)
    PrecacheUnitByNameSync("npc_shadow_gov_agent", context)
    PrecacheUnitByNameSync("npc_shadow_gov_sniper", context)
    PrecacheUnitByNameSync("npc_shadow_gov_head", context)
    PrecacheResource("particle", "particles/units/heroes/hero_enigma/enigma_blackhole.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_shield.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enigma.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_bounty_hunter.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_slardar.vsndevts", context)

end

function Activate()
    print('[CUSTOM_GAME] Activate()')

    if GameRules.GameMode ~= nil then
        print('[CUSTOM_GAME] GameMode already exists; skipping duplicate initialization')
        return
    end

    GameRules.GameMode = GameMode()
    GameRules.GameMode:_InitGameMode()

    print('[CUSTOM_GAME] GameMode initialized')
end
