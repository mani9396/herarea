import os
import sys

if sys.platform == 'win32':
    import asyncio
    import warnings
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", DeprecationWarning)
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from daphne.cli import CommandLineInterface

if __name__ == '__main__':
    CommandLineInterface.entrypoint()
