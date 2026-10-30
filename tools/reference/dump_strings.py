# dumps the readable string fields of every MonoBehaviour in the owner's Dog Witch install:
# one line per object, its Unity length-prefixed strings in order. Reference only; the output
# is never committed.
import struct, UnityPy
root = "/media/vega/mdot2b/SteamLibrary/steamapps/common/DOG WITCH/DOG WITCH_Data"

def strings(raw):
    out, i = [], 0
    while i + 4 <= len(raw):
        n = struct.unpack_from("<i", raw, i)[0]
        if 2 <= n <= 400 and i + 4 + n <= len(raw):
            s = raw[i + 4:i + 4 + n]
            if all(32 <= b < 127 or b in (9, 10) for b in s):
                out.append(s.decode())
                i += 4 + n
                i = (i + 3) & ~3
                continue
        i += 4
    return out

with open("data/extracted/monobehaviour_strings.tsv", "w") as f:
    for name in ["resources.assets", "sharedassets2.assets"]:
        env = UnityPy.load(f"{root}/{name}")
        for o in env.objects:
            if o.type.name != "MonoBehaviour":
                continue
            ss = strings(o.get_raw_data())
            if len(ss) >= 2:
                f.write(f"{name}\t{o.path_id}\t" + "\t".join(s.replace("\t", " ").replace("\n", "\\n") for s in ss) + "\n")
