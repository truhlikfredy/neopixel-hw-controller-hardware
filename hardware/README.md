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
![wave](/images/wave.png)

# Dependencies

* verilator to compile simulation
* Node.js / npm (run npm install to get the nodemon installed automatically, which is required for the run-scrip monitor)
* gtk-wave to see the waveforms
* visual studio code (not required, but commandbar settings are already premade for it)
