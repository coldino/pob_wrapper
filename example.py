from pathlib import Path
from pprint import pprint

from pob_wrapper import PathOfBuilding

TEST_ITEM_1 = r'''
Rarity: Rare
Hypnotic Circle
Opal Ring
--------
Requirements:
Level: 80
--------
Item Level: 80
--------
Your Meteor Towers drop an additional Meteor
--------
24% increased Elemental Damage (implicit)
--------
+48 to Intelligence
Adds 21 to 40 Fire Damage to Attacks
+46 to maximum Energy Shield
+15% to all Elemental Resistances
+17 to Strength and Intelligence (crafted)
--------
Note: ~price 4 exa
'''


def run():
    pob_install = r'D:\Programs\PathOfBuilding'
    pob_path = r'D:\Programs\PathOfBuilding'  # or %ProgramData%\Path of Building` for installed version

    pob = PathOfBuilding(pob_path, pob_install)

    builds_path = pob.get_builds_dir()
    print("POB Builds:", builds_path)

    print('\nLoading build:')
    pob.load_build(rf'{builds_path}\Experiment\ZioniclesExperiment.xml')
    pprint(pob.get_build_info())

    print('\nUpdating build:')
    pob.update_build()

    mod = "10% increased Intelligence"
    print('\nTesting single mod effects:', mod)
    pprint(pob.test_mod_effect(mod))

    print('\nGenerating HTML from item effects test: ./test-item1.html')
    Path('test-item1.html').write_text(pob.test_item_as_html(TEST_ITEM_1))

    print('\nFetch data directly from Lua:')
    print('  build.spec.curAscendClassName = ', end='')
    pprint(pob.fetch('build.spec.curAscendClassName'))

    # `pob` is killed automatically

    return pob


if __name__ == '__main__':
    pob = run()
