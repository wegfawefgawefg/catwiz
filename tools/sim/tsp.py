"""Reads the game's content tables (game/content/*.tsp) for the sim: a small s-expression
reader and an evaluator for the top-level consts and enums, so the sim takes its numbers from
the game and never retypes them.

What it understands: (const NAME type value), (enum Name (a b c)), (struct ...) (skipped),
(make Type :field v ...) to a dict, (make (array T n) v ...) to a list, numbers, strings,
chars, and names: this file's consts, another module's (faces.WAND_3, en.PUFFCAP, after its
(import ... alias)), enum members (ac.Effect.hit to "hit"), state.NOTHING (255). Names it
cannot resolve (the art tiles) stay as their text.
"""

import os
import re

NOTHING = 255


def tokens(text):
    out = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c in " \t\r\n":
            i += 1
        elif c == ";":
            while i < n and text[i] != "\n":
                i += 1
        elif c in "()":
            out.append(c)
            i += 1
        elif c == '"':
            j = i + 1
            s = []
            while text[j] != '"':
                if text[j] == "\\":
                    j += 1
                s.append(text[j])
                j += 1
            out.append(("str", "".join(s)))
            i = j + 1
        elif c == "'":
            # a char: 'x' or '\x'
            if text[i + 1] == "\\":
                out.append(("num", ord(text[i + 2])))
                i += 4
            else:
                out.append(("num", ord(text[i + 1])))
                i += 3
        else:
            j = i
            while j < n and text[j] not in " \t\r\n()":
                j += 1
            word = text[i:j]
            if re.fullmatch(r"-?0x[0-9a-fA-F]+", word):
                out.append(("num", int(word, 16)))
            elif re.fullmatch(r"-?[0-9]+", word):
                out.append(("num", int(word)))
            else:
                out.append(("sym", word))
            i = j
    return out


def parse(text):
    toks = tokens(text)
    pos = 0
    top = []

    def read():
        nonlocal pos
        t = toks[pos]
        pos += 1
        if t == "(":
            items = []
            while toks[pos] != ")":
                items.append(read())
            pos += 1
            return items
        return t

    while pos < len(toks):
        top.append(read())
    return top


class Module:
    """One content file: its consts by name, its enums (name to member list), its imports."""

    def __init__(self, name):
        self.name = name
        self.consts = {}
        self.enums = {}
        self.imports = {}  # alias to module name


class Content:
    """The modules read so far, from the directories given (earlier directories win)."""

    def __init__(self, dirs):
        self.dirs = dirs
        self.modules = {}

    def path(self, modname):
        # modname is like "content/faces"; a content dir holds the files themselves
        base = modname.split("/")[-1] + ".tsp"
        for d in self.dirs:
            p = os.path.join(d, base)
            if os.path.exists(p):
                return p
        return None

    def module(self, modname):
        if modname in self.modules:
            return self.modules[modname]
        m = Module(modname)
        self.modules[modname] = m
        p = self.path(modname)
        if p is None:
            return m
        with open(p) as f:
            forms = parse(f.read())
        for form in forms:
            if not isinstance(form, list) or not form:
                continue
            head = form[0]
            if head == ("sym", "import"):
                target = form[1][1]
                alias = form[2][1] if len(form) > 2 else target.split("/")[-1]
                m.imports[alias] = target
            elif head == ("sym", "enum"):
                m.enums[form[1][1]] = [x[1] for x in form[2]]
        for form in forms:
            if isinstance(form, list) and form and form[0] == ("sym", "const"):
                m.consts[form[1][1]] = self.value(m, form[3])
        return m

    def name(self, m, word):
        if word == "true":
            return True
        if word == "false":
            return False
        if word in m.consts:
            return m.consts[word]
        parts = word.split(".")
        if len(parts) == 2 and parts[0] in m.enums:
            return parts[1]
        if parts[0] == "state":
            if parts[1] == "NOTHING":
                return NOTHING
            return parts[-1]  # state.Aim.foe and the like: the member's name
        if parts[0] in m.imports:
            other = self.module(m.imports[parts[0]])
            rest = ".".join(parts[1:])
            if len(parts) == 3:
                return parts[2]  # an enum member in another module
            if rest in other.consts:
                return other.consts[rest]
        return word

    def value(self, m, form):
        if isinstance(form, tuple):
            kind, v = form
            if kind == "sym":
                return self.name(m, v)
            return v
        head = form[0]
        if head == ("sym", "make"):
            typ = form[1]
            if isinstance(typ, list):
                return [self.value(m, x) for x in form[2:]]
            out = {}
            items = form[2:]
            for k in range(0, len(items), 2):
                out[items[k][1][1:]] = self.value(m, items[k + 1])
            return out
        return [self.value(m, x) for x in form]


def number_after(path, pattern):
    """A literal number in engine code the sim must match (the re-rolls a turn): the first
    match of pattern's group 1, read from the source so it is not retyped."""
    with open(path) as f:
        found = re.search(pattern, f.read())
    return int(found.group(1))
