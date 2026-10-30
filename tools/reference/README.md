# Reference scripts

While prototyping, these read the owner's own install of Dog Witch (Steam, Unity) to look at
how the original's battle screen, characters and card data are put together. Nothing they
wrote is in the repo or in the game: their output went to `data/extracted/` and
`mockup/out/`, both gitignored. The game does not use them. They need UnityPy, numpy and
Pillow, and the install path at the top of each.

- `survey.py`: counts the Unity object types in each asset file.
- `dump_strings.py`: prints the string fields of every MonoBehaviour.
- `find_cards.py`: finds the MonoBehaviours that hold card data and tries to read them.
- `unity_assets.py`: finds a prefab by name and returns its mesh parts in world space with their
  colours.
- `raster.py`: a small numpy z-buffer rasteriser for those parts.
- `prefab_render.py`: renders characters and a forest battle from those parts at Apple II
  screen sizes, for silhouette and proportion reference while drawing our own art; its contact
  sheet puts the owner's private screenshots of the original (outside the repo) along the top.
- `mesh_render.py`: exports chosen meshes to OBJ and renders flat-shaded previews.
