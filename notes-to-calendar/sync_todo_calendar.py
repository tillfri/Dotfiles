#!/usr/bin/env python3
"""
sync_todo_calendar.py

Syncs todos with due: dates from todo.txt to Google Calendar.
- Inserts new events, patches changed due dates, deletes removed todos.
- State is persisted in todo-mapping.json.
- Config (OAuth tokens) is read from calendar_config.json.
"""

import hashlib
import json
import re
import sys
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).parent
TODO_FILE = BASE_DIR / "todo.txt"
MAPPING_FILE = BASE_DIR / "todo-mapping.json"
CONFIG_FILE = BASE_DIR / "calendar_config.json"

CALENDAR_ID = ""
TOKEN_URI = "https://oauth2.googleapis.com/token"

# ---------------------------------------------------------------------------
# todo.txt parsing
# ---------------------------------------------------------------------------

_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_PRIORITY_RE = re.compile(r"^\([A-Z]\)$")
_TAG_RE = re.compile(
    r"(?:^|\s)"  # start of string or whitespace
    r"(?:"
    r"\+\S+"  # +context
    r"|@\S+"  # @project
    r"|\S+:\S+"  # key:value  (includes due:date)
    r")"
)


def parse_todo_line(line: str) -> dict | None:
    """
    Parse a single todo.txt line into a dict with keys:
      completed, priority, completion_date, creation_date, description, due_date
    Returns None for blank lines.
    """
    line = line.strip()
    if not line:
        return None

    tokens = line.split()
    idx = 0
    completed = False
    priority = None
    completion_date = None
    creation_date = None

    # Completion marker
    if tokens[idx] == "x":
        completed = True
        idx += 1

    # Priority — only valid on incomplete tasks per spec, but we parse it regardless
    if idx < len(tokens) and _PRIORITY_RE.match(tokens[idx]):
        priority = tokens[idx][1]  # strip parentheses
        idx += 1

    # Date(s)
    if idx < len(tokens) and _DATE_RE.match(tokens[idx]):
        date1 = tokens[idx]
        idx += 1
        if idx < len(tokens) and _DATE_RE.match(tokens[idx]):
            # Two dates: completion_date + creation_date (only meaningful when completed)
            completion_date = date1
            creation_date = tokens[idx]
            idx += 1
        else:
            creation_date = date1

    description = " ".join(tokens[idx:])

    # Extract due: date
    due_match = re.search(r"(?:^|\s)due:(\d{4}-\d{2}-\d{2})(?:\s|$)", description)
    due_date = due_match.group(1) if due_match else None

    return {
        "completed": completed,
        "priority": priority,
        "completion_date": completion_date,
        "creation_date": creation_date,
        "description": description,
        "due_date": due_date,
    }


def normalize_description(description: str) -> str:
    """Strip all tags (+context, @project, key:value) from a description."""
    result = re.sub(
        r"(?<!\S)"  # preceded by start-of-string or whitespace
        r"(?:\+\S+|@\S+|\S+:\S+)"
        r"(?!\S)",  # followed by end-of-string or whitespace
        "",
        description,
    )
    # Collapse whitespace
    return " ".join(result.split())


def make_hash(normalized: str) -> str:
    return hashlib.sha256(normalized.encode()).hexdigest()


# ---------------------------------------------------------------------------
# Mapping file helpers
# ---------------------------------------------------------------------------


def load_mapping() -> dict:
    if MAPPING_FILE.exists():
        return json.loads(MAPPING_FILE.read_text())
    return {}


def save_mapping(mapping: dict) -> None:
    MAPPING_FILE.write_text(json.dumps(mapping, indent=2))


# ---------------------------------------------------------------------------
# Google Calendar helpers
# ---------------------------------------------------------------------------


def build_service():
    config = json.loads(CONFIG_FILE.read_text())
    creds = Credentials(
        token=config["access_token"],
        refresh_token=config["refresh_token"],
        token_uri=TOKEN_URI,
        client_id=config["client_id"],
        client_secret=config["client_secret"],
    )
    # Refresh if expired
    if creds.expired:
        creds.refresh(Request())
        # Persist the new access token so we don't re-auth next run
        config["access_token"] = creds.token
        CONFIG_FILE.write_text(json.dumps(config, indent=2))

    return build("calendar", "v3", credentials=creds)


def make_event_body(description: str, due_date: str) -> dict:
    """Build a Google Calendar all-day event body."""
    return {
        "summary": description,
        "start": {"date": due_date},
        "end": {"date": due_date},
    }


def insert_event(service, description: str, due_date: str) -> str:
    """Insert a new calendar event; returns the Google event id."""
    body = make_event_body(description, due_date)
    result = service.events().insert(calendarId=CALENDAR_ID, body=body).execute()
    print(f"  [INSERT] '{description}' on {due_date} → event id: {result['id']}")
    return result["id"]


