__all__ = [
    "_printDict",
    "_dump"
]

print(f"Custom Startup Defined Functions:\n{__all__}")


#### Set custom REPL options ###################################################
import sys
# Set the primary prompt to bright green
sys.ps1 = '\033[92m>>> \033[0m'
# Set the secondary prompt to green
sys.ps2 = '\033[32m... \033[0m'
################################################################################


def _printDict(pydict):
    """Sort the dictionary keys and print {key} = {value} for each.

    Args:
        pydict (dict)

    Returns:
        None

    """
    [print(f"{key} = {pydict.get(key)}") for key in sorted(pydict.keys())]


def _dump(obj, values=False):
    """Prints out a sorted list of the dir of the supplied object.

    Args:
        obj (Object): Any Python object compatible with dir
        values (bool, optional): If true will print <attr> = <attr value>

    """
    attrs = sorted(dir(obj))

    if not values:
        for attr in attrs:
            print(attr)
    else:
        for attr in attrs:
            print(f"{attr} = {getattr(obj, attr)}\n")
