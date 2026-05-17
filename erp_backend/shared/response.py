import json
from decimal import Decimal


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            if obj % 1 == 0:
                return int(obj)
            return float(obj)
        return super().default(obj)


def to_json(data):
    return json.dumps(data, cls=DecimalEncoder, ensure_ascii=False)


def parse_body(event):
    body = event.get("body")
    if not body:
        return {}
    if isinstance(body, dict):
        return body
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON body")


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "GET,POST,PATCH,DELETE,OPTIONS",
        },
        "body": to_json(body),
    }


def success(data=None, message="OK", status_code=200):
    return response(status_code, {
        "success": True,
        "message": message,
        "data": data,
    })


def error(message="Error", status_code=400, details=None):
    payload = {
        "success": False,
        "message": message,
    }
    if details is not None:
        payload["details"] = details
    return response(status_code, payload)


def handle_exception(exc):
    if isinstance(exc, ValueError):
        return error(str(exc), 400)
    return error("Internal server error", 500, str(exc))
