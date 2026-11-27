import re

# Same component splitting as the removed distutils.version.LooseVersion.
_COMPONENT = re.compile(r"(\d+|[a-z]+|\.)")


def _loose_key(version):
    return [
        int(part) if part.isdigit() else part
        for part in _COMPONENT.split(version)
        if part and part != "."
    ]


def newest(versions):
    return max(versions, key=_loose_key)