def patch_event(service, event_id: str, description: str, due_date: str) -> str:
    """Patch an existing calendar event; returns the (same) event id."""
    body = make_event_body(description, due_date)
    result = service.events().patch(calendarId=CALENDAR_ID, eventId=event_id, body=body).execute()
    print(f"  [PATCH]  '{description}' → new due date {due_date} (id: {result['id']})")
    return result["id"]


def delete_event(service, event_id: str, description: str) -> None:
    """Delete a calendar event by id."""
    service.events().delete(calendarId=CALENDAR_ID, eventId=event_id).execute()
    print(f"  [DELETE] '{description}' (id: {event_id})")


# ---------------------------------------------------------------------------
# Main sync logic
# ---------------------------------------------------------------------------


def collect_current_todos() -> dict[str, dict]:
    """
    Parse todo.txt and return a dict keyed by hash for every todo that has a
    due date.  Value: {description, due_date} where description is normalized.
    """
    current: dict[str, dict] = {}
    lines = TODO_FILE.read_text().splitlines()

    for lineno, raw in enumerate(lines, start=1):
        todo = parse_todo_line(raw)
        if todo is None or todo["due_date"] is None:
            continue

        normalized = normalize_description(todo["description"])
        if not normalized:
            print(f"  [WARN] Line {lineno}: description empty after normalization, skipping.")
            continue

        h = make_hash(normalized)
        if h in current:
            print(f"  [WARN] Line {lineno}: hash collision with earlier entry '{current[h]['description']}', skipping.")
            continue

        current[h] = {
            "description": normalized,
            "due_date": todo["due_date"],
        }

    return current


def sync():
    if not CONFIG_FILE.exists():
        sys.exit(f"ERROR: {CONFIG_FILE} not found.\nCopy calendar_config.json.template and fill in your credentials.")

    print("Loading todo.txt …")
    current = collect_current_todos()
    print(f"  Found {len(current)} todo(s) with due dates.")

    print("Loading todo-mapping.json …")
    mapping = load_mapping()
    print(f"  Mapping contains {len(mapping)} stored entry(ies).")

    current_hashes = set(current)
    stored_hashes = set(mapping)

    new_hashes = current_hashes - stored_hashes
    updated_hashes = {h for h in current_hashes & stored_hashes if current[h]["due_date"] != mapping[h]["due_date"]}
    deleted_hashes = stored_hashes - current_hashes

    print(f"\nDiff: {len(new_hashes)} new, {len(updated_hashes)} updated, {len(deleted_hashes)} deleted.")

    if not any([new_hashes, updated_hashes, deleted_hashes]):
        print("Nothing to do.")
        return

    print("Connecting to Google Calendar …")
    try:
        service = build_service()
    except Exception as exc:
        sys.exit(f"ERROR: Could not build Google Calendar service: {exc}")
    print()

    # --- Inserts ---
    for h in new_hashes:
        desc = current[h]["description"]
        due = current[h]["due_date"]
        try:
            event_id = insert_event(service, desc, due)
            mapping[h] = {
                "description": desc,
                "due_date": due,
                "calendar_event_id": event_id,
            }
        except HttpError as exc:
            print(f"  [ERROR] Insert failed for '{desc}': {exc}")

    # --- Patches ---
    for h in updated_hashes:
        desc = current[h]["description"]
        due = current[h]["due_date"]
        event_id = mapping[h].get("calendar_event_id")
        if not event_id:
            print(f"  [WARN] No event_id stored for '{desc}', inserting instead.")
            try:
                event_id = insert_event(service, desc, due)
            except HttpError as exc:
                print(f"  [ERROR] Insert (fallback) failed for '{desc}': {exc}")
                continue
        else:
            try:
                event_id = patch_event(service, event_id, desc, due)
            except HttpError as exc:
                print(f"  [ERROR] Patch failed for '{desc}': {exc}")
                continue
        mapping[h] = {
            "description": desc,
            "due_date": due,
            "calendar_event_id": event_id,
        }

    # --- Deletes ---
    for h in deleted_hashes:
        desc = mapping[h].get("description", "<unknown>")
        event_id = mapping[h].get("calendar_event_id")
        if event_id:
            try:
                delete_event(service, event_id, desc)
            except HttpError as exc:
                print(f"  [ERROR] Delete failed for '{desc}': {exc}")
        else:
            print(f"  [WARN] No event_id for '{desc}', removing from mapping only.")
        del mapping[h]

    save_mapping(mapping)
    print("\nDone. todo-mapping.json updated.")


if __name__ == "__main__":
    sync()
