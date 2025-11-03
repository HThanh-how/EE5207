@echo off
REM Single Cycle RISC-V Processor - Local Test Script for Windows
REM ==============================================================

cd /d "%~dp0"

echo ==========================================
echo Single Cycle RISC-V Processor - Local Test
echo ==========================================
echo.

REM Check if flist exists
if not exist flist (
    echo Creating file list...
    make create_filelist
)

REM Try different simulators
where xrun >nul 2>&1
if %errorlevel% == 0 (
    echo Using Cadence Xcelium (xrun)...
    xrun -access +rwc -f ./flist
    goto :end
)

where vlog >nul 2>&1
if %errorlevel% == 0 (
    echo Using ModelSim/QuestaSim...
    vlog -sv -f flist
    vsim -c -do "run -all; quit" -voptargs=+acc tbench
    goto :end
)

where iverilog >nul 2>&1
if %errorlevel% == 0 (
    echo Using Icarus Verilog...
    iverilog -g2012 -f flist -o sim.exe
    sim.exe
    goto :end
)

where verilator >nul 2>&1
if %errorlevel% == 0 (
    echo Using Verilator...
    verilator --cc --exe --build --top-module tbench -f flist
    obj_dir\Vtbench.exe
    goto :end
)

echo ERROR: No supported simulator found!
echo Please install one of:
echo   - Cadence Xcelium (xrun)
echo   - ModelSim/QuestaSim (vlog/vsim)
echo   - Icarus Verilog (iverilog)
echo   - Verilator
exit /b 1

:end
pause

