"""
Health check module for the Serverless ERP application.

This module provides a simple health check endpoint to verify that the API is running.
"""

from shared.response import success_response


def lambda_handler(event, context):
    """
    Health check Lambda handler.

    Returns a success response indicating the service is running.

    Args:
        event (dict): API Gateway event
        context: Lambda context object

    Returns:
        dict: API response with service status
    """
    return success_response(
        message="Serverless ERP API is running",
        data={
            "service": "serverless-erp",
            "version": "1.0.0"
        }
    )