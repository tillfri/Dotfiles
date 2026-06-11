# notes-to-calendar

Syncs `todo.txt` entries that have a `due:YYYY-MM-DD` tag to Google Calendar as all-day events.

## How it works

- Todos with a `due:` date are hashed (by their normalized description, tags stripped) and tracked in `todo-mapping.json`.
- On each run: new todos are **inserted**, changed due dates are **patched**, removed todos are **deleted**.
- If nothing changed, no API call is made.

## Setup

### 1. Install dependencies

```bash
uv pip install google-api-python-client google-auth
```

### 2. Fill in credentials

Copy `calendar_config.json` and fill in your OAuth tokens and client credentials:

```json
{
  "access_token": "ya29.xxx",
  "refresh_token": "1//xxx",
  "client_id": "xxx.apps.googleusercontent.com",
  "client_secret": "GOCSPX-xxx"
}
```

Get these from the [Google Cloud Console](https://console.cloud.google.com/) under **APIs & Services → Credentials**.  
The access token is auto-refreshed when expired and written back to the file.

### 3. Run manually

```bash
python sync_todo_calendar.py
```

The script reads `todo.txt` and `todo-mapping.json` from its own directory.

## Automation via systemd

A user service is included at `systemd/user/todo-watch.service`.  
It runs `~/scripts/todo-watch.sh` (which should call `sync_todo_calendar.py`) and restarts it on exit.

```bash
# Install and enable
cp systemd/user/todo-watch.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now todo-watch.service

# Check status / logs
systemctl --user status todo-watch.service
journalctl --user -u todo-watch.service -f
```

## Files

| File | Purpose |
|---|---|
| `sync_todo_calendar.py` | Main sync script |
| `calendar_config.json` | OAuth credentials (not committed) |
| `todo-mapping.json` | Hash → event ID state (auto-generated) |
| `systemd/user/todo-watch.service` | Systemd unit for continuous syncing |
