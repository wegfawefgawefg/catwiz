# each fight's palette: the backdrop's roles to colours, its zone (the fighters' lighting,
# light.py), its variant of the forest and who is in it. Fights 1-4 are the day: a small
# palette each, high key, the darks kept to small pieces.
#
# three tiers: the paper (white, the light blue band and far wood), the ground (aqua, one
# flat colour), and the fighters' darks. Yellow is the sun and the hud's focus only. The
# crowns' ramp hue-shifts: green in the shade, aqua in the light.

from dhgr import (BLACK, MAGENTA, DBLUE, PURPLE, DGREEN, GREY, MBLUE, LBLUE, BROWN, ORANGE,
                  PINK, GREEN, YELLOW, AQUA, WHITE)

DAY = dict(band=LBLUE, paper=WHITE, sun=YELLOW, sun_rim=WHITE, cloud=LBLUE, far=LBLUE,
           leaf=(GREEN, AQUA, AQUA), cuts=(0.3, 0.5), trunk=GREEN, grass=AQUA, horizon=GREEN,
           tuft=GREEN, flower=(PINK, WHITE), path=WHITE, pebble=GREY, water=LBLUE, glint=WHITE,
           bank=GREEN, stone=GREY, frame=BLACK, shadow=BLACK)

# fight 4, the afternoon on the way to dusk: the band and the cloud go pink, the sun lower
# and orange-rimmed, black trunks close in
AFTERNOON = dict(DAY, band=PINK, cloud=PINK, sun_rim=ORANGE, flower=(YELLOW, PINK))

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
