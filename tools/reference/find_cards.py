# finds MonoBehaviours whose bytes contain a known card name and tries to read their fields
import UnityPy
root = "/media/vega/mdot2b/SteamLibrary/steamapps/common/DOG WITCH/DOG WITCH_Data"
env = UnityPy.load(f"{root}/resources.assets")
hits = 0
for o in env.objects:
    if o.type.name != "MonoBehaviour":
        continue
    raw = o.get_raw_data()
    if b"ELF TWIG" not in raw and b"Yo-Yo" not in raw and b"YO-YO" not in raw:
        continue
    hits += 1
    print("path_id", o.path_id, "bytes", len(raw), "typetree", o.serialized_type.node is not None if o.serialized_type else None)
    try:
        tree = o.read_typetree()
        print({k: (v if not isinstance(v, (list, dict)) else type(v).__name__) for k, v in list(tree.items())[:40]})
    except Exception as e:
        print("no typetree:", type(e).__name__, str(e)[:120])
        print(raw[:400])
    if hits >= 3:
        break
print("hits", hits)
