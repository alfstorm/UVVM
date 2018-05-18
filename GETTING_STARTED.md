( [Click here to go to the UVVM overall overview](https://github.com/UVVM/UVVM/blob/master/README.md) )

# Getting started using UVVM

UVVM is Free and Open source, under the very flexible [MIT licence](https://github.com/UVVM/UVVM/blob/master/LICENSE)
UVVM basically has two levels of usage: Basic/Introductory and Advanced
With the Basic/Introductory level you are given a library and methodology that provides common functionality for all testbenches from simple to expert with things like logging, alert handling, checking signals, waiting for signals, checking timing properties, simple randomisation, etc. This is explained directly below this chapter.
A number of BFMs (Bus Functional Models) compatible with the Utility Library are provided as free and open source code as a kick-start for testbenches using interfaces like AXI lite/stream, Avalon, I2C, SPI, UART, SBI, GPIO, etc.
For more advanced testbenches with either multiple interfaces, or the need to reach interface related corner cases, the VVC system is really great. This is explained below the Utility Library.
A number of VHDL verification components (VVCs) are provided for free with this system.

## Github directory naming notation
- The directories starting with 'uvvm_' are the core libraries for UVVM Utility Library and UVVM VVC System
- All directories starting with 'bitvis_vip_' are verification IP/modules from Bitvis
- All other directories starting with 'bitvis_' are design IP/modules from Bitvis
- Directories starting with 'x' are external (third party) libraries that work seamlessly with UVVM

## For developers with no previous UVVM experience: Step 1
You should start by first understanding and trying out the Utility Library. The basics here could be covered in less than one hour. The UVVM Utility Library has a *very* low user threshold - according to all users so far.
* Read the [README-file for UVVM Utility Library](https://github.com/UVVM/UVVM/blob/master/README_UVVM_Utility_Library.md) to get a first introduction to why, what and how.
* Go through the powerpoint 'Making a simple, structured and efficient VHDL testbench – Step-by-step' linked to from the README-file

## For developers with no previous UVVM experience: Step 2
To compile Utility Library related VHDL files you can do the following:
- To compile Utility Library only: 
  a) Using Modelsim/Questasim project files: 
     Double click on uvvm_util/sim/uvvm_util.mpf (may have to relate file extension to simulator)
  b) Running commands inside Modelsim/Questasim/RivieraPro/ActiveHDL:
     Run do-file: uvvm_util/script/compile_src.do
  c) Using GHDL:
     Use GHDL provided script with uvvm_util/script/compile_order.txt as input
  d) Any other approach - or with script problems:
     Follow compile order given in uvvm_util/script/compile_order.txt
     Note that VHDL 2008 must be used. Lines starting with '# ' are required library definitions
        vlib <source_path>/sim/<lib_name>
        vmap <lib_name> <source_path>/sim/<lib_name>
- To compile the complete IRQ demo testbench including Utility Library and the IRQC DUT: 
  - For alle a,b,c,d over bytt ut path   uvvm_util med bitvis_irqc
- To compile all above pluss all provided BFMs, the scripts for compiling the complete UVVM should be used. (See below)
If you want to run a demo testbench using the Utility library, including the SBI BFM, you can run bitvis_irqc/tb/irqc_tb.vhd

## For developers who understand the basics of UVVM Utility library and need more than just basic testbenches:
### Step 1
A very brief introduction to making a structured testbench architecture can be found under https://github.com/UVVM/UVVM/tree/master/_supplementary_doc Advanced Verification - Made simple.




    



