from datetime import datetime, timezone
from uuid import uuid4


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def new_id(prefix):
    return f"{prefix}-{uuid4().hex[:10].upper()}"
