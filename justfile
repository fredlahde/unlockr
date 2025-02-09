build:
    zig build

lock: build
    sudo ./zig-out/bin/unlockr lock

unlock: build
    sudo ./zig-out/bin/unlockr unlock

install:
    zig build --release=safe
    sudo install -o root -g root -m 755 -C -v ./zig-out/bin/unlockr /usr/bin/unlockr

install-sample-config:
    sudo install -v -d -o root -g root -m 755 /etc/unlockr
    sudo install -v -o root -g root -m 400 config.json.sample /etc/unlockr/config.json 
