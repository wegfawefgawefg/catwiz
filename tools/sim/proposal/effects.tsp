; PROPOSAL (tools/sim, docs/balance.md): the constants of game/content/effects.tsp for the
; item-slot model. Only the constants: the match arms for the new effect kinds are described in
; docs/balance.md (and played by tools/sim/rules.py); this file does not replace the game's.

(const MOST_MANA u8 5)
(const FLEA_TURNS u8 3)
(const HAIRBALL_FLEAS u8 2)
(const ZOOMIES_HITS u8 5)
(const SCREAM_SELF u8 1)
(const TRAP_BACK u8 3)  ; belly rub trap: what whoever hits you takes back
(const SPIKY_BACK u8 1) ; spiky fluff: the same
(const YARN_FLEAS u8 1) ; yarn wand: the fleas it leaves
