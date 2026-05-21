from decimal import Decimal, InvalidOperation


def require_fields(data, fields):
    missing = [field for field in fields if data.get(field) in (None, "")]
    if missing:
        raise ValueError(f"Missing required fields: {', '.join(missing)}")


def to_decimal(value, field_name):
    try:
        decimal_value = Decimal(str(value))
    except (InvalidOperation, TypeError):
        raise ValueError(f"{field_name} must be a valid number")
    return decimal_value


def to_positive_int(value, field_name):
    try:
        int_value = int(value)
    except (ValueError, TypeError):
        raise ValueError(f"{field_name} must be a valid integer")
    if int_value <= 0:
        raise ValueError(f"{field_name} must be greater than zero")
    return int_value


def to_non_negative_int(value, field_name):
    try:
        int_value = int(value)
    except (ValueError, TypeError):
        raise ValueError(f"{field_name} must be a valid integer")
    if int_value < 0:
        raise ValueError(f"{field_name} cannot be negative")
    return int_value
