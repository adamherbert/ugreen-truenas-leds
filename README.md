# ugreen-truenas-leds

This is a quick and dirty program to poll for disk and network activity on
a UGREEN DXP6800 Pro and other models, and update the front panel
LEDs accordingly.

Take a look at `config.yaml` for the settings.

## Building

```bash
go build -o truenas-leds .
```

## Running

```bash
./truenas-leds --config=config.yaml [--device=/dev/i2c-2]
```

## Finding your i2c device

The default device may not work for you.

```bash
$ i2cdetect -l
```