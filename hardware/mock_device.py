"""Optional desktop-only FIREBASE MOCK device (NOT ESP32 firmware).

Use to verify commands, readings and rules while hardware is with a teammate.
Requires Python 3.9+ but no external Python packages. Every mock telemetry
packet contains source='mock', so the Flutter app warns that values are fake.
No account password is saved to disk.
"""
import getpass
import json
import time
import urllib.error
import urllib.parse
import urllib.request


def request(url, data=None, method=None):
    body = json.dumps(data).encode('utf-8') if data is not None else None
    req = urllib.request.Request(url, data=body,
                                 headers={'Content-Type': 'application/json'},
                                 method=method or ('POST' if body else 'GET'))
    try:
        with urllib.request.urlopen(req, timeout=20) as res:
            return json.loads(res.read())
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f'HTTP {exc.code}: {exc.read().decode()}') from exc


def main():
    print('FIREBASE MOCK DEVICE - NO PHYSICAL HARDWARE CONNECTION')
    api_key = input('Firebase Web API key: ').strip()
    db = input('Realtime Database URL (https://...): ').strip().rstrip('/')
    home = input('Home ID [demo-home]: ').strip() or 'demo-home'
    email = input('Mock/device user email: ').strip()
    password = getpass.getpass('Firebase user password: ')
    if not db.startswith('https://'):
        raise ValueError('RTDB URL must use HTTPS')
    if not home.replace('-', '').replace('_', '').isalnum():
        raise ValueError('Invalid home ID')
    login_url = ('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key='
                 + urllib.parse.quote(api_key))

    def sign_in():
        result = request(login_url, {'email': email, 'password': password,
                                     'returnSecureToken': True})
        return result['idToken'], time.time() + int(result.get('expiresIn', '3600')) - 120

    token, expiry = sign_in()
    print('Signed in. Press Ctrl+C to stop the mock. NOT ESP32 hardware.')
    n = 0
    while True:
        if time.time() > expiry:
            token, expiry = sign_in()
        home_base = f'{db}/homes/{urllib.parse.quote(home)}'
        query = urllib.parse.urlencode({'auth': token})
        commands = request(f'{home_base}/commands.json?{query}') or {}
        if not isinstance(commands, dict):
            commands = {}
        print('Received app commands:', commands)
        ac_mode = commands.get('ac_mode', 'OFF')
        if ac_mode not in ('OFF', 'LOW', 'MEDIUM', 'HIGH'):
            ac_mode = 'OFF'
        acknowledged = {
            'lamp': bool(commands.get('lamp', False)),
            'ac_mode': ac_mode,
            'geyser': bool(commands.get('geyser', False)),
            'main_door_open': bool(commands.get('door_open', False)),
        }
        door_open = (n // 6) % 2 == 1
        acknowledged['fridge_led'] = door_open
        request(f'{home_base}/reported.json?{query}', acknowledged, method='PUT')
        request(f'{home_base}/telemetry.json?{query}', {
            'temperature_c': 26.5,
            'humidity_pct': 54.0,
            'fridge_door_open': door_open,
            'gas_raw': 0,
            'source': 'mock',
            'updated_at': int(time.time() * 1000),
        }, method='PUT')
        print('Published MOCK-only acknowledgements/readings.')
        n += 1
        time.sleep(5)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nMock stopped.')
