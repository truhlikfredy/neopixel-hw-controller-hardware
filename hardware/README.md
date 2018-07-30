# Description

This part of the project implements the peripheral itself in verilog. The **emul** folder is used to emulate it with verilator so it doesn't have to be synthetized every single time to verify if it's working. GTK-Wave can be used to view output waveforms of the module.

To compile the emulation you want to run these commands:
```
npm run-script clean
npm run-script build
```

To run both clean, build and execute the simulation run the following:
```
npm run-script run
```

Just to see where is an issue you can run it in linting mode:
```
npm run-script lint
```

To automatically trigger compilation on changes the vscode can be setup to save file on lost focus. By just ALT-TABing to the gtk-wave to see the waveforms it will trigger recompilation and run of the simulation
```
npm run-script monitor
```

And to startup gtk-wave for the very first time (for refresh ctrl+shift R is enough) run:
```
npm run-script wave
```
![wave](/hardware/images/wave.png)

# Protocol 

Is implementing the [WS2812](https://cdn-shop.adafruit.com/datasheets/WS2812.pdf) NZR protocol.
3 things can be happening on the data wire:
* Transmit 1 (**HIGH** for 0.7us followed with **LOW** for 0.6us)
* Transmit 0 (**HIGH** for 0.4us followed with **LOW** for 0.8us)
* Reset (stay **LOW** for at least 50us)

There is some leeway in the timing so it doesn't have to absolutely precise, for properly correct timing see the datasheet:

| Emitting color | Wavelength(nm) | Luminous intensity(mcd) | Current(ma) | Voltage(V) |
| -------------  | -------------- | ----------------------- | ----------- | ---------- |
| Red            | 620-630        | 550-700                 | 20          | 1.8-2.2    |
| Green          | 515-530        | 1100-1400               | 20          | 3.0-3.2    |
| Blue           | 465-475        | 200-400                 | 20          | 3.2-3.4    |

Sequence chart:

![sequence](/hardware/images/sequence.svg)

| Label     | Description                         | Time(ns)    | 
| --------- | ----------------------------------- | ----------- |
| T0H       | 0 code, high voltage segment        | 350 +-150   |
| T0L       | 0 code, low voltage segment         | 800 +-150   |
| T0H + T0L | both high and low segments together | 1250 +-600  |
| T1H       | 1 code, high voltage segment        | 700 +-150   |
| T1L       | 1 code, low voltage segment         | 600 +-150   |
| T1H + T1L | both high and low segments together | 1250 +-600  |
| Reset     | low voltage                         | Above 50000 |

Note that the datasheet might be off as the 0/1 code taking 1250ns +-600ns would be breaking the constrains of the contained high+low segments. I assume the segments are driving constraints while the total is driven constraint. The fastest time a code can be transmitted is 0 code (850ns) and slowest time is 1 code (1600ns). So the average and range would be 1225ns +-375ns.

DO of each LED pixel is feed to the following LED's DIN

![cascade](/hardware/images/cascade.svg)


![refresh-cycle](/hardware/images/refresh-cycle.svg)

Each LED will keep the next LED in Reset until it processes and consumes its first data chunk and then it will passthrough all others data chunks (data chunks are pealed away in the chain like like layers of a onion). This way the 3rd LED will see as its first data chunk the 3rd data chunk in the stream and will not even know there were 2 data chunks before.

Every single data chunk consists of 24 bits, their order is in figure below. Notice the order of the colors **GRB** and the fact that the most significant bits are transmitted first.

![data-chunk](/hardware/images/data-chunk.svg)


# Dependencies

* verilator to compile simulation
* Node.js / npm (run npm install to get the nodemon installed automatically, which is required for the run-scrip monitor)
* gtk-wave to see the waveforms
* Phantomjs to build images for the documentation
* visual studio code (not required, but commandbar settings are already premade for it)
