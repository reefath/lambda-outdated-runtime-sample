import configparser
import os

_INI = os.path.join(os.path.dirname(os.path.dirname(__file__)), "settings.ini")


def load_settings():
    parser = configparser.ConfigParser()
    parser.read(_INI)
    return {section: dict(parser.items(section)) for section in parser.sections()}
