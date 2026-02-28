import re
from typing import Dict, Optional, Tuple

REQUIRED_FIELDS = ("allocationId", "date", "startTime", "endTime")


def parse_time_12h(value: str) -> Optional[int]:
    if not isinstance(value, str):
        return None

    match = re.fullmatch(r"(\d{1,2}):(\d{2})\s([AP]M)", value.strip())
    if not match:
        return None

    hour = int(match.group(1))
    minute = int(match.group(2))
    meridiem = match.group(3)

    if hour < 1 or hour > 12 or minute < 0 or minute > 59:
        return None

    if meridiem == "PM" and hour != 12:
        hour += 12
    if meridiem == "AM" and hour == 12:
        hour = 0

    return hour * 60 + minute


def validate_resolve_conflict_payload(data: Dict) -> Tuple[bool, Optional[str]]:
    if not isinstance(data, dict):
        return False, "Request body must be a JSON object."

    missing = [field for field in REQUIRED_FIELDS if not data.get(field)]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}."

    start = parse_time_12h(data["startTime"])
    end = parse_time_12h(data["endTime"])

    if start is None or end is None:
        return False, "Invalid time format. Use HH:MM AM/PM."

    if end <= start:
        return False, "endTime must be later than startTime."

    return True, None
