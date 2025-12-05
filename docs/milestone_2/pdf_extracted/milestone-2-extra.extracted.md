# Part 2 — Milestone 2 EXTRA (Original PDF)
**Source file:** milestone-2-extra.pdf


---

## Page 1

![Page 1 snapshot](/mnt/data/export_fitz_noocr/milestone-2-extra/page-1.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(143.6, 122.1, 451.6, 139.8)`

```
Milestone 2 Extra
—
Computer Architecture

```

**Block 2**  
`bbox=(159.5, 147.3, 435.8, 172.9)`

```
Single Cycle RV32I ISA Tests

```

**Block 3**  
`bbox=(276.0, 195.6, 319.3, 210.3)`

```
Hai Cao

```

**Block 4**  
`bbox=(275.7, 221.4, 319.6, 236.0)`

```
rev 1.0.1

```

**Block 5**  
`bbox=(72.0, 267.3, 131.0, 285.0)`

```
Contents

```

**Block 6**  
`bbox=(72.0, 299.2, 523.3, 312.7)`

```
1
Introduction
1

```

**Block 7**  
`bbox=(72.0, 327.0, 523.3, 340.5)`

```
2
Environment Setup
1

```

**Block 8**  
`bbox=(88.4, 343.9, 523.3, 357.3)`

```
2.1
Project Directory Hierarchy . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
2

```

**Block 9**  
`bbox=(88.4, 360.8, 523.3, 374.2)`

```
2.2
Memory Configuration . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
2

```

**Block 10**  
`bbox=(88.4, 377.8, 523.3, 391.1)`

```
2.3
File Setup for Verilator . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
3

```

**Block 11**  
`bbox=(88.4, 394.7, 523.3, 408.1)`

```
2.4
File Setup for Xcelium
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
3

```

**Block 12**  
`bbox=(72.0, 422.6, 523.3, 436.1)`

```
3
Simulation
3

```

**Block 13**  
`bbox=(72.0, 450.5, 523.3, 464.0)`

```
4
Simulation Results
3

```

**Block 14**  
`bbox=(88.4, 467.3, 523.3, 480.7)`

```
4.1
Expected Behavior
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
3

```

**Block 15**  
`bbox=(88.4, 484.3, 523.3, 497.6)`

```
4.2
Troubleshooting Common Issues . . . . . . . . . . . . . . . . . . . . . . . . . . . .
5

```

**Block 16**  
`bbox=(278.6, 508.5, 316.7, 520.8)`

```
Abstract

```

**Block 17**  
`bbox=(114.2, 526.7, 496.0, 538.9)`

```
If you come across any errors or have suggestions for improving this document, please

```

**Block 18**  
`bbox=(99.3, 541.7, 496.0, 554.0)`

```
email the TA: cxhai.sdh221@hcmut.edu.vn with the subject “[CA203 MS2 TEST FEED-

```

**Block 19**  
`bbox=(99.3, 556.6, 136.9, 569.0)`

```
BACK]”

```

**Block 20**  
`bbox=(72.0, 592.3, 176.4, 610.0)`

```
1
Introduction

```

**Block 21**  
`bbox=(72.0, 624.1, 523.3, 637.5)`

```
This document serves as a comprehensive guide for conducting functional verification of the

```

**Block 22**  
`bbox=(72.0, 641.0, 523.3, 654.4)`

```
RV32I instruction set, as outlined in the requirements for Milestone 2. The objective is to ensure

```

**Block 23**  
`bbox=(72.0, 658.0, 523.3, 671.4)`

```
that the implemented design meets the expected functional behavior, leveraging a systematic

```

**Block 24**  
`bbox=(72.0, 674.9, 523.3, 688.3)`

```
testing environment. The verification environment provided is a straightforward functional

```

**Block 25**  
`bbox=(72.0, 691.9, 523.3, 705.2)`

```
testbench, where students’ designs act as DUT (Device Under Test). Modules for driving stimuli

```

**Block 26**  
`bbox=(72.0, 708.8, 523.3, 722.2)`

```
and collecting results, including driver and scoreboard components, are provided. Students

```

**Block 27**  
`bbox=(72.0, 725.7, 523.3, 739.1)`

```
are expected to organize their source code correctly, navigate to the simulation directory, and

```

**Block 28**  
`bbox=(72.0, 742.7, 387.7, 756.0)`

```
execute the provided scripted makefile for automated simulation.

```

**Block 29**  
`bbox=(88.9, 759.6, 492.2, 773.0)`

```
The following are key aspects to understand before proceeding with the simulation:

```

**Block 30**  
`bbox=(294.9, 789.5, 300.4, 802.9)`

```
1

```


---

## Page 2

![Page 2 snapshot](/mnt/data/export_fitz_noocr/milestone-2-extra/page-2.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(294.1, 34.3, 523.3, 47.7)`

```
Milestone 2 Extra
—
Computer Architecture

```

**Block 2**  
`bbox=(85.6, 72.7, 523.3, 86.0)`

```
1. The test environment monitors o_pc_debug and o_io_ledr signals to determine test

```

**Block 3**  
`bbox=(99.3, 89.6, 369.9, 103.0)`

```
outcomes, indicating either a "pass" or "error" condition.

```

**Block 4**  
`bbox=(85.6, 115.0, 523.3, 128.4)`

```
2. Due to the flexible memory mapping requirements, your design must support 32-bit

```

**Block 5**  
`bbox=(99.3, 131.9, 467.5, 145.3)`

```
load/store operations to the LEDR register, mapped to address 0x1000_0000.

```

**Block 6**  
`bbox=(72.0, 168.9, 221.4, 186.6)`

```
2
Environment Setup

```

**Block 7**  
`bbox=(72.0, 200.7, 523.3, 214.1)`

```
Prior to commencing the test, students must copy the singlecycle test from the common direc-

```

**Block 8**  
`bbox=(72.0, 217.6, 295.8, 231.0)`

```
tory to their home directory and navigate to it.

```

**Block 9**  
`bbox=(57.1, 260.5, 94.9, 271.5)`

```
1
cd ~

```

**Block 10**  
`bbox=(57.1, 277.4, 215.2, 288.4)`

```
2
cp -rf ~/common/sc-test .

```

**Block 11**  
`bbox=(57.1, 294.4, 129.3, 305.3)`

```
3
cd sc-test

```

**Block 12**  
`bbox=(72.0, 332.2, 249.0, 346.9)`

```
2.1
Project Directory Hierarchy

```

**Block 13**  
`bbox=(72.0, 357.7, 523.3, 371.0)`

```
The project structure adheres to a hierarchical organization to facilitate efficient simulation and

```

**Block 14**  
`bbox=(72.0, 374.6, 310.1, 388.0)`

```
verification. Directories are structured as follows:

```

**Block 15**  
`bbox=(72.0, 403.3, 129.3, 414.3)`

```
milestone2

```

**Block 16**  
`bbox=(72.0, 420.2, 306.8, 431.2)`

```
|-- 00_src
# Verilog source files

```

**Block 17**  
`bbox=(72.0, 437.2, 278.2, 448.1)`

```
|-- 01_bench
# Testbench files

```

**Block 18**  
`bbox=(72.0, 454.1, 169.4, 465.1)`

```
|
|-- driver.sv

```

**Block 19**  
`bbox=(72.0, 471.0, 192.3, 482.0)`

```
|
|-- scoreboard.sv

```

**Block 20**  
`bbox=(72.0, 488.0, 169.4, 498.9)`

```
|
|-- tbench.sv

```

**Block 21**  
`bbox=(72.0, 504.9, 163.6, 515.9)`

```
|
�-- tlib.svh

```

**Block 22**  
`bbox=(72.0, 521.8, 266.7, 532.8)`

```
|-- 02_test
# Testing files

```

**Block 23**  
`bbox=(72.0, 538.8, 238.1, 549.8)`

```
|
�-- isa.mem
# Hex file

```

**Block 24**  
`bbox=(72.0, 555.7, 243.8, 566.7)`

```
|-- 10_sim
# Verilator

```

**Block 25**  
`bbox=(72.0, 572.7, 146.5, 583.6)`

```
|
|-- flist

```

**Block 26**  
`bbox=(72.0, 589.6, 163.6, 600.6)`

```
|
�-- Makefile

```

**Block 27**  
`bbox=(72.0, 606.5, 232.4, 617.5)`

```
�-- 11_xm
# Xcelium

```

**Block 28**  
`bbox=(94.9, 623.5, 146.5, 634.4)`

```
|-- flist

```

**Block 29**  
`bbox=(94.9, 640.4, 163.6, 651.4)`

```
�-- Makefile

```

**Block 30**  
`bbox=(59.5, 666.5, 294.0, 679.8)`

```
00_src Place all SystemVerilog source files here.

```

**Block 31**  
`bbox=(48.0, 691.9, 523.3, 705.2)`

```
01_bench This directory provides insight into the testbench setup. Study its contents to understand

```

**Block 32**  
`bbox=(99.3, 708.8, 236.4, 722.2)`

```
the simulation environment.

```

**Block 33**  
`bbox=(53.7, 734.2, 487.9, 747.6)`

```
02_test Contains the file isa.mem, a hexadecimal file representing the instruction set test.

```

**Block 34**  
`bbox=(59.4, 759.6, 391.5, 773.0)`

```
10_sim This directory includes scripts for simulation using Verilator.

```

**Block 35**  
`bbox=(294.9, 789.5, 300.4, 802.9)`

```
2

```


---

## Page 3

![Page 3 snapshot](/mnt/data/export_fitz_noocr/milestone-2-extra/page-3.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(294.1, 34.3, 523.3, 47.7)`

```
Milestone 2 Extra
—
Computer Architecture

```

**Block 2**  
`bbox=(65.1, 72.7, 434.3, 86.0)`

```
11_xm This directory contains scripts for simulation using Cadence Xcelium.

```

**Block 3**  
`bbox=(72.0, 105.8, 224.8, 120.6)`

```
2.2
Memory Configuration

```

**Block 4**  
`bbox=(72.0, 131.3, 523.3, 144.7)`

```
To ensure compatibility with the testbench, make the following modifications to your memory

```

**Block 5**  
`bbox=(72.0, 148.3, 110.0, 161.7)`

```
models:

```

**Block 6**  
`bbox=(88.1, 173.9, 523.3, 187.6)`

```
• Since the testbench requires more than 4 KiB, your design must use an address width of at

```

**Block 7**  
`bbox=(99.3, 191.1, 523.3, 204.5)`

```
least 16 bits (supporting a memory size of 16 KiB). Hence, the top address for simulation

```

**Block 8**  
`bbox=(99.3, 208.1, 251.6, 221.4)`

```
should be at least 0x0000_7FFF.

```

**Block 9**  
`bbox=(88.1, 233.6, 523.3, 247.4)`

```
• The memory must be preloaded with the contents of 02_test/isa.mem to provide test

```

**Block 10**  
`bbox=(99.3, 250.9, 159.0, 264.3)`

```
instructions.

```

**Block 11**  
`bbox=(72.0, 284.1, 224.1, 298.8)`

```
2.3
File Setup for Verilator

```

**Block 12**  
`bbox=(72.0, 309.6, 523.3, 322.9)`

```
To run simulations using Verilator, change into 10_sim directory and edit flist file to include

```

**Block 13**  
`bbox=(72.0, 326.5, 523.3, 339.9)`

```
all relevant design files. For example, if your top-level module is named singlecycle.sv,

```

**Block 14**  
`bbox=(72.0, 343.4, 156.8, 356.8)`

```
include the entry:

```

**Block 15**  
`bbox=(88.9, 361.7, 237.8, 372.7)`

```
./../00_src/singlecycle.sv

```

**Block 16**  
`bbox=(72.0, 393.6, 221.4, 408.3)`

```
2.4
File Setup for Xcelium

```

**Block 17**  
`bbox=(72.0, 419.1, 523.3, 432.4)`

```
To execute simulations using Cadence Xcelium, change into 10_sim directory and edit flist

```

**Block 18**  
`bbox=(72.0, 436.0, 523.3, 449.4)`

```
file to include all relevant design files.
For example, if your top-level module is named

```

**Block 19**  
`bbox=(72.0, 452.9, 242.5, 466.3)`

```
singlecycle.sv, include the entry:

```

**Block 20**  
`bbox=(88.9, 471.2, 237.8, 482.1)`

```
./../00_src/singlecycle.sv

```

**Block 21**  
`bbox=(72.0, 507.1, 166.8, 524.8)`

```
3
Simulation

```

**Block 22**  
`bbox=(72.0, 538.9, 515.3, 552.3)`

```
With all setup completed, you must first access computing resource and run Makefile script.

```

**Block 23**  
`bbox=(85.6, 564.8, 523.3, 578.2)`

```
1. Run the command below to access a computing node. Without “--x11”, you cannot use

```

**Block 24**  
`bbox=(99.3, 581.7, 122.5, 595.1)`

```
GUI.

```

**Block 25**  
`bbox=(236.7, 609.0, 357.0, 619.9)`

```
srun --x11 --pty bash

```

**Block 26**  
`bbox=(85.6, 633.5, 523.3, 646.9)`

```
2. If you use Verilator, navigate to 10_sim and run “make”. If you want to observe wave-

```

**Block 27**  
`bbox=(99.3, 650.5, 349.4, 663.8)`

```
forms, you can use “make wave” to open GTKWave.

```

**Block 28**  
`bbox=(85.6, 676.4, 523.3, 689.8)`

```
3. In case you use Xcelium, navigate to 11_xm and run “make”. If you want to observe

```

**Block 29**  
`bbox=(99.3, 693.3, 369.0, 706.7)`

```
waveforms, you can use “make gui” to open SimVision.

```

**Block 30**  
`bbox=(294.9, 789.5, 300.4, 802.9)`

```
3

```


---

## Page 4

![Page 4 snapshot](/mnt/data/export_fitz_noocr/milestone-2-extra/page-4.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(294.1, 34.3, 523.3, 47.7)`

```
Milestone 2 Extra
—
Computer Architecture

```

**Block 2**  
`bbox=(72.0, 69.5, 219.0, 87.3)`

```
4
Simulation Results

```

**Block 3**  
`bbox=(72.0, 101.0, 200.2, 115.8)`

```
4.1
Expected Behavior

```

**Block 4**  
`bbox=(72.0, 126.5, 444.4, 139.9)`

```
A correctly functioning design should produce the expected output as below:

```

**Block 5**  
`bbox=(57.1, 168.1, 175.1, 179.1)`

```
1
SINGLE CYCLE TESTS

```

**Block 6**  
`bbox=(57.1, 188.4, 60.0, 195.7)`

```
2

```

**Block 7**  
`bbox=(57.1, 202.0, 146.5, 213.0)`

```
3
add......PASS

```

**Block 8**  
`bbox=(57.1, 219.0, 146.5, 229.9)`

```
4
addi.....PASS

```

**Block 9**  
`bbox=(57.1, 235.9, 146.5, 246.9)`

```
5
sub......PASS

```

**Block 10**  
`bbox=(57.1, 252.8, 146.5, 263.8)`

```
6
and......PASS

```

**Block 11**  
`bbox=(57.1, 269.8, 146.5, 280.7)`

```
7
andi.....PASS

```

**Block 12**  
`bbox=(57.1, 286.7, 146.5, 297.7)`

```
8
or.......PASS

```

**Block 13**  
`bbox=(57.1, 303.6, 146.5, 314.6)`

```
9
ori......PASS

```

**Block 14**  
`bbox=(54.1, 320.6, 146.5, 331.5)`

```
10
xor......PASS

```

**Block 15**  
`bbox=(54.1, 337.5, 146.5, 348.5)`

```
11
xori.....PASS

```

**Block 16**  
`bbox=(54.1, 354.4, 146.5, 365.4)`

```
12
slt......PASS

```

**Block 17**  
`bbox=(54.1, 371.4, 146.5, 382.3)`

```
13
slti.....PASS

```

**Block 18**  
`bbox=(54.1, 388.3, 146.5, 399.3)`

```
14
sltu.....PASS

```

**Block 19**  
`bbox=(54.1, 405.3, 146.5, 416.2)`

```
15
sltiu....PASS

```

**Block 20**  
`bbox=(54.1, 422.2, 146.5, 433.2)`

```
16
sll......PASS

```

**Block 21**  
`bbox=(54.1, 439.1, 146.5, 450.1)`

```
17
slli.....PASS

```

**Block 22**  
`bbox=(54.1, 456.1, 146.5, 467.0)`

```
18
srl......PASS

```

**Block 23**  
`bbox=(54.1, 473.0, 146.5, 484.0)`

```
19
srli.....PASS

```

**Block 24**  
`bbox=(54.1, 489.9, 146.5, 500.9)`

```
20
sra......PASS

```

**Block 25**  
`bbox=(54.1, 506.9, 146.5, 517.8)`

```
21
srai.....PASS

```

**Block 26**  
`bbox=(54.1, 523.8, 146.5, 534.8)`

```
22
lw.......PASS

```

**Block 27**  
`bbox=(54.1, 540.7, 146.5, 551.7)`

```
23
lh.......PASS

```

**Block 28**  
`bbox=(54.1, 557.7, 146.5, 568.6)`

```
24
lhu......PASS

```

**Block 29**  
`bbox=(54.1, 574.6, 146.5, 585.6)`

```
25
lb.......PASS

```

**Block 30**  
`bbox=(54.1, 591.6, 146.5, 602.5)`

```
26
sw.......PASS

```

**Block 31**  
`bbox=(54.1, 608.5, 146.5, 619.5)`

```
27
sh.......PASS

```

**Block 32**  
`bbox=(54.1, 625.4, 146.5, 636.4)`

```
28
sb.......PASS

```

**Block 33**  
`bbox=(54.1, 642.4, 146.5, 653.3)`

```
29
auipc....PASS

```

**Block 34**  
`bbox=(54.1, 659.3, 146.5, 670.3)`

```
30
lui......PASS

```

**Block 35**  
`bbox=(54.1, 676.2, 146.5, 687.2)`

```
31
beq......PASS

```

**Block 36**  
`bbox=(54.1, 693.2, 146.5, 704.1)`

```
32
bne......PASS

```

**Block 37**  
`bbox=(54.1, 710.1, 146.5, 721.1)`

```
33
blt......PASS

```

**Block 38**  
`bbox=(54.1, 727.0, 146.5, 738.0)`

```
34
bltu.....PASS

```

**Block 39**  
`bbox=(54.1, 744.0, 146.5, 755.0)`

```
35
bge......PASS

```

**Block 40**  
`bbox=(54.1, 760.9, 146.5, 771.9)`

```
36
bgeu.....PASS

```

**Block 41**  
`bbox=(294.9, 789.5, 300.4, 802.9)`

```
4

```


---

## Page 5

![Page 5 snapshot](/mnt/data/export_fitz_noocr/milestone-2-extra/page-5.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(294.1, 34.3, 523.3, 47.7)`

```
Milestone 2 Extra
—
Computer Architecture

```

**Block 2**  
`bbox=(54.1, 74.0, 146.5, 85.0)`

```
37
jal......PASS

```

**Block 3**  
`bbox=(54.1, 90.9, 146.5, 101.9)`

```
38
jalr.....PASS

```

**Block 4**  
`bbox=(54.1, 107.9, 152.2, 118.8)`

```
39
malgn....ERROR

```

**Block 5**  
`bbox=(54.1, 124.8, 146.5, 135.8)`

```
40
iosw.....PASS

```

**Block 6**  
`bbox=(54.1, 145.1, 60.0, 152.4)`

```
41

```

**Block 7**  
`bbox=(54.1, 158.7, 89.2, 169.6)`

```
42
END

```

**Block 8**  
`bbox=(88.9, 192.3, 523.3, 205.7)`

```
Note that handling of misaligned memory addresses is not mandatory, and such scenarios

```

**Block 9**  
`bbox=(72.0, 209.3, 210.4, 222.6)`

```
may result in an error status.

```

**Block 10**  
`bbox=(72.0, 242.4, 279.6, 257.2)`

```
4.2
Troubleshooting Common Issues

```

**Block 11**  
`bbox=(72.0, 267.9, 523.3, 281.3)`

```
While the test is termed an “ISA Test,” it is designed to validate functional correctness by

```

**Block 12**  
`bbox=(72.0, 284.9, 523.3, 298.3)`

```
integrating multiple instructions in each stage.
This approach ensures robust verification

```

**Block 13**  
`bbox=(72.0, 301.8, 259.3, 315.2)`

```
rather than isolated instruction testing.

```

**Block 14**  
`bbox=(88.9, 318.8, 523.3, 332.3)`

```
Hint: Ensure that the “trinity” of instructions — beq, jal, and addi — is correctly imple-

```

**Block 15**  
`bbox=(72.0, 335.7, 450.6, 349.1)`

```
mented, as errors in these instructions can cascade and cause other tests to fail.

```

**Block 16**  
`bbox=(294.9, 789.5, 300.4, 802.9)`

```
5

```

