"""The game's faces and charms as the catalog lays them out (game/content/catalog.tsp): their rows
read from game/content/faces.tsp (and the slot files it appends), charm_rows.tsp, by tsp.py, so
a sim or a check takes every number from the rows and never retypes them. A face's id is its
place in the rows, as on disk 2.

    python3 tools/sim/catalog.py            the faces and charms, a line each
    import catalog; catalog.faces(), catalog.charms(), catalog.upgrades()

A row is a dict: id, const (its name in code), the fields as written (name, text, slot, amount,
step, cost, aim, tags, show, picture, weight; a charm's kind, when, mark) and steps, a list of
[op, arg] (arg None for none; a string for a line of its own).
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
CONTENT = os.path.join(REPO, "game", "content")
sys.path.insert(0, HERE)

import tsp  # noqa: E402


def plain(v):
    if isinstance(v, tuple):
        return v[1]
    return [plain(x) for x in v]


def macro_body(path, name):
    forms = tsp.parse(open(path).read())
    imports = {}
    body = None
    for f in forms:
        if not isinstance(f, list) or not f:
            continue
        if f[0] == ("sym", "import"):
            target = f[1][1]
            alias = f[2][1] if len(f) > 2 else target.split("/")[-1]
            imports[alias] = target
        if f[0] == ("sym", "macro") and f[1] == ("sym", name):
            body = f[3]
    return body, imports


def rows_of(module, name="rows"):
    """the rows a (macro rows ...) gives: its quoted list, or the lists an append joins"""
    body, imports = macro_body(os.path.join(CONTENT, module.split("/")[-1] + ".tsp"), name)
    if body and body[0] == ("sym", "append"):
        out = []
        for part in body[1:]:
            if isinstance(part[0], tuple) and part[0][0] == "sym" and part[0][1].endswith(".rows"):
                alias = part[0][1][: -len(".rows")]
                out += rows_of(imports[alias])
            else:
                out += part
        return out
    return body


def row_dict(i, row):
    d = {"id": i, "const": row[0][1]}
    items = row[1:]
    for k in range(0, len(items), 2):
        key = items[k][1][1:]
        v = items[k + 1]
        if key == "steps":
            d[key] = [[plain(s[0]), plain(s[1]) if len(s) > 1 else None] for s in v]
        else:
            d[key] = plain(v)
    return d


def faces():
    return [row_dict(i, r) for i, r in enumerate(rows_of("content/faces"))]


def charms():
    return [row_dict(i, r) for i, r in enumerate(rows_of("content/charm_rows"))]


def upgrades():
    """the six upgrade cards' weights, wand to trick"""
    body, _ = macro_body(os.path.join(CONTENT, "faces.tsp"), "upgrades")
    return [v[1] for v in body]


def main():
    for f in faces():
        print("face %2d %-17s %-5s %3d +%d cost %d %-4s weight %d  %s" % (
            f["id"], f["name"], f["slot"], f["amount"], f["step"], f["cost"], f["aim"],
            f["weight"], f["text"]))
    print("upgrades", upgrades())
    for c in charms():
        print("charm %2d %-17s %-9s %d %-11s weight %d  %s" % (
            c["id"], c["name"], c["kind"], c["amount"], c["when"], c["weight"], c["text"]))


if __name__ == "__main__":
    main()
