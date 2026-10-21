# App ↔ Firebase ↔ ESP32 data contract

The Flutter app connects to Firebase Realtime Database using Firebase Auth **email/password** REST sign-in. It does not connect directly to an ESP32 IP address. Actual GPIO operation requires ESP32 firmware that authenticates with Firebase as an allowed device user, polls commands, applies outputs, and reports results. A Firebase sign-in alone does **not** mean the hardware is online.

## Database tree

```json
{
  "homes": {
    "demo-home": {
      "commands": {
        "lamp": false,
        "ac_mode": "OFF",
        "geyser": false,
        "door_open": false
      },
      "reported": {
        "lamp": false,
        "ac_mode": "OFF",
        "geyser": false,
        "fridge_led": false,
        "main_door_open": false
      },
      "telemetry": {
        "temperature_c": 0.0,
        "humidity_pct": 0.0,
        "fridge_door_open": false,
        "gas_raw": 0,
        "updated_at": 0,
        "source": "esp32"
      }
    }
  }
}
```

- Flutter writes `lamp`, `geyser`, and `door_open` booleans, plus `ac_mode` as one of `OFF`, `LOW`, `MEDIUM`, or `HIGH`. There is no fridge LED command.
- Flutter reads the complete `homes/<homeId>` object every five seconds. Bedroom 1 and **Real IoT Sensors** use the same app controller and Firebase state.
- ESP32 reads `commands`, applies outputs, then writes applied state to `reported`. AC mode is a string. `main_door_open` reports the SG90 target position applied by firmware; there is no door-position feedback sensor.
- ESP32 writes DHT22 temperature (°C), humidity (%), `fridge_door_open`, raw MQ-2 ADC, `updated_at` and `source: "esp32"` under `telemetry`. The millisecond Unix or ISO-8601 UTC timestamp is the heartbeat used to detect stale telemetry.
- `fridge_led` is sensor-controlled, not manually switched. GPIO14 follows the reed state and is only reported by ESP32.
- A command is a request, not confirmation. The app shows it as pending until matching state appears in `reported`. Never acknowledge a command before applying the requested hardware action.
- Bedroom 1 demonstration-model pin map (do not change assignments):
  - GPIO5 → Lamp LED
  - GPIO19 → AC LOW LED
  - GPIO21 → AC MEDIUM LED
  - GPIO22 → AC HIGH LED
  - GPIO23 → Geyser LED
  - GPIO14 → Fridge Interior LED
  - GPIO13 → Fridge Reed Sensor (`INPUT_PULLUP`)
  - GPIO18 → SG90 Main Door Servo
  - GPIO4 → DHT22 data
  - GPIO34 → MQ-2 analog input
- AC mode changes must first set GPIO19, GPIO21 and GPIO22 LOW, then enable at most the one requested mode pin. OFF leaves all three LOW.
- With a normally-open reed wired between GPIO13 and GND, `INPUT_PULLUP` reads LOW with magnet near (CLOSED) and HIGH with magnet away (OPEN). Verify polarity on the actual sensor during bench setup; adjust logical interpretation if the reed switch/contact type behaves differently, without changing its GPIO. GPIO14 follows the verified logical open state.
- Use configured, safe SG90 open/closed positions. Report the applied servo target only after writing the servo position; it is not independent door-position feedback.
- MQ-2 input must never exceed 3.3 V at GPIO34. Raw ADC and configurable threshold are prototype warnings only, not calibrated gas concentration or a safety alarm. Do not connect mains appliances to GPIO.

## Exact demonstration-model wiring

Disconnect power before changing wiring. Keep the GPIO assignments above unchanged.

### Indicator LEDs

For each LED, connect the listed ESP32 output through its own **220 Ω series resistor** to the LED long leg (anode, `+`). Connect the short leg (cathode, `−`) to common GND:

| LED | GPIO |
|---|---:|
| Lamp | GPIO5 |
| AC LOW | GPIO19 |
| AC MEDIUM | GPIO21 |
| AC HIGH | GPIO22 |
| Geyser | GPIO23 |
| Fridge interior | GPIO14 |

The three AC indicator LEDs are mutually exclusive. The fridge interior LED is driven automatically by the reed sensor; do not add a manual LED command or switch.

### Fridge reed module

| Module connection | Connect to |
|---|---|
| `S` | GPIO13 |
| `−` | ESP32 GND |
| Middle pin | Leave unconnected for this module configuration |

