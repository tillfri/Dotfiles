#!/usr/bin/env python3
"""
sync_todo_calendar.py

Syncs todos with due: dates from a markdown TODO file to Google Calendar.
- Inserts new events, patches changed due dates, deletes removed todos.
- State is persisted in todo-mapping.json.
- Config (OAuth tokens, todo_file path) is read from calendar_config.json.

Markdown format: any bullet line (leading tabs/spaces + "- ") containing
a due:YYYY-MM-DD tag will be synced. Removing a line deletes its event.
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
MAPPING_FILE = BASE_DIR / "todo-mapping.json"
CONFIG_FILE = BASE_DIR / "calendar_config.json"

TOKEN_URI = "https://oauth2.googleapis.com/token"

# ---------------------------------------------------------------------------
# Markdown TODO parsing
# ---------------------------------------------------------------------------

_BULLET_RE = re.compile(r"^[\t ]*- (.+)$")
_DUE_RE = re.compile(r"(?:^|\s)due:(\d{4}-\d{2}-\d{2})(?:\s|$)")


def parse_md_line(line: str) -> dict | None:
    """
    Parse a single markdown bullet line.
    Returns a dict with 'description' (normalized, due tag stripped) and
    'due_date', or None if the line is not a bullet or has no due date.
    """
    m = _BULLET_RE.match(line)
    if not m:
        return None

    content = m.group(1).strip()

    due_match = _DUE_RE.search(content)
    if not due_match:
        return None

    due_date = due_match.group(1)

    # Strip the due: tag and collapse whitespace
    normalized = _DUE_RE.sub(" ", content).strip()
    normalized = " ".join(normalized.split())

    return {"description": normalized, "due_date": due_date}


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


def build_service(config: dict):
    creds = Credentials(
        token=config["access_token"],
        refresh_token=config["refresh_token"],
        token_uri=TOKEN_URI,
        client_id=config["client_id"],
        client_secret=config["client_secret"],
    )
    if creds.expired:
        creds.refresh(Request())
        config["access_token"] = creds.token
        CONFIG_FILE.write_text(json.dumps(config, indent=2))

    return build("calendar", "v3", credentials=creds)


def make_event_body(description: str, due_date: str) -> dict:
    return {
        "summary": description,
        "start": {"date": due_date},
        "end": {"date": due_date},
    }


def insert_event(service, calendar_id: str, description: str, due_date: str) -> str:
    body = make_event_body(description, due_date)
    result = service.events().insert(calendarId=calendar_id, body=body).execute()
    print(f"  [INSERT] '{description}' on {due_date} → event id: {result['id']}")
    return result["id"]


def patch_event(service, calendar_id: str, event_id: str, description: str, due_date: str) -> str:
    body = make_event_body(description, due_date)
    result = service.events().patch(calendarId=calendar_id, eventId=event_id, body=body).execute()
    print(f"  [PATCH]  '{description}' → new due date {due_date} (id: {result['id']})")
    return result["id"]


def delete_event(service, calendar_id: str, event_id: str, description: str) -> None:
    service.events().delete(calendarId=calendar_id, eventId=event_id).execute()
    print(f"  [DELETE] '{description}' (id: {event_id})")


# ---------------------------------------------------------------------------
# Main sync logic
# ---------------------------------------------------------------------------


def collect_current_todos(todo_file: Path) -> dict[str, dict]:
    """
    Parse a markdown TODO file and return a dict keyed by hash for every
    bullet line that contains a due:YYYY-MM-DD tag.
    Value: {description, due_date}.
    """
    current: dict[str, dict] = {}
    lines = todo_file.read_text().splitlines()

    for lineno, raw in enumerate(lines, start=1):
        todo = parse_md_line(raw)
        if todo is None:
            continue

        normalized = todo["description"]
        if not normalized:
            print(f"  [WARN] Line {lineno}: description empty after normalization, skipping.")
            continue

        h = make_hash(normalized)
        if h in current:
            print(
                f"  [WARN] Line {lineno}: hash collision with earlier entry "
                f"'{current[h]['description']}', skipping."
            )
            continue

        current[h] = {"description": normalized, "due_date": todo["due_date"]}

    return current


def sync():
    if not CONFIG_FILE.exists():
        sys.exit(
            f"ERROR: {CONFIG_FILE} not found.\n"
            "Copy calendar_config.json.template and fill in your credentials."
        )

    config = json.loads(CONFIG_FILE.read_text())

    todo_file_path = config.get("todo_file")
    if not todo_file_path:
        sys.exit("ERROR: 'todo_file' key missing from calendar_config.json.")
    todo_file = Path(todo_file_path)
    if not todo_file.exists():
        sys.exit(f"ERROR: TODO file not found: {todo_file}")

    calendar_id = config.get("calendar_id", "")
    if not calendar_id:
        sys.exit("ERROR: 'calendar_id' key missing from calendar_config.json.")

    print(f"Loading {todo_file} …")
    current = collect_current_todos(todo_file)
    print(f"  Found {len(current)} todo(s) with due dates.")

    print("Loading todo-mapping.json …")
    mapping = load_mapping()
    print(f"  Mapping contains {len(mapping)} stored entry(ies).")

    current_hashes = set(current)
    stored_hashes = set(mapping)

    new_hashes = current_hashes - stored_hashes
    updated_hashes = {
        h for h in current_hashes & stored_hashes
        if current[h]["due_date"] != mapping[h]["due_date"]
    }
    deleted_hashes = stored_hashes - current_hashes

    print(
        f"\nDiff: {len(new_hashes)} new, {len(updated_hashes)} updated, "
        f"{len(deleted_hashes)} deleted."
    )

    if not any([new_hashes, updated_hashes, deleted_hashes]):
        print("Nothing to do.")
        return

    print("Connecting to Google Calendar …")
    try:
        service = build_service(config)
    except Exception as exc:
        sys.exit(f"ERROR: Could not build Google Calendar service: {exc}")
    print()

    # --- Inserts ---
    for h in new_hashes:
        desc = current[h]["description"]
        due = current[h]["due_date"]
        try:
            event_id = insert_event(service, calendar_id, desc, due)
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
                event_id = insert_event(service, calendar_id, desc, due)
            except HttpError as exc:
                print(f"  [ERROR] Insert (fallback) failed for '{desc}': {exc}")
                continue
        else:
            try:
                event_id = patch_event(service, calendar_id, event_id, desc, due)
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
                delete_event(service, calendar_id, event_id, desc)
            except HttpError as exc:
                print(f"  [ERROR] Delete failed for '{desc}': {exc}")
        else:
            print(f"  [WARN] No event_id for '{desc}', removing from mapping only.")
        del mapping[h]

    save_mapping(mapping)
    print("\nDone. todo-mapping.json updated.")


if __name__ == "__main__":
    sync()
