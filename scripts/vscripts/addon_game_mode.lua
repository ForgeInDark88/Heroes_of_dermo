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
    }
    for _, sound in ipairs(hero_sounds) do
        PrecacheResource("soundfile", sound, context)
    end

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
