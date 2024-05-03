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

4. On to printing (live) sound in the basic way? See development in `audio/run.jl`. WIP.
