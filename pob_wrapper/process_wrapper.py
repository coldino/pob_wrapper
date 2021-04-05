import json
import os
import sys
from subprocess import PIPE, STDOUT
from typing import *

from .popen_job import Popen

__all__ = [
    'ProcessWrapper',
    'safe_string',
]

START_MSG = '!*>>>>>>>>>>>>*!'
START_RESULT = '!*------------*!'
END_RESULT = '!*<<<<<<<<<<<<*!'


def safe_string(txt):
    txt = txt.replace('\\', '\\\\')
    txt = txt.replace('\n', '\\n')
    txt = txt.replace('"', '\\"')
    return txt


class ProcessWrapper:
    '''Starts a sub-process that can be used in a simple question/response pattern.'''
    process: Popen

    receive_msg_fn = lambda self, msg: print("Lua: " + msg if msg else '', end='')

    def __init__(self, debug=False):
        self.debug = debug and True

    def start(self, args: List[str], cwd=None):
        cwd = cwd or os.getcwd()
        self.process = Popen(args, stdin=PIPE, stdout=PIPE, stderr=sys.stderr, universal_newlines=True, cwd=cwd, bufsize=1)
        firstline = self.process.stdout.readline()
        if firstline == '': raise EOFError("Unable to start subprocess")
        if self.debug: print('===', firstline)

    def send(self, txt, ignore_result=False):
        '''Not yet thread-safe!'''
        self.put(txt)

        self.expect(START_MSG)
        while True:
            msg = self.get()
            if msg.startswith(START_RESULT):
                break
            self.receive_msg_fn(msg)

        result_txt = self.get()
        self.expect(END_RESULT)

        if ignore_result:
            return True

        result = json.loads(result_txt)
        return result

    def kill(self):
        self.process.terminate()
        self.process.wait()

    def get(self):
        line = self.process.stdout.readline()
        if line == '': raise EOFError("Subprocess stream ended")
        if self.debug: print('>>>', line)
        return line

    def put(self, line):
        line = line.replace('\n', '\\n')
        if self.debug: print('<<<', line)
        self.process.stdin.write(line)
        self.process.stdin.write('\n')
        self.process.stdin.flush()

    def expect(self, pattern):
        line = self.get()
        if not line.startswith(pattern):
            raise ValueError(f"Received {line} instead of pattern {pattern}")
        return line
