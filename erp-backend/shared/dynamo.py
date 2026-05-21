import os
import boto3
from boto3.dynamodb.conditions import Attr


def dynamodb_resource():
    endpoint_url = os.environ.get("DYNAMODB_ENDPOINT_URL")
    if endpoint_url:
        return boto3.resource("dynamodb", endpoint_url=endpoint_url)
    return boto3.resource("dynamodb")


def table(env_name):
    table_name = os.environ[env_name]
    return dynamodb_resource().Table(table_name)


def scan_active(table_ref):
    result = table_ref.scan(FilterExpression=Attr("isActive").ne(False))
    return result.get("Items", [])


def scan_all(table_ref):
    result = table_ref.scan()
    return result.get("Items", [])
