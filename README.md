# Path of Building Wrapper

Allows use of an existing Path of Building installation from a Python application. If you don't know Path of Building is then you don't play Path of Exile and can safely ignore this.

*This is simple initial implementation with limited functionality, but provides a base to build on.*

## Features

* Launch PoB in headless mode as a controllable sub-processes
* Load builds
* Read basic build information
* Updates builds (from pathofexile.com) and attempts to maintain chosen skill
* Test the effect of items (output as HTML)
* Test the effect of individual mod lines (output as diffs to all output stats)


## Example

(taken from [example.py](./example.py))

Fire up Path of Building as a headless sub-process:
```py
pob_install = r'D:\Programs\PathOfBuilding'
pob_path = r'D:\Programs\PathOfBuilding' # or `%ProgramData%\Path of Building` for installed version
pob = PathOfBuilding(pob_path, pob_install)
```

Ask where the builds are stored:
```py
builds_path = pob.get_builds_dir()
```
...returns `C:\Users\<username>\Documents\My Games\Path of Exile\Builds/`

Load a build and get its basic info:
```py
pob.load_build(rf'{builds_path}\Experiment\ZioniclesExperiment.xml')
build_info = pob.get_build_info()
```
Returns:
```js
{'buildName': 'ZioniclesExperiment',
 'char': {'ascendClassName': 'Ascendant', 'className': 'Scion', 'level': 89},
 'file': {'path': 'C:\\Users\\<username>\\Documents\\My Games\\Path of '
                  'Exile\\Builds/\\Experiment\\ZioniclesExperiment.xml',
          'subpath': '\\Experiment\\'}}
```

Test the effect of a single mod line:
```py
mod = "10% increased Intelligence"
effects = pob.test_mod_effect(mod)
```
Returns:
```js
{'AverageDamage': 4114.275,
 'AverageHit': 4114.275,
 'Duration': 0.2175,
 'EnergyShield': 311.0,
...
```

Test the effects of a new item, outputting as HTML:
```py
item = '''
Rarity: Rare
Hypnotic Circle
Opal Ring
--------
24% increased Elemental Damage (implicit)
--------
+48 to Intelligence
--------
Note: ~price 40 exa
'''
Path('test-item1.html').write_text(pob.test_item_as_html(item))
```
...produces something like the page below, although any item copied from a trade website will be handled.

![Item test output](readme_imgs\test_item_1_html.png)


## Things to improve

* Detect where PoB was installed and/or where its data is (ProgramData).
* Provide access to more build & skill data
