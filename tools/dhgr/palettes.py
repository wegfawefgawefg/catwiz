# each fight's palette: the backdrop's roles to colours, its zone (the fighters' lighting,
# light.py), its variant of the forest and who is in it. Fights 1-4 are the day: a small
# palette each, high key, the darks kept to small pieces.
#
# ramps (shade to light) hue-shift: the leaves go dark green > green > aqua (cooler in the
# light, the sky's colour), the sun yellow; shadows on the meadow are green, not grey.

from dhgr import (BLACK, MAGENTA, DBLUE, PURPLE, DGREEN, GREY, MBLUE, LBLUE, BROWN, ORANGE,
                  PINK, GREEN, YELLOW, AQUA, WHITE)

DAY = dict(sky=LBLUE, haze=WHITE, cloud=WHITE, cloud_sh=LBLUE, far=LBLUE,
           leaf_far=(LBLUE, LBLUE, LBLUE), cuts_far=(0.28, 0.6),
           leaf_near=(DGREEN, GREEN, AQUA), cuts_near=(0.12, 0.42),
           trunk=DGREEN, grass=AQUA, grass_sh=GREEN, sun=YELLOW, flower=(WHITE, PINK, YELLOW),
           path=YELLOW, path_sh=WHITE, water=LBLUE, water_sh=MBLUE, glint=WHITE, stone=GREY)

# fight 4 is the afternoon: the leaves' tops catch a yellow light and the cloud's belly
# goes pink, towards dusk
AFTERNOON = dict(DAY, cloud_sh=PINK, leaf_near=(DGREEN, GREEN, AQUA, YELLOW),
                 cuts_near=(0.12, 0.42, 0.82), flower=(YELLOW, PINK, WHITE))

FIGHTS = [
    dict(n=1, variant="clearing", P=DAY, zone="day", foes=["puffcap", "sporelet"]),
    dict(n=2, variant="path", P=DAY, zone="day", foes=["puffcap", "sporelet", "nightflap"]),
    dict(n=3, variant="brook", P=DAY, zone="day", foes=["sporelet", "nightflap"]),
    dict(n=4, variant="thicket", P=AFTERNOON, zone="day", foes=["puffcap", "sporelet", "nightflap"]),
]


def used(P):
    # the colours a palette can put down
    out = set()
    for k, v in P.items():
        if k.startswith("cuts"):
            continue
        out |= set(v) if isinstance(v, tuple) else {v}
    return out
