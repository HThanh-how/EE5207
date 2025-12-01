# Extracted from pipeline.pdf


=== Page 1 ===
Pipeline Technique & Branch Prediction
Implementation
Computer Architecture 101 – Day 1
Hai Cao
Dept. of Electronics
HCMC University of Technology – VNU-HCM
rev 1.0
=== Page 2 ===
Table of contents
1. Pipeline Idealism
2. Pipelined Processor
3. Hazards
4. Branch Prediction
Computer Architecture 203 Pipeline & Branch Prediction 2/64
=== Page 3 ===
Pipeline Idealism
=== Page 4 ===
Pipeline Idealism
Laundry Analogy
1. Place one dirty load of clothes in the washer.
2. When the washer is finished, place the wet load in the dryer.
3. When the dryer is finished, place the dry load on a table and fold.
4. When folding is finished, ask your roommate to put the clothes away.
Computer Architecture 203 Pipeline & Branch Prediction 4/64
=== Page 5 ===
Pipeline Idealism
Laundry Analogy
1.Throughput increased by 4
2.Latency of a load remains unchanged.
⇒If the number of loads increases, with higher throughput , the completion time decreases.
Computer Architecture 203 Pipeline & Branch Prediction 5/64
=== Page 6 ===
Pipeline Idealism
Motivation
▶Increase throughput without additional hardware.
▶Allow multiple instructions to overlap in execution.
Computer Architecture 203 Pipeline & Branch Prediction 6/64
=== Page 7 ===
Pipeline Idealism
Performance and Cost
Given:A system requires Ggates and takes Ttime to execute. If the system is pipelined, each stage
introduces an additional Lflip-flops/latches, which require Stime. With kis the number of stages:
1.Throughput/Performance is the number of tasks processed in a second.
▶Nonpipelined:
Pnonpilelined=1
T+S
▶Pipelined:
Ppipelined=1
T/k+S
2.Costrefers to the total count of combinational logic gates, which influences the power
consumption.
▶Nonpipelined:
Cnonpilelined=G+L
▶Pipelined:
Cpipelined=G+Lk
Computer Architecture 203 Pipeline & Branch Prediction 7/64
=== Page 8 ===
Pipeline Idealism
Trade-off
y=Cost
Performance
=(Lk+G)
T
k+S
=LT+GS+LSk+GT
k
dy
dk=LS−GT
k2
⇒kopt=r
LS
GTkopt
kCost/Performance
Computer Architecture 203 Pipeline & Branch Prediction 8/64
=== Page 9 ===
Pipelined Processor
=== Page 10 ===
Pipelined Processor
Instruction Pipelining
Each RISC-V instruction is simple and generally needs 5 steps/stages:
FFetchinstruction from memory.
DDecodeinstruction and read data from Regfile.
XExecutethe operation or compute an address for memory related instructions.
MMemory is accessed for loading or storing data.
WWrite Back data to Regfile.
Instructions F D X M W
ALU ✓ ✓ ✓ ✓
Load ✓ ✓ ✓ ✓ ✓
Store ✓ ✓ ✓ ✓
Branch ✓ ✓ ✓ ✓
JAL ✓ ✓ ✓
JALR ✓ ✓ ✓ ✓
Computer Architecture 203 Pipeline & Branch Prediction 10/64
=== Page 11 ===
Pipelined Processor
Computer Architecture 203 Pipeline & Branch Prediction 11/64
=== Page 12 ===
Pipelined Processor
Computer Architecture 203 Pipeline & Branch Prediction 12/64
=== Page 13 ===
Pipelined Processor
Speed-up
Given:
mthe number of instructions
nthe number of pipelined stages
tthe required time of each stage to complete
The completed time
without pipelining mnt
with pipelining(m+n−1)t
S(n)=mnt
(m+n−1)t=mn
m+n−1
limm→∞S(n)=n
Computer Architecture 203 Pipeline & Branch Prediction 13/64
=== Page 14 ===
Pipelined Processor
Exercise
Given:A 5-stage pipelined processor with completed time of each stage as below
tF=200 ps
tD=300 ps
tX=250 ps
tM=200 ps
tW=150 ps
Questions:
1. Before pipelined, what is the maximum frequency of this processor ( fSC)?
2. What is the maximum frequency of this processor ( fPL)?
3. If this pipelined processor runs a program of 2300 lines of instruction, how long will it take to
complete the program ( T)?
Computer Architecture 203 Pipeline & Branch Prediction 14/64
=== Page 15 ===
Pipelined Processor
Seperating Stages
Computer Architecture 203 Pipeline & Branch Prediction 15/64
=== Page 16 ===
Pipelined Processor
LOAD in IF Stage
Computer Architecture 203 Pipeline & Branch Prediction 16/64
=== Page 17 ===
Pipelined Processor
LOAD in ID Stage
Computer Architecture 203 Pipeline & Branch Prediction 17/64
=== Page 18 ===
Pipelined Processor
LOAD in EX Stage
Computer Architecture 203 Pipeline & Branch Prediction 18/64
=== Page 19 ===
Pipelined Processor
LOAD in MEM Stage
Computer Architecture 203 Pipeline & Branch Prediction 19/64
=== Page 20 ===
Pipelined Processor
LOAD in WB Stage
Computer Architecture 203 Pipeline & Branch Prediction 20/64
=== Page 21 ===
Pipelined Processor
How to Wire RegWren
Computer Architecture 203 Pipeline & Branch Prediction 21/64
=== Page 22 ===
Pipelined Processor
How to Wire RegWren
Computer Architecture 203 Pipeline & Branch Prediction 22/64
=== Page 23 ===
Pipelined Processor
Pipelining
Computer Architecture 203 Pipeline & Branch Prediction 23/64
=== Page 24 ===
Pipelined Processor
Pipelining
Computer Architecture 203 Pipeline & Branch Prediction 24/64
=== Page 25 ===
Pipelined Processor
Pipelining
Computer Architecture 203 Pipeline & Branch Prediction 25/64
=== Page 26 ===
Pipelined Processor
How to Wire Control Signals
Computer Architecture 203 Pipeline & Branch Prediction 26/64
=== Page 27 ===
Pipelined Processor
How to Wire Control Signals
Computer Architecture 203 Pipeline & Branch Prediction 27/64
=== Page 28 ===
Pipelined Processor
How to Wire Control Signals
Computer Architecture 203 Pipeline & Branch Prediction 28/64
=== Page 29 ===
Hazards
=== Page 30 ===
Hazards
Hazards
Hazards happen when an instruction cannot execute in the expected cycle.
There are two types of hazard
▶Pipeline hazards
▶Structural hazard
▶Data hazard
▶Control hazard (or Branch hazard)
Computer Architecture 203 Pipeline & Branch Prediction 30/64
=== Page 31 ===
Hazards Structural Hazard
Structural Hazard
Von Neumann
CPUMemoryHarvard
address bus
data bus
CPUMemory
Program
Memory
DataModern
CPUMemory
Program
Memory
Data$
Computer Architecture 203 Pipeline & Branch Prediction 31/64
=== Page 32 ===
Hazards Data Hazard
Data Hazard
Whenaplannedinstructioncannotbeexecutedattheproperclockcyclebecausethedataneededfor
the execution are not yet available.
Read after Write
add r5, r3, r2
add r6, r5, r1
In this example, the second instruction READ r5, AFTER the first instruction WRITE it.
Computer Architecture 203 Pipeline & Branch Prediction 32/64
=== Page 33 ===
Hazards Data Hazard
Data Hazard
Case 1
i0: add r5, r3, r2
i1: xor r6, r5, r1
i2: sub r9, r3, r5
i3: or r2, r7, r5
i4: sll r4, r5, r5IF ID EX ME WB
i2i1i0
i2i1nopi0
i2i1nopnopi0
i2i1nopnopnop
i3i2i1nopnop
i4i3i2i1nop
“nop” to stall i1 untili0 writes successfully.
Computer Architecture 203 Pipeline & Branch Prediction 33/64
=== Page 34 ===
Hazards Data Hazard
Data Hazard
Case 2
i0: add r4, r3, r2
i1: lw r5, 0x40(r1)
i2: sub r9, r5, r1
i3: or r2, r7, r5
i4: sll r4, r5, r1IF ID EX ME WB
i2i1i0
i3i2i1i0
i3i2nopi1i0
i3i2nopnopi1
i3i2nopnopnop
i4i3i2nopnop
“nop” to stall i2 untili1 writes successfully.
Computer Architecture 203 Pipeline & Branch Prediction 34/64
=== Page 35 ===
Hazards Data Hazard
Control Hazard
Case 3
i0: add r4, r3, r2
i1: beq r5, r6, _L0
i2: sub r9, r5, r1
...
i8: _L0
sll r4, r5, r1
i9: xor r6, r8, r2IF ID EX ME WB
i2i1i0
i3i2i1i0
...i3i2i1i0
If instruction i1 is NOT TAKEN, there is nothing to worry about.
Computer Architecture 203 Pipeline & Branch Prediction 35/64
=== Page 36 ===
Hazards Data Hazard
Data Hazard
Case 3
i0: add r4, r3, r2
i1: beq r5, r6, _L0
i2: sub r9, r5, r1
...
i8: _L0
sll r4, r5, r1
i9: xor r6, r8, r2IF ID EX ME WB
i2i1i0
i3i2i1i0
i8nopnopi1i0
i9i8nopnopi1
i9i8nopnop
i9i8nop
But in the other case, i2 andi3 must be flushed.
Computer Architecture 203 Pipeline & Branch Prediction 36/64
=== Page 37 ===
Hazards Data Hazard
How to Stall and Flush
Enable and Reset of Flipflop.
Computer Architecture 203 Pipeline & Branch Prediction 37/64
=== Page 38 ===
Hazards Forwarding
Forwarding
When the second instruction is in the pipeline, register x1 isn’t updated, yet its value is in the
pipeline already.
Forwarding — bypassing — is a method of resolving a data hazard by retrieving the missing data
element from internal buffers rather than waiting for it to arrive from programmer-visible registers
or memory.
Computer Architecture 203 Pipeline & Branch Prediction 38/64
=== Page 39 ===
Hazards Forwarding
Forwarding
Computer Architecture 203 Pipeline & Branch Prediction 39/64
=== Page 40 ===
Hazards Forwarding
Forwarding
Case 1
i0: add r5, r3, r2
i1: xor r6, r5, r1
i2: sub r9, r3, r5
i3: or r2, r7, r5
i4: sll r4, r5, r5IF ID EX ME WB
Computer Architecture 203 Pipeline & Branch Prediction 40/64
=== Page 41 ===
Hazards Forwarding
Forwarding
// 00: no forward
// 01: forward from WB
// 10: forward from MEM
ForwardA <- 0;
if(MEM.RdWren and (MEM.RdAddr != 0) and (MEM.RdAddr == EX.Rs1Addr))
ForwardA <- 10;
if(WB.RdWren and (WB.RdAddr != 0) and (WB.RdAddr == EX.Rs1Addr))
ForwardA <- 01;
What if both conditions are true?
Computer Architecture 203 Pipeline & Branch Prediction 41/64
=== Page 42 ===
Hazards Forwarding
Forwarding
// 00: no forward
// 01: forward from WB
// 10: forward from MEM
ForwardA <- 0;
if(MEM.RdWren and (MEM.RdAddr != 0) and (MEM.RdAddr == EX.Rs1Addr))
ForwardA <- 10;
else if (WB.RdWren and (WB.RdAddr != 0) and (WB.RdAddr == EX.Rs1Addr))
ForwardA <- 01;
Computer Architecture 203 Pipeline & Branch Prediction 42/64
=== Page 43 ===
Hazards Forwarding
Forwarding
Case 1
i0: add r5, r3, r2
i1: xor r6, r5, r1
i2: sub r9, r3, r5
i3: or r2, r7, r5
i4: sll r4, r5, r5IF ID EX ME WB
i2i1i0
i3i2i1i0
i4i3i2i1i0
i4i3i2i1
i4i3i2
i4i3
Forwarding resolves hazards of case 1.
Computer Architecture 203 Pipeline & Branch Prediction 43/64
=== Page 44 ===
Hazards Forwarding
Forwarding
Case 2
i0: add r4, r3, r2
i1: lw r5, 0x40(r1)
i2: sub r9, r5, r1
i3: or r2, r7, r5
i4: sll r4, r5, r1IF ID EX ME WB
Computer Architecture 203 Pipeline & Branch Prediction 44/64
=== Page 45 ===
Hazards Forwarding
Forwarding
MEM.enable <- 1;
if(MEM.RdWren and (MEM.RdAddr != 0) and MEM.isload and ((MEM.RdAddr == EX.Rs1Addr) or
(MEM.RdAddr == EX.Rs2Addr)) ↩→
MEM.enable <- 0;
Is this enough?
Computer Architecture 203 Pipeline & Branch Prediction 45/64
=== Page 46 ===
Hazards Forwarding
Forwarding
Case 2
i0: add r4, r3, r2
i1: lw r5, 0x40(r1)
i2: sub r9, r5, r1
i3: or r2, r7, r5
i4: sll r4, r5, r1IF ID EX ME WB
i2i1i0
i3i2i1i0
i4i3i2i1i0
i4i3i1i1
Where did instruction i2 go?
Computer Architecture 203 Pipeline & Branch Prediction 46/64
=== Page 47 ===
Hazards Forwarding
Forwarding
x.enable <- 1;
if(MEM.RdWren and (MEM.RdAddr != 0) and MEM.isload and ((MEM.RdAddr == EX.Rs1Addr) or
(MEM.RdAddr == EX.Rs2Addr)) ↩→
MEM.enable <- 0;
ID.enable <- 0;
EX.enable <- 0;
Is this enough?
Computer Architecture 203 Pipeline & Branch Prediction 47/64
=== Page 48 ===
Hazards Forwarding
Forwarding
Case 2
i0: add r4, r3, r2
i1: lw r5, 0x40(r1)
i2: sub r9, r5, r1
i3: or r2, r7, r5
i4: sll r4, r5, r1IF ID EX ME WB
i2i1i0
i3i2i1i0
i4i3i2i1i0
i4i3i2i1i1
Why did instruction i1 stay there?
Computer Architecture 203 Pipeline & Branch Prediction 48/64
=== Page 49 ===
Hazards Forwarding
Forwarding
x.enable <- 1;
if(MEM.RdWren and (MEM.RdAddr != 0) and MEM.isload and ((MEM.RdAddr == EX.Rs1Addr) or
(MEM.RdAddr == EX.Rs2Addr)) ↩→
MEM.enable <- 0;
MEM.reset <- 0;
ID.enable <- 0;
EX.enable <- 0;
Computer Architecture 203 Pipeline & Branch Prediction 49/64
=== Page 50 ===
Hazards Forwarding
Forwarding
Case 2
i0: add r4, r3, r2
i1: lw r5, 0x40(r1)
i2: sub r9, r5, r1
i3: or r2, r7, r5
i4: sll r4, r5, r1IF ID EX ME WB
i2i1i0
i3i2i1i0
i4i3i2i1i0
i4i3i2nopi1
i4i3i2nop
i4i3i2
Forwarding can’t completely resolve hazards of case 2. Why?
Computer Architecture 203 Pipeline & Branch Prediction 50/64
=== Page 51 ===
Branch Prediction
=== Page 52 ===
Branch Prediction Overview
Branch Prediction
Branch Prediction is a technique that predicts the next instruction when the processor encounters a
control transfer instruction, which is branch instruction or jump instruction.
→The lower the miss rate, the lower the consumed power
Computer Architecture 203 Pipeline & Branch Prediction 52/64
=== Page 53 ===
Branch Prediction Overview
Let’s do a little bit math
There are three types of branches, and each has its own “taken” probability.
▶Unconditional branch (jumps): Pjump=100%
▶Forward conditional branch ( if/else ):Pfw=50%
▶Backward conditional branch ( do/while ):Pbw=90%
Because Pjump=100%, let’s consider the other two only.
Given:The number of forward branches and that of backward branches are equal. The probability
of a banch to be taken:
P=Pfw+Pbw
2=50%+90%
2=70% (1)
Computer Architecture 203 Pipeline & Branch Prediction 53/64
=== Page 54 ===
Branch Prediction Overview
IPC
IPC—instructionspercycles—indicatestheperformaceofaprocessor. Ifapipelinedprocessorhas
too many “ nop”, IPC will decrease.
Given:The number of branch instructions is 20 %(Pbr), and the processor takes TWO-CYCLE
penalty (delay) for a branch instruction ( Δ).
IPC=Ninstr
Ncycle=1
PbrΔ+1=1
20%×2+1=71%
Computer Architecture 203 Pipeline & Branch Prediction 54/64
=== Page 55 ===
Branch Prediction Static Prediction
Static Prediction
However, because we do NOT need to delay if a branch instruction is not taken, (1) shows that
Pmis=70%, so:
IPC=Ninstr
Ncycle=1
PbrPmisΔ+1=1
20%×70%×2+1=78%
Computer Architecture 203 Pipeline & Branch Prediction 55/64
=== Page 56 ===
Branch Prediction Static Prediction
Static Prediction
But if we know the next PC of a branch instruction and allow the processor to always go to that PC,
Pmis=30%, so:
IPC=Ninstr
Ncycle=1
PbrPmisΔ+1=1
20%×30%×2+1=89%
→The performance is clearly enhanced.
Computer Architecture 203 Pipeline & Branch Prediction 56/64
=== Page 57 ===
Branch Prediction Static Prediction
Branch Target Buffer
BTB, Branch Target Buffer, will save predicted PCs of branch instructions, using PC as an index or
address. Because the last two bits are 00, and if all the other 30 bits are used, the buffer size will be
230=4GiB. It is big, and not all instructions are branches; it is wasteful. Thus, to ensure the
correctness of a smaller buffer, only low bits are used as the index, and the rest are called tags.
hittagpredicted PC
PC+4next PCPC
01
Computer Architecture 203 Pipeline & Branch Prediction 57/64
=== Page 58 ===
Branch Prediction Static Prediction
Branch Target Buffer
x1CA800 addi x11, x0, 30
x1CA804 addi x18, x0, 1
x1CA808 add x13, x0, x0
_COMPARE:
x1CA80C and x12, x11, x18
x1CA810 beq x12, x0, _ADD_EVEN
x1CA814 j _DECREASE
_ADD_EVEN:
x1CA818 add x13, x11, x13
_DECREASE:
x1CA81C sub x11, x11, x18
x1CA820 bne x11, x0, _COMPARE
_EXIT:
x1CA824 ...
...
_ANOTHER:
x2FB810 bgt x13, x12, _EXITtag predicted pc
... ... ...
0x203 0x00000 0x00000000
0x204 0x001CA 0x001CA818
0x205 0x001CA 0x001CA81C
0x206 0x00000 0x00000000
0x207 0x00000 0x00000000
0x208 0x001CA 0x001CA80C
0x209 0x00000 0x00000000
... ... ...
Computer Architecture 203 Pipeline & Branch Prediction 58/64
=== Page 59 ===
Branch Prediction Dynamic Prediction
Dynamic Prediction
To increase performance, the processor needs to decide when to “taken” or not.
hittagpredicted PC
PC+4next PCPC
01
taken
predict taken
predictor
Computer Architecture 203 Pipeline & Branch Prediction 59/64
=== Page 60 ===
Branch Prediction Dynamic Prediction
One Bit Scheme Predictor
Let’s set one bit to predict taken/not taken of branch instructions, this bit simply changes its
prediction when it predicts wrong. The accuracy might be 85 %.
pred
takenpred
!taken
taken!taken
Computer Architecture 203 Pipeline & Branch Prediction 60/64
=== Page 61 ===
Branch Prediction Dynamic Prediction
Two Bit Scheme Predictor
However, if the outcome is changing every time: TK–NT–TK–NT–TK–..., one-bit scheme becomes
useless, and thus two-bit schemes become superior. The accuracy might be 90 %.
pred
taken
pred
!takenpred
!takenpred
takenpred
taken
pred
!takenpred
!takenpred
taken
taken!taken
Computer Architecture 203 Pipeline & Branch Prediction 61/64
=== Page 62 ===
Branch Prediction G-share
G-share
Because the previous scheme only uses the last prediction result to predict future branches, it is not
sufficient. G-shareortwo-bitadaptiveglobalutilizesapattern—aregisterstoringbranchhistory—
to predict. Instead of one predictor FSM, a table called BHT (Branch History Table) contains a
collection of Npredictor FSMs, with pattern as index.
hittagpredicted PC
PC+4next PCPC
01
taken
predict takenBHT
pattern
Computer Architecture 203 Pipeline & Branch Prediction 62/64
=== Page 63 ===
Branch Prediction G-share
G-share
However, pattern should be used with PC to make pattern PC-relative, and thus BHT is utilized
efficiently. In this way, the accuracy would be 93 %.
hittagpredicted PC
PC+4next PCPC
01
taken
predict takenBHT
pattern
Computer Architecture 203 Pipeline & Branch Prediction 63/64
=== Page 64 ===
Questions?
Computer Architecture 203 Pipeline & Branch Prediction 64/64