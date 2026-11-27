import importlib.util
import os

_HERE = os.path.dirname(__file__)


def load_plugin(name):
    path = os.path.join(_HERE, "plugin_%s.py" % name)
    spec = importlib.util.spec_from_file_location("report_plugin_%s" % name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
