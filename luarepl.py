import sys
from pathlib import Path
from pprint import pprint

from prompt_toolkit import PromptSession
from prompt_toolkit import print_formatted_text as print
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.formatted_text import PygmentsTokens
from prompt_toolkit.history import FileHistory
from prompt_toolkit.lexers import PygmentsLexer
from pygments import lex
from pygments.lexers.scripting import LuaLexer

from pob_wrapper import ExternalError, PathOfBuilding


def run():
    pob_install = r'D:\Programs\PathOfBuilding'
    pob_path = r'D:\Programs\PathOfBuilding'

    pob = PathOfBuilding(pob_path, pob_install, verbose='-d' in sys.argv)

    builds_path = pob.get_builds_dir()
    print("POB Builds:", builds_path)

    print('\nLoading build:')
    pob.load_build(rf'{builds_path}\Experiment\ZioniclesExperiment.xml')
    pprint(pob.get_build_info())

    session = PromptSession(history=FileHistory(".repl-history"),
                            lexer=PygmentsLexer(LuaLexer),
                            auto_suggest=AutoSuggestFromHistory(),
                            mouse_support=True)

    try:
        while True:
            text = session.prompt('Lua > ')
            try:
                result = pob._send(text)
                pprint(result)
            except ExternalError as err:
                print("ERROR:", err.status.get('error', err.status))
    except KeyboardInterrupt:
        pass
    except EOFError:
        pass

    return pob


if __name__ == '__main__':
    pob = run()
