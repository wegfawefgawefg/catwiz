"""Writes the catalog sim's content (gen_content.h) from the game's own files, so every number,
row and step stays in game/content and adding a card needs no sim code:

    python3 tools/sim/cg/gen.py > tools/sim/cg/gen_content.h     (the Makefile does this)

What it reads: the faces' and charms' rows with their steps (tools/sim/catalog.py), the shared
steps, the hooks and Mimic's table (content/cards.tsp), the vocabulary's op bytes
(content/steps.tsp), the statuses (content/statuses.tsp), the enemies, moves and fights
(content/enemies.tsp, moves.tsp, encounters.tsp), the engine numbers it needs (content/cards,
effects, items, state, battle/turn) and the upgrades' weights. A step is compiled to its two
bytes as content/steps.tsp's step_bytes macro does it, except that a say's line (a string or a
table line) is a SAY with no argument: the sim keeps no log text, but a say is still a step (a
coin, has or if_calm skips steps by count).

The domains (docs/faces.md's groups) are the one table here: they are not in the game's rows.
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.dirname(HERE)
sys.path.insert(0, SIM)

import catalog  # noqa: E402
import tsp  # noqa: E402

REPO = os.path.dirname(os.path.dirname(SIM))
GAME = os.path.join(REPO, "game")
CONTENT = os.path.join(GAME, "content")

# docs/faces.md's domains, by name (a card may be in two). Cards in none are generic.
DOMAINS = ["simple", "kittens", "three", "fleas", "wet", "shield", "life", "mana", "dice",
           "chaos", "growth", "gambles"]
DOMAIN_OF = {
    "simple": ["BIG STICK", "THICK FUR", "BRIGHT STAR", "HAIRBALL BLAST", "GLARE",
               "LUCKY COLLAR", "SPARE YARN", "HEAD START"],
    "kittens": ["MEOWCRONOMICON", "FEATHER TOY", "LITTER STAR", "IF IT FITS", "CARDBOARD BOX",
                "MARK TERRITORY", "MOTHER CAT", "KITTEN MITTENS", "LITTER BOX"],
    "three": ["TWIG WAND", "FLUFF", "SPIKY FLUFF", "WARM BLANKET", "STATIC FUR",
              "BELL COLLAR", "PURRFECT TRIO", "CLAW SWIPE", "STAR CLUSTER", "TRIPLE HEX",
              "ECHO"],
    "fleas": ["FLEAS", "FLEA CIRCUS", "SCRATCH THE ITCH", "FLEA COLLAR", "FLEA MARKET",
              "PLAGUE", "FLEA COMB", "ITCHY", "FLEA FARM"],
    "wet": ["SPRAY BOTTLE", "WET", "PUDDLE SPLASH", "MOON TIDE", "RAIN CLOUD",
            "THUNDER PURR", "DRENCHED", "MONSOON", "RAIN BOOTS", "STORM CLOUD"],
    "shield": ["MIRROR FUR", "MOON BOWL", "KNEAD", "FLUFFY TAIL", "BOX SLAM", "PUFFED UP",
               "FORTIFY", "SHIELD BASH", "HAIRBALL WALL", "STONE CAT", "PORCUPINE",
               "THICK COAT"],
    "life": ["NINE LIVES", "LOVE BITE", "CATNAP", "PURR", "BLOOD MOON", "HISS", "LEECH",
             "LAST STAND", "HUNGER", "NINTH LIFE"],
    "mana": ["STAR", "SHOOTING STAR", "WISHING STAR", "ZOOMIES", "STILL WATER", "GRUMPY FACE",
             "BAD MILK", "MOONBEAM", "OVERFLOW", "MANA BURN", "MANA LEECH", "SPELL ECHO",
             "CHEAP TRICK", "MANA BATTERY"],
    "dice": ["RED DOT", "LUCKY PAW", "SUNBEAM", "SCRATCH POST", "SIXTH TOE", "CALM PAW",
             "RATTLE", "FRESH ROLL", "PAW FLIP", "NAP SPOT", "LUCKY SEVEN"],
    "chaos": ["LASER POINTER", "CATFIGHT", "MIMIC", "KNOCK IT OFF", "3 AM SCREAMING",
              "MOUSE ON STRING", "CHAIN BOUNCE", "SPOOK", "HYPNOTIZE", "CATNIP BOMB",
              "LULLABY", "LASER SHOW", "TROUBLEMAKER", "PIED PIPER"],
    "growth": ["SCRATCHING HABIT", "GRUDGE", "SNOWBALL", "SHARPEN CLAWS", "MOMENTUM",
               "THICK SKIN"],
    "gambles": ["DOUBLE OR NOTHING", "COIN FLIP", "ALL IN", "HAT TRICK", "CURSED COIN",
                "JACKPOT"],
}
# the second domain a few cards are in (faces.md lists them twice)
ALSO = {"STATIC FUR": "wet", "CARDBOARD BOX": "three", "WARM BLANKET": "life",
        "LUCKY PAW": "shield", "SUNBEAM": "mana", "STILL WATER": "dice"}

TAG_BITS = {"three": 1, "kittens": 2, "grows": 4, "plus": 8, "times": 16, "none": 32, "hp": 64}

# content/steps.tsp's step_bytes: a step word's op and its argument's kind
KIND_OF = {
    "num": ("NUM", "none"), "lit": ("LIT", "num"), "kits": ("KITS", "num"),
    "get": ("GET", "her"), "t_get": ("GET", "its"), "plus": ("PLUS", "her"),
    "t_plus": ("PLUS", "its"), "half": ("HALF", "none"), "more": ("MORE", "num"),
    "fell": ("FELL", "none"), "landed": ("FELL", "one"), "low": ("LOW", "num"),
    "coin": ("COIN", "num"), "hat": ("HAT", "none"), "t_times": ("TIMES", "its"),
    "least": ("LEAST", "num"), "most": ("MOST", "num"), "kept": ("KEPT", "none"),
    "has": ("IF", "her"), "t_has": ("IF", "its"), "if_up": ("IF_UP", "none"),
    "three": ("THREE", "none"), "calm": ("CALM", "none"), "if_calm": ("CALM", "one"),
    "add": ("ADD", "her"), "t_add": ("ADD", "its"), "set": ("SET", "her"),
    "t_set": ("SET", "its"), "max": ("MAX", "her"), "times": ("TIMES", "her"),
    "sub": ("SUB", "her"), "t_sub": ("SUB", "its"), "mana": ("MANA", "none"),
    "spill": ("SPILL", "none"), "rerolls": ("REROLLS", "none"),
    "no_rerolls": ("REROLLS", "one"), "heal": ("HEAL", "none"), "hit": ("HIT", "none"),
    "pierce": ("PIERCE", "none"), "plain": ("PLAIN", "none"), "hurt": ("HURT", "none"),
    "curse": ("CURSE", "its"), "pounce": ("POUNCE", "none"), "all": ("ALL", "none"),
    "others": ("ALL", "one"), "rep": ("REP", "none"), "end": ("END", "none"),
    "next": ("NEXT", "none"), "pick": ("NEXT", "one"), "retarget": ("RETARGET", "none"),
    "me": ("ME", "none"), "call": ("DO", "sub"), "stop": ("STOP", "none"),
    "back": ("BACK", "none"), "blocked": ("BLOCKED", "none"), "copy": ("COPY", "none"),
    "look": ("MIMIC", "none"), "mimic": ("MIMIC", "one"), "cue": ("CUE", "zero"),
    "say": ("SAY", "zero"), "say_it": ("SAY", "zero"), "say_me": ("SAY", "zero"),
}


def cstr(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def sym(x):
    return x[1] if isinstance(x, tuple) else x


def read_forms(path):
    return tsp.parse(open(path).read())


def statuses():
    """content/statuses.tsp's Status enum (tsp.py cannot read that file: its '(' glyph)"""
    text = open(os.path.join(CONTENT, "statuses.tsp")).read()
    text = re.sub(r";[^\n]*", "", text)
    body = text[text.index("(enum Status (") + len("(enum Status ("):]
    body = body[: body.index(")")]
    names = body.split()
    count = int(re.search(r"\(const STATUS_COUNT u8 (\d+)\)", open(
        os.path.join(CONTENT, "statuses.tsp")).read()).group(1))
    foes = int(re.search(r"\(const FOE_COUNT u8 (\d+)\)", open(
        os.path.join(CONTENT, "statuses.tsp")).read()).group(1))
    assert len(names) == count, (len(names), count)
    return names, foes


def consts_of(path):
    """a file's (const NAME type NUMBER) values"""
    out = {}
    for m in re.finditer(r"\(const (\w+) u8 (0x[0-9a-fA-F]+|\d+)\)", open(path).read()):
        out[m.group(1)] = int(m.group(2), 0)
    return out


def enum_of(forms, name):
    for f in forms:
        if isinstance(f, list) and f and sym(f[0]) == "enum" and sym(f[1]) == name:
            return [sym(x) for x in f[2]]
    raise KeyError(name)


class Compiler:
    def __init__(self):
        self.status, self.foe_count = statuses()
        self.ops = consts_of(os.path.join(CONTENT, "steps.tsp"))
        self.cards = consts_of(os.path.join(CONTENT, "cards.tsp"))
        self.subs = ["ZAP_HIT", "SHIELD", "TANGLE", "WET", "FLEAS"]  # steps.SUB_ order
        for i, s in enumerate(self.subs):
            assert self.ops["SUB_" + s] == i, s

    def num(self, a):
        if isinstance(a, int):
            return a
        name = a.split(".")[-1]
        if name in self.cards:
            return self.cards[name]
        raise KeyError("steps: no number " + a)

    def step(self, word, a):
        if word not in KIND_OF:
            raise KeyError("steps: no step " + word)
        op, kind = KIND_OF[word]
        if isinstance(a, str) and kind == "zero" and word.startswith("say"):
            return [self.ops["SAY"], 0]  # a line of its own: still a step
        if kind in ("none", "zero"):
            return [self.ops[op], 0]
        if kind == "one":
            return [self.ops[op], 1]
        if kind == "num":
            return [self.ops[op], self.num(a)]
        if kind == "her":
            return [self.ops[op], self.status.index(a)]
        if kind == "its":
            return [self.ops[op], self.status.index(a) + 0x80]
        if kind == "sub":
            return [self.ops[op], self.subs.index(a)]
        raise KeyError(kind)

    def row(self, steps):
        out = []
        for word, a in steps:
            out += self.step(word, a)
        out += [self.ops["STOP"], 0]
        return out


def card_rows():
    """content/cards.tsp's (steps.steps NAME ...) rows, in order, as [word, arg] lists"""
    out = []
    for f in read_forms(os.path.join(CONTENT, "cards.tsp")):
        if isinstance(f, list) and f and sym(f[0]) == "steps.steps":
            name = sym(f[1])
            steps = [[sym(s[0]), (sym(s[1]) if len(s) > 1 else None)] for s in f[2:]]
            out.append((name, steps))
    return out


def table_rows(forms, name):
    """a (const NAME (array Struct n) (make (array ...) (make Struct :f v ...) ...)) as dicts"""
    for f in forms:
        if isinstance(f, list) and f and sym(f[0]) == "const" and sym(f[1]) == name:
            out = []
            for item in f[3][2:]:
                d = {}
                fields = item[2:]
                for k in range(0, len(fields), 2):
                    v = fields[k + 1]
                    if isinstance(v, list):  # (addr_of (at ROW 0))
                        v = sym(v[1][1])
                    d[sym(fields[k])[1:]] = sym(v)
                out.append(d)
            return out
    raise KeyError(name)


def main():
    comp = Compiler()
    faces = catalog.faces()
    charms = catalog.charms()
    ups = catalog.upgrades()
    cards_forms = read_forms(os.path.join(CONTENT, "cards.tsp"))
    steps_forms = read_forms(os.path.join(CONTENT, "steps.tsp"))
    action_forms = read_forms(os.path.join(CONTENT, "action.tsp"))
    enc_forms = read_forms(os.path.join(CONTENT, "encounters.tsp"))
    when = enum_of(steps_forms, "When")
    effects = enum_of(action_forms, "Effect")
    slots = enum_of(action_forms, "Slot")
    kinds = enum_of(enc_forms, "CharmKind")

    c = tsp.Content([CONTENT, GAME])
    enemies = c.module("content/enemies")
    en_rows = enemies.consts["ENEMIES"]
    moves = c.module("content/moves").consts["MOVES"]
    enc = c.module("content/encounters")
    fights = enc.consts["FIGHTS"]
    hero = enc.consts["HERO"]
    fx = consts_of(os.path.join(CONTENT, "effects.tsp"))
    items = consts_of(os.path.join(CONTENT, "items.tsp"))
    state = consts_of(os.path.join(GAME, "state.tsp"))
    turn = consts_of(os.path.join(GAME, "battle", "turn.tsp"))
    offer = consts_of(os.path.join(GAME, "battle", "offer.tsp"))
    statuses_c = consts_of(os.path.join(CONTENT, "statuses.tsp"))
    start = re.findall(r"\(catalog\.id (\w+)\)", open(os.path.join(CONTENT, "items.tsp")).read())
    face_id = {f["const"]: f["id"] for f in faces}
    start_ids = [face_id[n] for n in start[-6:]]
    rerolls = int(re.search(r"\(\+ \(- \(\+ (\d+) \(amount enc\.CharmKind\.pocket\)\)",
                            open(os.path.join(CONTENT, "charms.tsp")).read()).group(1))
    hairball = face_id["HAIRBALL"]
    assert hairball == len(faces) - 1

    out = ["/* generated by gen.py from game/content: do not edit */",
           "#ifndef GEN_CONTENT_H", "#define GEN_CONTENT_H", ""]

    def enum(name, prefix, members):
        out.append("enum %s {" % name)
        for m in members:
            out.append("    %s%s," % (prefix, m))
        out.append("    %sCOUNT" % prefix)
        out.append("};")
        out.append("static const char *const %s_NAME[] = {%s};" % (
            name.upper(), ", ".join(cstr(m) for m in members)))

    enum("Status", "ST_", comp.status)
    enum("When", "W_", when)
    enum("Effect", "E_", effects)
    enum("Slot", "S_", slots)
    enum("CharmKind", "K_", kinds)
    enum("Domain", "D_", DOMAINS)
    out.append("enum { A_foe, A_self, A_all, A_friend };")
    for name, v in sorted(comp.ops.items(), key=lambda kv: kv[1]):
        if not name.startswith("SUB_"):
            out.append("#define OP_%s %d" % (name, v))
    for k, v in TAG_BITS.items():
        out.append("#define TAG_%s %d" % (k.upper(), v))

    # the step rows: every face, every charm, then cards.tsp's own
    rows = []
    for f in faces:
        rows.append(("face_" + f["const"], comp.row(f["steps"])))
    for ch in charms:
        rows.append(("charm_" + ch["const"], comp.row(ch["steps"])))
    named = card_rows()
    first_card_row = len(rows)
    for name, steps in named:
        rows.append((name, comp.row(steps)))
    row_index = {name: i for i, (name, _) in enumerate(rows)}
    flat, at = [], []
    for _, b in rows:
        at.append(len(flat))
        flat += b

    consts = [
        ("FACE_COUNT", len(faces)),
        ("CHARM_COUNT", len(charms)),
        ("HAIRBALL_ID", hairball),
        ("ROW_COUNT", len(rows)),
        ("FIRST_CARD_ROW", first_card_row),
        ("FOE_COUNT", comp.foe_count),
        ("MOVE_COUNT", len(moves)),
        ("KIND_COUNT", len(en_rows)),
        ("FIGHT_ROWS", len(fights)),
        ("FIGHT_COUNT", enc.consts["FIGHT_COUNT"]),
        ("HERO_HP", hero["hp"]),
        ("NAP_HEAL_SHIFT", enc.consts["NAP_HEAL_SHIFT"]),
        ("ITEM_MOST", items["ITEM_MOST"]),
        ("HELD_CHARMS", items["HELD_CHARMS"]),
        ("MOST_MANA", statuses_c["MOST_MANA"]),
        ("FLEA_TURNS", comp.cards["FLEA_TURNS"]),
        ("BACK_MOST", comp.cards["BACK_MOST"]),
        ("REROLLS_MOST", comp.cards["REROLLS_MOST"]),
        ("COMBO_AT", fx["COMBO_AT"]),
        ("KITTEN_HIT", fx["KITTEN_HIT"]),
        ("DICE", state["DICE"]),
        ("DICE_MOST", state["DICE_MOST"]),
        ("REROLLS", rerolls),
        ("LUCKY_REROLLS", turn["LUCKY_REROLLS"]),
        ("FACES_DRAWN", offer["FACES_DRAWN"]),
        ("CHARMS_DRAWN", offer["CHARMS_DRAWN"]),
        ("UP_CARD", offer["UP"]),
        ("KING", enemies.consts["KING"]),
        ("KING_3", enemies.consts["KING_3"]),
    ]
    for name, v in consts:
        out.append("#define %s %d" % (name, v))
    for i, s in enumerate(comp.subs):
        out.append("#define SUB_%s %d" % (s, i))
    for name in row_index:
        if row_index[name] >= first_card_row:
            out.append("#define RW_%s %d" % (name, row_index[name]))
    out.append("")
    out.append("static const unsigned char STEP_BYTES[%d] = {%s};" % (
        len(flat), ", ".join(map(str, flat))))
    out.append("static const unsigned short ROW_AT[ROW_COUNT] = {%s};" % ", ".join(map(str, at)))
    out.append("static const char *const ROW_NAME[ROW_COUNT] = {%s};" % ", ".join(
        cstr(n) for n, _ in rows))

    def domains_of(name):
        bits = 0
        for i, d in enumerate(DOMAINS):
            if name in DOMAIN_OF[d]:
                bits |= 1 << i
        if name in ALSO:
            bits |= 1 << DOMAINS.index(ALSO[name])
        return bits

    known = set(f["name"] for f in faces) | set(ch["name"] for ch in charms)
    for d in DOMAINS:
        for n in DOMAIN_OF[d]:
            assert n in known, "domain card not in the game: " + n

    out.append("typedef struct { const char *name, *text; unsigned char slot, amount, step, cost,"
               " aim, tags, weight; unsigned short domains; } FaceRow;")
    out.append("static const FaceRow FACES[FACE_COUNT] = {")
    aims = {"foe": "A_foe", "self": "A_self", "all": "A_all", "friend": "A_friend"}
    for f in faces:
        tags = 0
        for t in f["tags"]:
            tags |= TAG_BITS[t]
        out.append("    {%s, %s, S_%s, %d, %d, %d, %s, %d, %d, %d}," % (
            cstr(f["name"]), cstr(f["text"]), f["slot"], f["amount"], f["step"], f["cost"],
            aims[f["aim"]], tags, f["weight"], domains_of(f["name"])))
    out.append("};")
    for f in faces:
        out.append("#define ID_%s %d" % (f["const"], f["id"]))
    for ch in charms:
        out.append("#define CH_%s %d" % (ch["const"], ch["id"]))
    out.append("typedef struct { const char *name, *text; unsigned char kind, when, amount,"
               " weight; unsigned short domains; } CharmRow;")
    out.append("static const CharmRow CHARMS[CHARM_COUNT] = {")
    for ch in charms:
        out.append("    {%s, %s, K_%s, W_%s, %d, %d, %d}," % (
            cstr(ch["name"]), cstr(ch["text"]), ch["kind"], ch["when"], ch["amount"],
            ch["weight"], domains_of(ch["name"])))
    out.append("};")

    hooks = table_rows(cards_forms, "HOOKS")
    out.append("typedef struct { unsigned char status, when, value; unsigned short row; } HookRow;")
    out.append("#define HOOK_COUNT %d" % len(hooks))
    out.append("static const HookRow HOOKS[HOOK_COUNT] = {%s};" % ", ".join(
        "{ST_%s, W_%s, ST_%s, RW_%s}" % (h["status"].split(".")[-1], h["when"].split(".")[-1],
                                         h["value"].split(".")[-1], h["fx"]) for h in hooks))
    mim = table_rows(cards_forms, "MIMICRY")
    out.append("typedef struct { unsigned char effect, all; unsigned short row; } MimicRow;")
    out.append("#define MIMICRY_COUNT %d" % len(mim))
    out.append("static const MimicRow MIMICRY[MIMICRY_COUNT] = {%s};" % ", ".join(
        "{E_%s, %d, RW_%s}" % (m["effect"].split(".")[-1], 1 if m["all"] in (True, "true") else 0,
                               m["fx"]) for m in mim))
    out.append("static const unsigned short SUBS[%d] = {%s};" % (
        len(comp.subs), ", ".join("RW_" + s for s in comp.subs)))

    out.append("typedef struct { const char *text; unsigned char effect, amount, aim; } MoveRow;")
    out.append("static const MoveRow MOVES[MOVE_COUNT] = {")
    for m in moves:
        out.append("    {%s, E_%s, %d, %s}," % (cstr(m["text"]), m["effect"], m["amount"],
                                                aims[m["aim"]]))
    out.append("};")
    out.append("typedef struct { const char *name; unsigned char hp, ward, first, count, calls,"
               " then, stall; } KindRow;")
    out.append("static const KindRow KINDS[KIND_COUNT] = {")
    for k in en_rows:
        out.append("    {%s, %d, %d, %d, %d, %d, %d, %d}," % (
            cstr(k["name"]), k["hp"], k["ward"], k["first_move"], k["move_count"], k["calls"],
            k["then"], k["stall"]))
    out.append("};")
    out.append("typedef struct { unsigned char count, enemies[3], elite, other, zone; } FightRow;")
    out.append("static const FightRow FIGHTS[FIGHT_ROWS] = {")
    zones = ["woods", "garden", "house"]
    for f in fights:
        en = [s["enemy"] for s in f["spots"]]
        out.append("    {%d, {%s}, %d, %d, %d}," % (
            f["count"], ", ".join(map(str, en)), 1 if f["elite"] else 0, f["other"],
            zones.index(f["zone"])))
    out.append("};")
    out.append("static const unsigned char STARTING_ITEMS[6] = {%s};" % ", ".join(
        map(str, start_ids)))
    out.append("static const unsigned char UPGRADE_WEIGHT[6] = {%s};" % ", ".join(map(str, ups)))
    out.append("")
    out.append("#endif")
    print("\n".join(out))


if __name__ == "__main__":
    main()
