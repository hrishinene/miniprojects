def read(name):
    return input(f"Please enter '{name}': ")

def read_int(name, default=0):
    s = input(f"Please enter '{name}' (int): ")
    return int(s) if s.strip().isdigit() else default

def read_float(name, default=0.0):
    s = input(f"Please enter '{name}' (float): ")
    try:
        return float(s)
    except ValueError:
        return default

def read_array(name, separator=',', strip_items=True):
    s = input(f"Please enter '{name}' (comma-separated): ")
    items = s.split(separator)
    return [item.strip() for item in items] if strip_items else items

def read_int_array(name):
    s = input(f"Please enter '{name}' (comma-separated integers): ")
    return [int(x) for x in s.split(',') if x.strip().isdigit()]

from datetime import datetime
def read_date(name, fmt='%Y-%m-%d', default=None):
    s = input(f"Please enter '{name}' (date in {fmt}): ")
    try:
        return datetime.strptime(s.strip(), fmt).date()
    except ValueError:
        return default
