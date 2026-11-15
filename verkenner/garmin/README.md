# Verkenner – watchface voor je Garmin Fenix 5S

De watchface laat je Verkenner-stand zien: **niveau** (als gouden ring langs de rand), **rang**, het **gebied waar je bent met % verkend**, je **reeks dagen op rij**, het aantal **badges** en de **km van vandaag**. Elke 5 minuten haalt hij de nieuwste stand op van je eigen server (via Bluetooth en de Garmin Connect-app op je telefoon).

```
Verkenner (telefoon)  ──POST──►  jouw server  ◄──GET──  Fenix 5S (watchface)
```

## 1. Server (netcup) — eenmalig

In de map `../server` staat alles. Met Docker:

```bash
scp -r server/ jij@jouw-server:~/verkenner-sync
ssh jij@jouw-server
cd ~/verkenner-sync
nano Caddyfile          # vervang VERVANG-MIJ.sslip.io door je domein,
                        # of door verkenner.<ip-met-streepjes>.sslip.io (bijv. verkenner.203-0-113-7.sslip.io)
docker compose up -d
curl https://<jouw-adres>/health      # moet {"ok":true} geven
```

Poort 80 en 443 moeten open staan (voor het automatische HTTPS-certificaat).
Zonder Docker kan ook: `python3 verkenner_sync.py` (luistert op 127.0.0.1:8787) achter je eigen nginx/Caddy.

## 2. Verkenner koppelen

Open Verkenner → **Opties → Horloge (Garmin)**:
- vul bij **Server** je adres in (`https://…`, zonder `/` aan het eind)
- kopieer de **Koppelsleutel** (die heb je zo nodig)
- tik **Nu versturen** → er moet "Verstuurd om …" staan

## 3. Watchface bouwen en op je horloge zetten (Linux Mint)

1. Installeer **VS Code** en daarin de extensie **Monkey C** (van Garmin).
2. VS Code → `Ctrl+Shift+P` → **Monkey C: Verify Installation** → volg de stappen; installeer via de **SDK Manager** de nieuwste SDK en het apparaat **fēnix 5S**.
3. `Ctrl+Shift+P` → **Monkey C: Generate a Developer Key** (eenmalig).
4. Open de map `VerkennerWatch` in VS Code.
5. Zet je gegevens in `resources/settings/properties.xml`:
   - `ServerUrl` = hetzelfde adres als in Verkenner
   - `SyncKey` = de koppelsleutel uit Verkenner
   (Bij zelf geïnstalleerde watchfaces kun je instellingen niet via de Garmin Connect-app wijzigen, daarom staan ze hier.)
6. Proberen in de simulator: `F5` (kies fenix5s).
7. Bouwen: `Ctrl+Shift+P` → **Monkey C: Build for Device** → **fenix5s** → je krijgt `VerkennerWatch.prg`.
8. Sluit je Fenix met USB aan, open hem in de bestandsbeheerder (MTP) en kopieer het `.prg`-bestand naar **GARMIN/APPS**.
9. Ontkoppel, en kies op je horloge de watchface **Verkenner** (houd UP ingedrukt → Wijzerplaat).

Na maximaal 5 minuten verschijnt je stand. Je telefoon moet in de buurt zijn met Garmin Connect actief.

## Wandelingen van je Fenix in Verkenner

Neem een wandeling op met je Fenix. Exporteer hem daarna op **connect.garmin.com** (activiteit openen → tandwiel → *Exporteren naar GPX*) en kies in Verkenner **Opties → Wandeling inladen (GPX)**. De mist trekt op langs je hele route, en alles wat je onderweg tegenkwam telt mee.
