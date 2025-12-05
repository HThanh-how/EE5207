# Hướng dẫn Test Local - Single Cycle RISC-V Processor

## Yêu cầu

Để test local, bạn cần một trong các SystemVerilog simulator sau:

### 1. Cadence Xcelium (Khuyến nghị cho server)
```bash
cd 03_sim
make create_filelist
make sim
```

### 2. ModelSim/QuestaSim
```bash
cd 03_sim
make create_filelist
vlog -sv -f flist
vsim -c -do "run -all; quit" -voptargs=+acc tbench
```

### 3. Vivado Simulator (Xilinx - Miễn phí)
```bash
cd 03_sim
make create_filelist
# Tạo project trong Vivado và add files từ flist
vivado -mode batch -source run_sim.tcl
```

### 4. Icarus Verilog (Open Source - Miễn phí)
```bash
cd 03_sim
make create_filelist
iverilog -g2012 -f flist -o sim
vvp sim
```

**Lưu ý**: Icarus Verilog có thể không hỗ trợ đầy đủ SystemVerilog, cần kiểm tra syntax.

### 5. Verilator (Open Source - Miễn phí)
```bash
cd 03_sim
make create_filelist
verilator --cc --exe --build --top-module tbench -f flist
obj_dir/Vtbench
```

## Test với script tự động

### Windows:
```cmd
cd 03_sim
run_local_test.bat
```

### Linux/Mac:
```bash
cd 03_sim
chmod +x run_local_test.sh
./run_local_test.sh
```

## Kết quả mong đợi

Khi test thành công, bạn sẽ thấy:
```
SINGLE CYCLE - ISA test

[... output từ o_io_ledr[7:0] khi PC = 0x18 ...]

END of ISA test
```

## Xem waveform (nếu có)

### Cadence Xcelium:
```bash
make wave
```

### ModelSim:
```bash
vsim -gui -f flist
```

### Vivado:
Mở Vivado và xem waveform trong GUI.

## Troubleshooting

### Lỗi "flist not found"
```bash
make create_filelist
```

### Lỗi "File not found" khi đọc hex file
Đảm bảo bạn đang chạy từ thư mục `03_sim` và đường dẫn `../02_test/isa_1b.hex` đúng.

### Lỗi syntax với Icarus Verilog
Icarus Verilog có thể không hỗ trợ một số cú pháp SystemVerilog. Nên dùng ModelSim hoặc Verilator.

### Timeout error
Kiểm tra xem processor có bị stuck không. Tăng timeout trong `tbench.sv` nếu cần:
```systemverilog
`define FINISH 40_000  // Tăng giá trị này nếu cần
```

## Test trên server

Khi submit lên server, server sẽ dùng `xrun` để test. Đảm bảo code của bạn:
1. Compile không lỗi với `xrun`
2. Pass được test case `isa_1b.hex`
3. Output đúng khi PC = 0x18 và kết thúc tại PC = 0x1C

