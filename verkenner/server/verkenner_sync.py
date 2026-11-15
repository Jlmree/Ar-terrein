#!/usr/bin/env python3
"""Verkenner-sync: een piepklein opslagpunt voor je Verkenner-voortgang.

De Verkenner-webapp zet je stand hier neer (PUT /v/<sleutel>),
de Garmin-watchface haalt hem op (GET /v/<sleutel>).
Alleen Python 3 nodig, geen extra pakketten.
"""
import json, os, re, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DATA = os.environ.get('VERKENNER_DATA', '/var/lib/verkenner')
PORT = int(os.environ.get('VERKENNER_PORT', '8787'))
HOST = os.environ.get('VERKENNER_HOST', '127.0.0.1')
ORIGIN = os.environ.get('VERKENNER_ORIGIN', 'https://jlmree.github.io')
KEY = re.compile(r'^/v/([A-Za-z0-9_-]{16,64})$')
MAXB = 4096
os.makedirs(DATA, exist_ok=True)


class H(BaseHTTPRequestHandler):
    server_version = 'verkenner-sync/1'

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', ORIGIN)
        self.send_header('Access-Control-Allow-Methods', 'GET, PUT, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Access-Control-Max-Age', '86400')

    def _send(self, code, body=b'', ctype='application/json'):
        self.send_response(code)
        self._cors()
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        if body:
            self.wfile.write(body)

    def do_OPTIONS(self):
        self._send(204)

    def do_GET(self):
        if self.path in ('/', '/health'):
            return self._send(200, b'{"ok":true}')
        m = KEY.match(self.path)
        if not m:
            return self._send(404, b'{"fout":"onbekend pad"}')
        f = os.path.join(DATA, m.group(1) + '.json')
        if not os.path.exists(f):
            return self._send(404, b'{"fout":"nog geen stand"}')
        with open(f, 'rb') as fh:
            self._send(200, fh.read())

    def do_PUT(self):
        m = KEY.match(self.path)
        if not m:
            return self._send(404, b'{"fout":"onbekend pad"}')
        n = int(self.headers.get('Content-Length') or 0)
        if n <= 0 or n > MAXB:
            return self._send(413, b'{"fout":"te groot"}')
        raw = self.rfile.read(n)
        try:
            obj = json.loads(raw)
            assert isinstance(obj, dict)
        except Exception:
            return self._send(400, b'{"fout":"geen geldige JSON"}')
        obj['ontvangen'] = int(time.time())
        tmp = os.path.join(DATA, m.group(1) + '.tmp')
        with open(tmp, 'w') as fh:
            json.dump(obj, fh, ensure_ascii=False, separators=(',', ':'))
        os.replace(tmp, os.path.join(DATA, m.group(1) + '.json'))
        self._send(200, b'{"ok":true}')

    do_POST = do_PUT

    def log_message(self, fmt, *args):
        sys.stderr.write('%s %s\n' % (self.address_string(), fmt % args))


if __name__ == '__main__':
    print('Verkenner-sync luistert op %s:%d, opslag in %s' % (HOST, PORT, DATA))
    ThreadingHTTPServer((HOST, PORT), H).serve_forever()
