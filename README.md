updates:

Music player works.
command /playsong <song name> works

MAIN!!!
Tried to add a way to limit mob spawning to specific Phases (bacterial blobs = only Phase 0; Amalgamation mobs = Phase 1; Infected mobs = Phases 2 & 3; and so on). The way it should work is:
- "tries to spawn a mod > checks phase > if phase doesn't match, delete self"
HOWEVER!!!!! a BIG exeption is Nexuses.

Nexus: Stationary, support mob that doesn't despawn. They spread an infected biome, converting blocks. When a valid target (player, animal, monster, NPC) is within it's line of sight, it summons more mobs to defend itself.
THIS IS A PROBLEM!!!!

Since Nexuses follow evolution by Stages, they can only spawn as Stage 1! But Stage 1 Nexuses can only spawn Flesh Amalgamations and Blobs! BUT SINCE NEXUSES ONLY SPAWN PHASE 3 ONWARDS, STAGE 1 NEXUS SPAWNS GET DELETED!!!!

So I deviced a trick. Tag mobs spawned by Nexus with a "Nexus" tag. This tag prevents deletion, even if the Phase is like 8.

If you could test it and figure out any bugs (also fix them if you want to and can [pretty please]), I'd be very happy.

With best regards, jawmer :]
