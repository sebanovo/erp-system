"""
Shared DynamoDB utilities for the Serverless ERP application.

This module provides utilities for connecting to and accessing DynamoDB tables
using environment variables for table names.
"""

import os
import boto3


def get_dynamodb_resource():
    """
    Get a DynamoDB resource instance.

    Returns:
        boto3.resource: DynamoDB resource
    """
    return boto3.resource("dynamodb")


def get_table(table_env_name):
    """
    Get a DynamoDB table instance from environment variable.

    Args:
        table_env_name (str): Environment variable name containing table name

    Returns:
        boto3.dynamodb.Table: Table instance

    Raises:
        RuntimeError: If environment variable is not set
    """
    table_name = os.environ.get(table_env_name)

    if not table_name:
        raise RuntimeError(f"Missing environment variable: {table_env_name}")

    dynamodb = get_dynamodb_resource()
    return dynamodb.Table(table_name)