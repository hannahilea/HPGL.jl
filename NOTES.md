# Dev notes
Steps followed to test machine interop and develop interactive tooling:

1. Load paper on machine

2. Confirm that chunker file works with demo file:
```
sudo ./target/debug/chunker ~/path/to/your/hpgl/file
```
so in our case, 
```
../../plotter-tools/chunker/target/debug/chunker examples/demo.hpgl
```
Success!

3. Figure out how to send commands from OUR utility. Success! 
    To reproduce this, with HPGL.jl as a working directory, do 
    ```
    julia --project=. scripts/validate-serialport.jl
    ```
    Then play around with input commands listed in that script.

    Fun commands to try include:
    - `SM *` then PA commands (draws at * at each coord)
        - `SM` to leave symbol mode 
        - if pen is down during that move, will draw symbol at end of it!
        - Symbols can be anything from decimal code [33-126](https://www.ibm.com/docs/en/aix/7.2?topic=adapters-ascii-decimal-hexadecimal-octal-binary-conversion-table) but not semicolon.


- [ ] Question (for manual): are all mnemonics 2 character?

4. Plot sound in the offline way! See `scratch/audio/offline-audio.jl`, which has the user record 10s of input and then plots it out. 

5. Plot sound in the online (realtime) way! See `scratch/audio/realtime-audio.jl`, which plots the realtime amplitude peaks recorded from the mic.

6. Pull the functionality from `realtime-audio.jl` into packaged code. 
