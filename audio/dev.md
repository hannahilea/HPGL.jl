# Working notes
1. Load paper on machine
2. Confirm that chunker file works with demo file:
```
sudo ./target/debug/chunker ~/path/to/your/hpgl/file
```
so in my case, 
```
../../plotter-tools/chunker/target/debug/chunker ../examples/demo.hpgl
autodetected serial device: "/dev/tty.usbserial-10"
```
1. Confirm that existing chunker utility can be used to write out the file
