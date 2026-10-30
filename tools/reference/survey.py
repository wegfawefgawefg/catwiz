# counts Unity object types per asset file in the owner's Dog Witch install
import collections, sys, UnityPy
root = "/media/vega/mdot2b/SteamLibrary/steamapps/common/DOG WITCH/DOG WITCH_Data"
for name in ["resources.assets", "sharedassets2.assets", "sharedassets0.assets", "sharedassets1.assets"]:
    env = UnityPy.load(f"{root}/{name}")
    kinds = collections.Counter(o.type.name for o in env.objects)
    print(name, dict(kinds.most_common(12)))
