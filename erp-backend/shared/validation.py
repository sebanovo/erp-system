"""
Shared validation utilities for the Serverless ERP application.

This module provides data validation functions for API request bodies,
including JSON parsing and field validation.
"""

import json
from decimal import Decimal, InvalidOperation


def parse_json_body(event):
    """
    Parse JSON body from API Gateway event.

    Handles both string and dict bodies, converting numbers to Decimal.

    Args:
        event (dict): API Gateway event

    Returns:
        dict: Parsed JSON data

    Raises:
        ValueError: If JSON is invalid
    """
    raw_body = event.get("body")

    if not raw_body:
        return {}

    if isinstance(raw_body, dict):
        return raw_body

    try:
        return json.loads(raw_body, parse_float=Decimal, parse_int=Decimal)
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON body")


def require_fields(data, required_fields):
    """
    Validate that required fields are present and not empty.

    Args:
        data (dict): Data to validate
        required_fields (list): List of required field names

    Raises:
        ValueError: If any required fields are missing or empty
    """
    missing_fields = []

    for field in required_fields:
        value = data.get(field)

        if value is None or value == "":
            missing_fields.append(field)

    if missing_fields:
        raise ValueError(f"Missing required fields: {', '.join(missing_fields)}")


def require_positive_decimal(value, field_name):
    """
    Validate and convert value to positive Decimal.

    Args:
        value: Value to validate
        field_name (str): Field name for error messages

    Returns:
        Decimal: Validated positive decimal

    Raises:
        ValueError: If value is invalid or not positive
    """
    if isinstance(value, bool):
        raise ValueError(f"{field_name} must be a valid number")

    try:
        number = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError(f"{field_name} must be a valid number")

    if number <= 0:
        raise ValueError(f"{field_name} must be greater than zero")

    return number


def require_non_negative_decimal(value, field_name):
    """
    Validate and convert value to non-negative Decimal.

    Args:
        value: Value to validate
        field_name (str): Field name for error messages

    Returns:
        Decimal: Validated non-negative decimal

    Raises:
        ValueError: If value is invalid or negative
    """
    if isinstance(value, bool):
        raise ValueError(f"{field_name} must be a valid number")

    try:
        number = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError(f"{field_name} must be a valid number")

    if number < 0:
        raise ValueError(f"{field_name} must be greater than or equal to zero")

    return number


def require_positive_number(value, field_name):
    """
    Validate and convert value to positive float.

    Args:
        value: Value to validate
        field_name (str): Field name for error messages

    Returns:
        float: Validated positive number

    Raises:
        ValueError: If value is invalid or not positive
    """
    number = require_positive_decimal(value, field_name)
    return float(number)


def require_non_negative_number(value, field_name):
    """
    Validate and convert value to non-negative float.

    Args:
        value: Value to validate
        field_name (str): Field name for error messages

    Returns:
        float: Validated non-negative number

    Raises:
        ValueError: If value is invalid or negative
    """
    number = require_non_negative_decimal(value, field_name)
    return float(number)