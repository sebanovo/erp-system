from shared.response import success


def lambda_handler(event, context):
    return success({"status": "ok", "service": "serverless-erp"}, "Service is running")
    