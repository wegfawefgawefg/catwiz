# every fighter figure the game draws: its drawing, its frames, the frame that answers each
# role the engine asks for (battle/look.tsp), and the small sprites its moves throw or play
# (content/shows.tsp, a show with FOE: its sprites are the mover's shot roles).
#
# A block is a figure's frames as one run of sprites (its runs one block a half, unpacked
# together, draw/blit.tsp). A kind is a role table: each block is one, and a kind may also
# borrow another's block (the possum that faked it, the Bulldog King's later phases): its roles
# name frames of that block, so a phase costs only the frames it adds.
#
# Each figure is drawn where it stands: x the pixel of its middle (any: the game puts it at
# its spot's column), feet the row under its feet (the same ground for everyone, 108).

import beasts
import cat
import foes

ROLE_NAMES = ["idle", "attack", "hurt", "happy", "surprised", "flap", "flash", "shot", "shot2"]


class Block:
    # frames: drawn by draw(frame) (a Canvas in materials); shots: small masked sprites (rows
    # of letters, game_sprites.SHOW_KEY); flash: the frame the white flash is cut from
    def __init__(self, name, draw, frames, flash=None, shots=(), align=False):
        self.align = align  # drawn where its boxes take the fewest bytes (game_sprites)
        self.name = name
        self.draw = draw
        self.frames = list(frames)
        self.flash = flash
        self.shots = list(shots)  # [(name, rows)]


class Kind:
    # a role table over block's frames: roles maps a role to a frame (or shot) name of the
    # block; a role it does not name shows the kind's idle frame
    def __init__(self, name, block, roles):
        self.name = name
        self.block = block
        self.roles = roles


BLOCKS = {}
KINDS = {}


def block(name, draw, frames, flash=None, shots=(), roles=None, flyer=False, align=True):
    b = Block(name, draw, frames, flash, shots, align)
    BLOCKS[name] = b
    roles = dict(roles or {})
    roles.setdefault("idle", frames[0])
    roles.setdefault("flash", "flash")
    if flyer:
        roles.setdefault("flap", "flap")
    KINDS[name] = Kind(name, name, roles)
    return b


def borrow(name, owner, roles):
    roles = dict(roles)
    roles.setdefault("flash", "flash")
    KINDS[name] = Kind(name, owner, roles)


def at(fn, x, feet):
    return lambda frame: fn(x, feet, frame)


# the hero
block("cat", at(cat.cat, 30, 108), cat.FRAMES, flash="hit",
      roles={"attack": "attack", "hurt": "hit", "happy": "meow", "surprised": "ears"}, align=False)

# the woods
block("puffcap", at(foes.puffcap, 91, 108), foes.FRAMES["puffcap"], flash="hurt",
      roles={"attack": "attack", "hurt": "hurt"}, align=False)
block("sporelet", at(foes.sporelet, 124, 106), foes.FRAMES["sporelet"], flash="hurt",
      roles={"attack": "attack", "hurt": "hurt"}, align=False)
block("nightflap", at(foes.nightflap, 115, 44), foes.FRAMES["nightflap"], flash="hurt",
      roles={"attack": "attack", "hurt": "hurt"}, flyer=True, align=False)
block("shroom", at(foes.shroom, 75, 108), foes.FRAMES["shroom"], flash="hurt",
      roles={"attack": "attack", "hurt": "hurt"}, align=False)
block("squirrel", at(beasts.squirrel, 60, 108), beasts.FRAMES["squirrel"], flash="hurt",
      shots=beasts.SHOTS["squirrel"],
      roles={"attack": "attack", "hurt": "hurt", "shot": "acorn", "shot2": "die"})
block("possum", at(beasts.possum, 70, 108), beasts.FRAMES["possum"], flash="hurt",
      shots=beasts.SHOTS["possum"],
      roles={"attack": "attack", "hurt": "hurt", "shot": "bite"})
# the possum that faked it: up again, on the possum's block (its hurt the same playing dead)
borrow("possum_up", "possum", {"idle": "up", "attack": "up_attack", "hurt": "hurt", "shot": "smack"})


def frame_names(b):
    # a block's sprites in order: its frames, its flash, its shots
    return b.frames + ["flash"] + [n for n, _ in b.shots]


def is_flyer(kind):
    return "flap" in KINDS[kind].roles
