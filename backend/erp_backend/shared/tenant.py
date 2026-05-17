"""
Shared tenant utilities for the Serverless ERP application.

This module provides multi-tenancy support by extracting tenant IDs from
API Gateway request headers.
"""

DEFAULT_TENANT_ID = "demo"


def get_tenant_id(event):
    """
    Extract tenant ID from API Gateway event headers.

    Checks for x-tenant-id header (case-insensitive) and falls back to default.

    Args:
        event (dict): API Gateway event

    Returns:
        str: Tenant ID or default tenant
    """
    headers = event.get("headers") or {}

    tenant_id = (
        headers.get("x-tenant-id")
        or headers.get("X-Tenant-Id")
        or headers.get("X-Tenant-ID")
        or DEFAULT_TENANT_ID
    )

    return tenant_id.strip() if isinstance(tenant_id, str) and tenant_id.strip() else DEFAULT_TENANT_ID