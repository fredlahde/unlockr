# unlockr

A small CLI to interface with LUKS containers more easily,

## Usage

```bash
just install # build and install the binary
just install-sample-config # install the sample config
# edit the config at /etc/unlockr/config.json

sudo unlockr unlock # unlock the container

sudo unlockr lock # lock the container
```

## Config

There are 3 important config keys:

- `luks_img`: the path to the LUKS-encrypted container file (`.img`)
- `cryptsetup_name`: the identifer under which the `cryptsetup` tool recognizes the container
- `mount_point`: the path where the unlocked container will be mounted