Configure GPIO13 as `INPUT_PULLUP`. For the stated wiring and sensor configuration, magnet near means **CLOSED** and magnet away means **OPEN**; GPIO14 should turn ON only when OPEN. Verify this electrical polarity on the actual module before relying on the status. If its contact behavior differs, correct the firmware's logical interpretation, not the GPIO assignment.

### Main-door SG90 servo

| Servo wire | Connect to |
|---|---|
| Orange/yellow signal | GPIO18 |
| Red | Regulated 5 V supply |
| Brown/black ground | Regulated supply GND |

Connect the regulated supply GND to ESP32 GND (common ground). Power the servo from the regulated 5 V supply, not the ESP32 3.3 V pin. Firmware must use configured open/closed servo positions; `reported/main_door_open` confirms the commanded/applied servo target only, not independent physical door feedback.

### DHT22 temperature and humidity

| DHT22 connection | Connect to |
|---|---|
| `+` / VCC | ESP32 3.3 V |
| `OUT` / data | GPIO4 |
| `−` / GND | ESP32 GND |

For a bare DHT22 without an onboard pull-up, add a **10 kΩ** resistor between `OUT` and 3.3 V. Do not apply 5 V to GPIO4.

### MQ-2 analog sensor

| MQ-2 connection | Connect to |
|---|---|
| VCC | 5 V |
| GND | Common ESP32 GND |
| AO | Through a **10 kΩ** resistor to GPIO34 |
| DO | Leave unconnected |

Add a **15 kΩ** resistor from GPIO34 to GND. The 10 kΩ series and 15 kΩ lower resistor form the stated divider (about 3 V from a 5 V AO signal). Check the actual AO voltage and keep GPIO34 at or below 3.3 V. These divider resistors are not LED current-limiting resistors; do not substitute the 220 Ω LED resistors here. MQ-2 ADC values remain raw prototype readings, not calibrated gas concentration or a safety alarm.

### Power and common ground

- ESP32 3.3 V powers the DHT22 only.
- Regulated 5 V powers the SG90 servo and MQ-2 VCC.
- Join the grounds: ESP32 GND, all LED cathodes, servo supply GND, DHT22 GND, reed `−`, MQ-2 GND, and the lower 15 kΩ divider resistor.
- Do not power a real mains appliance from ESP32 GPIO or this demonstration wiring.

## Sample secure Realtime Database rules

**Edit the exact home ID and user UIDs before publishing.** Create one Firebase Auth user for the app and one for the ESP32; use their UIDs from Firebase Authentication → Users. Access is restricted to those two user IDs for this **one prototype home**.

```json
{
  "rules": {
    "homes": {
      "$homeId": {
        ".read": "$homeId === 'demo-home' && auth != null && (auth.uid === 'REPLACE_APP_USER_UID' || auth.uid === 'REPLACE_DEVICE_USER_UID')",
        ".write": "$homeId === 'demo-home' && auth != null && (auth.uid === 'REPLACE_APP_USER_UID' || auth.uid === 'REPLACE_DEVICE_USER_UID')"
      }
    }
  }
}
```

These are small-team prototype rules: they restrict who can read/write but **do not** isolate command and telemetry writing privileges. For production, separate app/device roles and validate data paths, ranges and shapes. Never enable `".read": true` or `".write": true` globally.

## Firmware integration checklist

1. Program an ESP32 for Wi-Fi connectivity; use the *device* Auth account to obtain Firebase ID tokens securely (not an Admin SDK service account key).
2. Configure the exact GPIO map above. Set GPIO13 to `INPUT_PULLUP` and verify magnet-near/away logic on the actual wiring.
3. Poll `homes/<homeId>/commands` every 2–5 seconds. Apply lamp/geyser booleans, exclusive AC mode, and SG90 target positions. Drive all three AC pins LOW before enabling a selected mode pin.
4. Derive `fridge_door_open` from GPIO13 and automatically drive GPIO14. Never accept a Firebase command for the fridge LED.
5. Publish applied output state under `reported`; publish valid DHT22, reed and safely scaled raw ADC data under `telemetry` with a fresh `updated_at` heartbeat and `"source": "esp32"`. Omit unavailable sensor values instead of inventing them.
6. Use MQ-2 thresholds only for configurable prototype warnings. They are not calibrated concentration or life-safety detection.
7. Confirm hardware state in either the **Bedroom 1** panel or the **Real IoT Sensors** page. Both display the same requests and ESP32 reports.

For testing Firebase without physical hardware, use the supplied `mock_device.py` desktop test client. Its acknowledgements are **simulated** and must never be confused with ESP32 responses.
