"""
Shared date utilities for the Serverless ERP application.

This module provides utilities for working with dates and timestamps
in UTC timezone.
"""

from datetime import datetime, timezone


def utc_now_iso():
    """
    Get current UTC time in ISO format.

    Returns:
        str: ISO 8601 formatted UTC timestamp
    """
    return datetime.now(timezone.utc).isoformat()