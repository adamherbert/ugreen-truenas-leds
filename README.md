# ugreen-truenas-leds

Polls disk and network activity on a UGREEN DXP6800 Pro (and other DXP models)
and drives the front-panel LEDs accordingly.

Ships as a container for TrueNAS SCALE; a bare-metal install path is still
supported for non-TrueNAS hosts.

## Install on TrueNAS SCALE (recommended)

Requires SCALE 24.10 or later (Docker-based Apps).

### 1. Create a dataset for the app

On a data pool (not the boot-pool — it is overwritten on upgrade):

```
/mnt/<pool>/apps/truenas-leds/
```

### 2. Drop in the config

Copy [`config.yaml`](config.yaml) into that dataset. The default `/dev/i2c-2`
works on most DXP boards; if yours differs, edit the `device:` key. Find the
right bus with `i2cdetect -l` on the host.

### 3. Install the Post Init script

The container needs `i2c-dev` and `i2c-i801` loaded on the host. Copy
[`deploy/truenas/post-init.sh`](deploy/truenas/post-init.sh) to your dataset,
then register it:

**System Settings → Advanced → Init/Shutdown Scripts → Add**

| Field    | Value                                               |
|----------|-----------------------------------------------------|
| Type     | Script                                              |
| Script   | `/mnt/<pool>/apps/truenas-leds/post-init.sh`        |
| When     | Post Init                                           |
| Timeout  | 10                                                  |

Reboot once so the modules load.

### 4. Install the Custom App

**Apps → Discover Apps → Install Custom App.** Paste the contents of
[`deploy/truenas/docker-compose.yaml`](deploy/truenas/docker-compose.yaml),
replacing `POOL` with your pool name.

### 5. Verify

- `lsmod | grep -E '^i2c_(dev|i801)'` — both modules loaded.
- `ls /dev/i2c-*` — character device exists.
- Apps UI shows `truenas-leds` as Running.
- Generate disk I/O; the matching front-panel LED should brighten.

### Notes

- The container runs with `CAP_SYS_RAWIO` and direct access to `/dev/i2c-2`
  only — not `privileged`.
- `/sys`, `/dev/disk/by-path`, and `/proc/diskstats` are bind-mounted
  read-only so the binary can discover disks and read IO counters.
- The I2C bus index can shift across kernel updates. If LEDs stop responding
  after a TrueNAS upgrade, re-run `i2cdetect -l` and update `config.yaml`.
- TrueNAS itself uses SMBus for sensor reads; no conflicts have been observed,
  but the two do share the bus.

## Install on bare metal (non-TrueNAS)

```bash
go build -o truenas-leds .
sudo install -m 0755 truenas-leds /usr/local/bin/
sudo install -m 0644 -D config.yaml /etc/truenas-leds/config.yaml
sudo install -m 0644 truenas-leds.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now truenas-leds.service
```

## Configuration

```yaml
# I2C device path for LED control. Find yours with: i2cdetect -l
device: /dev/i2c-2

# How often to poll for disk and network activity (10ms – 5000ms).
poll_interval: 100ms

# How long one full rainbow cycle takes on idle disks (1s – 10s).
rainbow_cycle_time: 3s

# Rainbow color cycling on inactive disks. False = LEDs off when idle.
enable_rainbow: true

# Brightness for rainbow colors (0–255). Ignored if enable_rainbow: false.
rainbow_brightness: 48
```

| Option              | Type     | Default       | Description                                                   |
|---------------------|----------|---------------|---------------------------------------------------------------|
| `device`            | string   | `/dev/i2c-2`  | I2C device path for communicating with the LEDs              |
| `poll_interval`     | duration | `100ms`       | Frequency of disk/network activity polling                   |
| `rainbow_cycle_time`| duration | `3s`          | Time for one complete rainbow cycle                          |
| `enable_rainbow`    | bool     | `true`        | Show rainbow colors on inactive disks                        |
| `rainbow_brightness`| int      | `48`          | Brightness level for rainbow (0–255)                         |

### LED behavior

- **Red** — disk write / network transmit
- **Blue** — disk read / network receive
- **Purple** — mixed activity
- **Rainbow** — inactive (when `enable_rainbow: true`)
- **Off** — inactive (when `enable_rainbow: false`)

Brightness is scaled with activity intensity.

## Container image

Built and published by GitHub Actions on every push to `main` and on tags:

```
ghcr.io/adamherbert/ugreen-truenas-leds:latest
ghcr.io/adamherbert/ugreen-truenas-leds:vX.Y.Z
ghcr.io/adamherbert/ugreen-truenas-leds:sha-<short>
```

`linux/amd64` only — the UGREEN DXP lineup is x86.

First-time setup: after the initial push, mark the GHCR package as **public**
under the fork's repository settings → Packages, or `docker pull` will require
authentication.

## Development

```bash
go build -o truenas-leds .
./truenas-leds -config config.yaml
```

Test locally:

```bash
go test ./...
```
