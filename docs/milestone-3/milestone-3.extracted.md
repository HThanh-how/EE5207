# Extracted from milestone-3.pdf


=== Page 1 ===
Milestone 3 — Computer Architecture
Design of Pipelined RISC-V Processors
Hai Cao
rev 2.0.0
Contents
1 Objectives 2
2 Overview 2
2.1 Processor Specification . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 5
2.2 General Guidelines . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 5
2.2.1 Directory structure . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 5
2.2.2 Functional verification . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 5
3 Week 1: Divide and Conquer 7
3.1 Pipelining . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 7
3.2 Memory Modeling and Memory Mapping . . . . . . . . . . . . . . . . . . . . . . 7
3.3 BRAM Modeling . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 8
4 Week 2-3: Five Models and Beyonds 8
4.1 Non-forwarding . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 8
4.2 Forwarding . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 9
4.3 Forwarding with Always Taken . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 9
4.4 Two-Bit Dynamic Branch Prediction . . . . . . . . . . . . . . . . . . . . . . . . . . 9
4.5 G-share Branch Prediction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 9
5 Week 4: Implementation, Presentation, and Submission 10
5.1 Implementation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 10
5.2 Presentation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 10
5.3 Submission . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 11
6 Week 5: Penalty 11
1
=== Page 2 ===
Milestone 3 — Computer Architecture
7 ISA Test – Functional Verification 12
7.1 Environment Setup . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 12
7.2 Project Directory Hierarchy . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 12
7.3 Memory Configuration . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
7.4 File Setup for Verilator . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
7.5 File Setup for Xcelium . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
7.6 Simulation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 13
7.7 Expected Result . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 14
7.8 Troubleshooting Common Issues . . . . . . . . . . . . . . . . . . . . . . . . . . . . 15
8 Benchmarking 15
9 Modified Processor 15
10 I/O System Conventions 15
11 Applications 17
12 Rubric 18
12.1 Report . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 18
Abstract
Thisdocumentprovidesanoverviewofthetasks,expectations,andrequirementsforthe
finalmilestoneintheComputerArchitecturecourse. Itdetailsthespecificcomponentsand
specificationsstudentsmustfollowtosuccessfullydesignatleast2modelsofpipelinedpro-
cessorsusingISARV32I.Foranyerrorsfoundorsuggestionsforenhancement,contactthe
TAviaemailatcxhai.sdh221@hcmut.edu.vnusingthesubjectline“ [CA203FEEDBACK] ”.
1 Objectives
•Review understanding of pipeline techniques
•Design several models of pipelined processors for comparison
•Explore the Branch Prediction technique
2 Overview
In this significant milestone, students are assigned the responsibility of designing multiple
models of the RV32I processor employing pipelined techniques, as outlined in the lectures.
The primary objective of this milestone is to compare at least two techniques to comprehend
the functionality of pipelining a processor and address its limitations to attain enhanced per-
formance. Given that the base processor has been successfully implemented in Milestone 2,
students are permitted to reuse its components, thereby enabling a feasible timeframe of four
2
=== Page 3 ===
Milestone 3 — Computer Architecture
weeks for implementing these strategies. However, it is noteworthy that individuals seeking
to enhance the frequency and capacity of their processor must employ BRAMs. While not
mandatory, their utilization is highly recommended and may result in additional credit.
Furthermore,studentswhodemonstrateathoroughunderstandingoftheconceptofbranch
prediction are eligible to incorporate branch predictors into their processors, which will be
awarded bonus credits. It is important to note that all the prerequisites for communication
between your custom processor (soft-core) and external peripherals remain unchanged.
For undergraduate students, an additional penalty week is allocated to ensure the fulfill-
ment of the milestone requirements.
3
=== Page 4 ===
Milestone 3 — Computer Architectureo_pc_debug
o_io_ledr
o_io_ledg
o_io_lcd
i_io_swo_io_hex0..7o_insn_vld
I$
Regfilepc
instrpc_next+4pc_four
LSUDecoder
(Control Unit)
BRCstallflush
stallflush
stall flushHazard Detection
Forwarding Unit
rs1_addr
rs2_addrrd_addr
is_load rd_addr
pc+4
pc_selflushstallforward
o_mispred
o_ctrl
Figure 1: Pipelined Processor with Hazard Detection and Forwarding Unit
4
=== Page 5 ===
Milestone 3 — Computer Architecture
2.1 Processor Specification
•Top-level module: pipelined.sv
•I/O ports:
Signal name Width Direction Description
i_clk 1 input Global clock, active on the rising edge.
i_reset 1 input Global low active reset.
o_pc_debug 32 output Debug program counter.
o_insn_vld 1 output Instruction valid.
o_ctrl 1 output Control transfer instructions (branch or jump).
o_mispred 1 output Mispredict.
o_io_ledr 32 output Output for driving red LEDs.
o_io_ledg 32 output Output for driving green LEDs.
o_io_hex0..7 7 output Output for driving 7-segment LED displays.
o_io_lcd 32 output Output for driving the LCD register.
i_io_sw 32 input Input for switches.
2.2 General Guidelines
2.2.1 Directory structure
Theprojectshouldmaintainawell-organizeddirectoryhierarchyforefficientmanagementand
submission:
1milestone2
2|-- 00_src # Verilog source files
3|-- 01_bench # Testbench files
4|-- 02_test # Memory files
5|-- 10_sim # Simulation files
6|-- 20_syn # Synthesis files
7| `-- quartus
8| | -- run # Makefile for synthesis
9| `-- src # Source files specific to synthesis
10`-- 99_doc # Documentation files
2.2.2 Functional verification
To ensure that the implemented design meets the expected functional behavior, leveraging
a systematic testing environment, students are provided with a verification environment for
straightforwardISAtests. Students’designsactasDUT(DeviceUnderTest)intheenvironment,
5
=== Page 6 ===
Milestone 3 — Computer Architecture
with provided modules for driving stimuli and collecting results. Students are expected to
organize their source code correctly, navigate to the simulation directory, and execute the
provided scripted makefile for automated simulation. If they already follow the previous
structure, copying and pasting the content of 00_srcwill suffice.
1pl-test
2|-- 00_src # Verilog source files
3|-- 01_bench # Testbench files
4| | -- driver.sv
5| | -- scoreboard.sv
6| | -- tbench.sv
7| `-- tlib.svh
8|-- 02_test # Testing files
9| `-- isa.mem # Hex file
10|-- 10_sim # Verilator
11| | -- flist
12| `-- Makefile
13`-- 11_xm # Xcelium
14 |-- flist
15 `-- Makefile
When the verification with ISA tests completes, students must copy that directory pl_test
and paste into their designated directories for submission.
6
=== Page 7 ===
Milestone 3 — Computer Architecture
3 Week 1: Divide and Conquer
In the first week, students should focus on pipelining the processor and design new memory
models.
3.1 Pipelining
ReferringtoFigure1,studentsaretaskedwithsegmenting( divide)theirsingle-cycleprocessor
into distinct stages and employing ( conquer) flip-flops to control the data flow of incoming
instructions through the pipeline. Initially, there may be several challenges to overcome.
However, it is essential to consider the following key points:
1. Enable and Reset signals of each stage are critical for a proper pipelined processor. Any
issues at first arise from their improper control.
2.insn_vld is now playing an important role, since flushing an instruction invalidates it,
preventingitfrombeingcountedasaninstructioninthecodeflowduringthefinalstage
(WB). This ensures accurate computation.
3.o_ctrlsignalisaddedtorecordcontroltransferinstructions. Ifabranchorjumpinstruc-
tion is in the WB stage, this signal is asserted with a value of 1.
4.o_mispred signalisaddedtorecordmispredictions,whentheHazardDetectionassertsa
flush due to a control transfer instruction being mispredicted. This signal is propagated
to the WB stage as well.
5. Placing a single instruction in the pipeline to verify its correct flow through each stage.
Subsequently,introducemoreinstructions withoutanyhazards andcomparethenumber
of active o_insn_vld signals (high) with the expected number of instructions.
3.2 Memory Modeling and Memory Mapping
This milestone necessitates the utilization of synchronous read and synchronous write mem-
ory models to achieve optimal timing and frequency. Consequently, students are prohibited
from reusing memory models in Milestone 2 and are required to design new ones. The re-
quirement to load the same data file into both data memory and instruction memory remains
valid.
Memory mapping is now anticipated to allocate 64KiB in the Memory/RAM region for
future benchmarking purposes. Individuals fail to utilize memory bits or BRAM and, conse-
quently,resorttologicelementsforgeneratingmemory,theyshouldconsiderimplementingthe
memorymappingofMilestone2iftheystillintendtoutilizeFPGAsandexecuteapplications.
7
=== Page 8 ===
Milestone 3 — Computer Architecture
Base address Top address Mapping
0x1001_1000 0xFFFF_FFFF (Reserved)
0x1001_0000 0x1001_0FFF Switches (required)
0x1000_5000 0x1000_FFFF (Reserved)
0x1000_4000 0x1000_4FFF LCD Control Registers
0x1000_3000 0x1000_3FFF Seven-segment LEDs 7-4
0x1000_2000 0x1000_2FFF Seven-segment LEDs 3-0
0x1000_1000 0x1000_1FFF Green LEDs (required)
0x1000_0000 0x1000_0FFF Red LEDs (required)
0x0001_0000 0x0FFF_FFFF (Reserved)
0x0000_0000 0x0000_FFFF Memory ( 64 KiB)(required)
Table 1: Pipelined Processor Memory Mapping
3.3 BRAM Modeling
If students are interested in utilizing BRAMs, kindly refer to the following link for compre-
hensive information on their functionality and proper implementation: Cyclone II Memory
Blocks.
4 Week 2-3: Five Models and Beyonds
Within the next two weeks, students are required to select two or more models introduced
in this section for implementation. The successful “divide and conquer” approach without
hazardinstructionsinWeek1servesasthefoundationforanysubsequentmodificationsbased
on the models below.
The baseline submission should design Non-forwarding andForwarding , ensuring the
inclusion of at least two models with their respective parameters for comparison. Milestone 3
isdesignedtobeIncremental,whichthenextmodelbuildsuponthepreviousmodels. Inother
words, “designing and verifying the functionality of the previous model before modifying it
into the next one.” Students who select more than two models are permitted to exclude the
initial two models: Non-forwarding and/orForwarding .
Remember:
1. The o_ctrlsignal should be asserted a control transfer instruction is present.
2. The o_mispred signal should be asserted when a flush happens to clear a wrong control
transfer instruction (branch or jump).
4.1 Non-forwarding
Building upon the design established in Week 1, you are now required to incorporate Hazard
Detection functionality to identify potential hazards between instructions. After doing so,
8
=== Page 9 ===
Milestone 3 — Computer Architecture
you must control two crucial signals, stalland flush, to direct the execution of instructions
accordingly.
4.2 Forwarding
With the assistance of a forwarding network and the dedicated Forwarding Unit, the transfor-
mationofNon-forwardingintoForwardingcanbeaccomplishedwithrelativeease. However,it
isimperativetoexercisecautionwhenhandlingloadinstructions,astheypossessthepotential
to engender deadlocks.
4.3 Forwarding with Always Taken
By default, the previous design is “always not-taken”. To implement a forwarding model
where the previous instruction is “always taken”, a Branch Target Buffer (BTB) is required.
This buffer records the predicted program counter (PC) for each branch or jump instruction.
Consequently, the Fetch stage must be modified to retrieve the predicted PC from the BTB if
the current PC is stored in the BTB.
4.4 Two-Bit Dynamic Branch Prediction
The preceding models are limited to static prediction due to the absence of a predictor. This
model necessitates a straightforward predictor employing the two-bit prediction scheme. The
one-bit scheme is inadvisable due to its susceptibility to corner cases, and the distinction
between designing two-bit and one-bit schemes is minimal.
4.5 G-share Branch Prediction
Those who decide to implement this model know what they are doing. Good luck!
9
=== Page 10 ===
Milestone 3 — Computer Architecture
5 Week 4: Implementation, Presentation, and Submission
5.1 Implementation
In this final week, students are expected to complete their processor designs. The primary
focus of this week is to conduct synthesis on Quartus and implement their designs on DE-2
board. Students are welcome to utilize the labs located on Campuses 1 and 2 for hardware
implementation. Please approach the lab supervisors for access. Any excuses for not having
access to DE-2 will not be considered as a valid reason for failing to meet the milestone.
Following a successful synthesis attempt, kindly record the following data:
Model Non-forwarding Forwarding Two-bit
Frequency𝐹𝑚𝑎𝑥(MHz)
Total logic elements ( %)
Total registers ( %)
Total memory bits ( %)
Table 2: Pipelined Processors Synthesis Comparison
Additionally, you have to record the 𝐼𝑃𝐶and Mispredict Rate of the ISA test and at least
one program you write. Record the result and make a table and a chart for illustration.
Note:you may observe the tbench.sv to write your calculation for 𝐼𝑃𝐶and Mispredict
Rate.
Test Non-forwarding Forwarding Two-bit
ISA testIPC
Mispred Rate ( %)
My Test 1IPC
Mispred Rate ( %)
My Test 2IPC
Mispred Rate ( %)
Table 3: Pipelined Processors Performance Comparison
5.2 Presentation
Duringtheweekendofthefourthweek,typicallyonSaturdayorSunday,studentsareobligated
to be present in person to submit their milestone. Should you be unable to present, an email
to the Teaching Assistant (TA) should be sent by Friday. However, if you do not receive a
confirmation email, your absence will still be considered.
10
=== Page 11 ===
Milestone 3 — Computer Architecture
5.3 Submission
Your submission project is the directory pl-test that you have executed ISA tests. You must
verify that your source code files are in 00_srcand simulation can be executed successfully in
either 10_simor11_xm.
You should number your models as pl-test-model-1 ,pl_test-model-2 , ...
Designated submission directories are located in ~/submission . For instance, if your user-
nameis ca101,yoursubmissionfolderwouldbe ~/submission/ca101 . Thenextstepistocopy
your pl-testandplaceitin ~/submission/ca101 underthesamename. Youmustsubmityour
code and report prior to the Presentation day.
Note:Your code will be scrutinized and run again by TA.
6 Week 5: Penalty
Groups who are unable to complete the assessment within the four-week timeframe may
present in the following Saturday only. However, your score will be reduced by one point.
11
=== Page 12 ===
Milestone 3 — Computer Architecture
7 ISA Test – Functional Verification
The following are key aspects to understand before proceeding with the simulation:
1. The test environment monitors o_pc_debug and o_io_ledr signals to determine test out-
comes, indicating either a “ pass” or “error” condition.
2. Due to the flexible memory mapping requirements, your design must support 32-bit
load/store operations to the LEDR register, mapped to address 0x1000_0000 .
7.1 Environment Setup
Prior to commencing the test, students must copy the singlecycle test from the common direc-
tory to their home directory and navigate to it.
1cd ~
2cp -rf ~/common/pl-test .
3cd sc-test
7.2 Project Directory Hierarchy
Theprojectstructureadherestoahierarchicalorganizationtofacilitateefficientsimulationand
verification. Directories are structured as follows:
1pl-test
2|-- 00_src # Verilog source files
3|-- 01_bench # Testbench files
4| | -- driver.sv
5| | -- scoreboard.sv
6| | -- tbench.sv
7| `-- tlib.svh
8|-- 02_test # Testing files
9| `-- isa.mem # Hex file
10|-- 10_sim # Verilator
11| | -- flist
12| `-- Makefile
13`-- 11_xm # Xcelium
14 |-- flist
15 `-- Makefile
00_srcPlace all SystemVerilog source files here.
01_bench Thisdirectoryprovidesinsightintothetestbenchsetup. Studyitscontentstounderstand
the simulation environment.
12
=== Page 13 ===
Milestone 3 — Computer Architecture
02_test Contains the file isa.mem, a hexadecimal file representing the instruction set test.
10_simThis directory includes scripts for simulation using Verilator.
11_xmThis directory contains scripts for simulation using Cadence Xcelium.
7.3 Memory Configuration
Toensurecompatibilitywiththetestbench,makethefollowingmodificationstoyourmemory
models:
•Since the testbench requires 64 KiB, your design must use an address width of at least
16 bitsto supporting a memory size of 64 KiBas in Table 3.
•The memory must be preloaded with the contents of 02_test/isa.mem to provide test
instructions.
7.4 File Setup for Verilator
To run simulations using Verilator, change into 10_simdirectory and edit flistfile to include
allrelevantdesignfiles. Forexample,ifyourtop-levelmoduleisnamed pipelined.sv ,include
the entry:
1./../00_src/pipelined.sv
7.5 File Setup for Xcelium
ToexecutesimulationsusingCadenceXcelium,changeinto 11_xmdirectoryandedit flistfileto
includeallrelevantdesignfiles. Forexample,ifyourtop-levelmoduleisnamed pipelined.sv ,
include the entry:
1./../00_src/pipelined.sv
7.6 Simulation
With all setup completed, you must first access computing resource and run Makefile script.
1. Run the command below to access a computing node. Without “ --x11”, you cannot use
GUI.
1srun --x11 --pty bash
2. IfyouuseVerilator,navigatetodirectory 10_simandrun“ make”. Toobservewaveforms,
run “ make wave ” to open Surfer or GTKWave.
13
=== Page 14 ===
Milestone 3 — Computer Architecture
3. In case you use Xcelium, navigate to directory 11_xmand run “ make”. To observe wave-
forms, run “ make gui ” to open SimVision.
7.7 Expected Result
A correctly functioning design should produce the expected output as below:
1
2PIPELINE - ISA tests
3
4add......PASS
5addi.....PASS
6sub......PASS
7and......PASS
8andi.....PASS
9or.......PASS
10ori......PASS
11xor......PASS
12xori.....PASS
13slt......PASS
14slti.....PASS
15sltu.....PASS
16sltiu....PASS
17sll......PASS
18slli.....PASS
19srl......PASS
20srli.....PASS
21sra......PASS
22srai.....PASS
23lw.......PASS
24lh.......PASS
25lhu......PASS
26lb.......PASS
27lbu......PASS
28sw.......PASS
29sh.......PASS
30sb.......PASS
31auipc....PASS
32lui......PASS
33beq......PASS
34bne......PASS
35blt......PASS
36bltu.....PASS
14
=== Page 15 ===
Milestone 3 — Computer Architecture
37bge......PASS
38bgeu.....PASS
39jal......PASS
40jalr.....PASS
41malgn....ERROR
42iosw.....PASS
43
44Result
45
46IPC = 0.xx
47Mispred Rate =x.xx
48
49END of ISA tests
As handling of misaligned memory addresses is not mandatory, and such scenarios may
result in an error status.
7.8 Troubleshooting Common Issues
While the test is termed an “ISA Test,” it is designed to validate functional correctness by
integrating multiple instructions in each stage. This approach ensures robust verification
rather than isolated instruction testing.
Hint:Ensure that the “Elite Four” of instructions — addi,beq,jal, and lui— is correctly
implemented, as errors in these instructions can cascade and cause other tests to fail.
8 Benchmarking
Content to be added in future versions.
9 Modified Processor
Youmayimplementamodifiedprocessordesigntoincorporateadditionalfeaturesoroptimiza-
tions. However, it is essential to first demonstrate a complete understanding of the standard
processor design. All modifications should be clearly documented and justified.
10 I/O System Conventions
For consistent operation and testing, adhere to the following conventions for setting up with
DE2 boards and interacting with the I/O system.
Note:OnlywhenconnectedtoDE2board,thoseperipheralsdatawillbetruncatedaccord-
ingly.
15
=== Page 16 ===
Milestone 3 — Computer Architecture
•LEDsUse the output ports o_io_ledr and o_io_ledg to control the red and green LEDs,
respectively. These can be used for status indicators or debugging.
o_io_ledr
Bits Usage
31 - 17 (Reserved)
16 - 0 17-bitdataconnectedtothearrayof17redLEDsinorder.
o_io_ledg
Bits Usage
31 - 8 (Reserved)
7 - 0 8-bitdataconnectedtothearrayof8greenLEDsinorder.
•Seven-Segment Utilize o_io_hex0..7 todisplaynumericalvaluesormessages. Eachport
has 7 bits in total, so four of them can represent a 32-bit data as shown below. To control
each seven-segment display, stores a byte at the corresponding address, such as SBat
0x1000_2000 willchangethevalueofHEX2,while SHatthesamelocationwillaffectboth
HEX2 and HEX3. For the case of misaligned addresses, your assumption is critical.
Address 0x1000_2000
Bits Usage
31 (Reserved)
30 - 24 7-bit data to HEX3.
23 (Reserved)
22 - 16 7-bit data to HEX2.
15 (Reserved)
14 - 8 7-bit data to HEX1.
7 (Reserved)
6 - 0 7-bit data to HEX0.
Address 0x1000_3000
Bits Usage
31 (Reserved)
30 - 24 7-bit data to HEX7.
23 (Reserved)
22 - 16 7-bit data to HEX6.
15 (Reserved)
14 - 8 7-bit data to HEX5.
7 (Reserved)
6 - 0 7-bit data to HEX4.
16
=== Page 17 ===
Milestone 3 — Computer Architecture
•LCD Display Manage more complex visual output through o_io_lcd . To drive LCD
properly, visit this link to investigate the specification of LCD HD44780.
Bits Usage
31 ON
30 - 11 (Reserved)
10 EN
9 RS
8 R/W
7 - 0 Data.
•Switches Use i_io_swtoreceiveinputfromexternalswitches,whichcanbeusedforuser
interaction or control signals.
Bits Usage
31 - 18 (Reserved)
17 Reset.
16 - 0 17-bit data from SW16 to SW0 respectively.
11 Applications
Developanapplicationthatutilizesthedesignedprocessor,demonstratingitscapabilitiesand
practicaluse. Thecomplexityandinnovationoftheapplicationwillimpactyourgrading. Sim-
pleapplicationsmightincludebasicinput/outputhandling,whilemoreadvancedapplications
could involve complex calculations or data processing.
Below are some example programs with its expected score:
•Design a stopwatch using seven-segment LEDs as the display.
•Convertahexadecimalnumbertoadecimalnumberanddisplayonseven-segmentLEDs.
•Convert a hexadecimal number to its decimal and binary forms and display on LCD.
•Input32-DcoordinatesofA,B,andC.Determinewhichpoint,AorB,isclosertoCusing
LCD as the display.
17
=== Page 18 ===
Milestone 3 — Computer Architecture
12 Rubric
Your project will be evaluated based on the following criteria:
1.BaselineSubmission–7pts: IfyourdesignssuccessfullypasstheISAtest,youwillearn
7 points. Please ensure that your source code is submitted to the server for verification
and transparency and your reports on LMS. No in-person presentation is required. If
youchoosenottopresentyourwork,pleaseindicateyourconsentintheGroupSign-Up
sheet.
2.BRAM Utilization – 1 pts: Individuals who employ BRAM to enhance the frequency of
their processors will receive a one-point bonus.
3.Branch Prediction – 2 pts: Those that integrate branch predictors introduced in the
lecture, such as the two-bit scheme and G-share, will earn additional points depending
on the complexity of the design.
4.Advanced or Alternative Design – 2 pts: For students who incorporate substantial
modifications or enhancements to the baseline processor design, up to two additional
pointswillbeawarded. Theassessmentwillbebasedontheinnovation,complexity,and
functionality of these improvements.
5.Bonus: Benchmarking–1pts: Studentswhobenchmarktheirprocessorswithprovided
benchmark tests in this course will receive an additional credit.
12.1 Report
A comprehensive project report must be submitted, detailing the design process, challenges
faced, and solutions implemented. Refer to the report guidelines on Google Drive. The
report should be clear and concise, with sections for introduction, methodology, results, and
conclusions. Visual aids such as diagrams and charts are encouraged to illustrate key points.
18