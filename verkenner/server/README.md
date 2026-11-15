# Verkenner-sync

Klein opslagpunt (Python, geen extra pakketten) zodat je Garmin-watchface je Verkenner-stand kan lezen.
Installatie: zie `../garmin/README.md`, stap 1.

- `POST /v/<sleutel>`: stand opslaan (JSON, max 4 KB)
- `GET /v/<sleutel>`: stand ophalen
- `GET /health`: controle

Gegevens staan in `./data/<sleutel>.json`. De sleutel is willekeurig en lang; wie hem niet kent, kan niets lezen of schrijven.
