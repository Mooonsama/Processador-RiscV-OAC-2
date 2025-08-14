# RISC-V Pipelined Processor Integration Summary

## What Was Integrated

### 1. **5-Stage Pipeline Architecture**
- **IF (Instruction Fetch)**: PC, Instruction Memory, IF/ID register
- **ID (Instruction Decode)**: Control Unit, Register File, Immediate Generator, ID/EX register  
- **EX (Execute)**: ALU, ALU Control, Forwarding Multiplexers, EX/MEM register
- **MEM (Memory Access)**: Data Memory, MEM/WB register
- **WB (Write Back)**: Write-back multiplexer

### 2. **Forwarding Unit Integration**
- **Location**: Between EX/MEM and MEM/WB stages
- **Function**: Detects RAW hazards and forwards data from later stages
- **Signals**: 
  - `forward_a` and `forward_b` control ALU input multiplexers
  - Forwards from EX/MEM stage (priority) or MEM/WB stage
- **Fixed Issues**: 
  - Corrected logic to check register x0 (never forward to/from x0)
  - Simplified conditional structure for better synthesis

### 3. **Hazard Detection Unit Integration**
- **Location**: In ID stage
- **Function**: Detects load-use hazards
- **Control Signals**:
  - `pc_write`: Stalls PC when hazard detected
  - `ifid_write`: Stalls IF/ID register
  - `control_mux_sel`: Inserts NOP in pipeline
- **Connected Modules**: Uses `rs1checar.v` and `rs2checar.v`

### 4. **Pipeline Registers**
- **IF/ID**: Passes instruction and PC
- **ID/EX**: Passes control signals, register data, immediate, register addresses
- **EX/MEM**: Passes ALU result, memory control, write data
- **MEM/WB**: Passes memory data, ALU result, write control

## Key Features Implemented

### ✅ **Data Forwarding**
- EX-to-EX forwarding (ALU result to ALU input)
- MEM-to-EX forwarding (Memory stage to ALU input)
- Proper priority handling (EX forwarding takes precedence over MEM)

### ✅ **Hazard Detection**
- Load-use hazard detection
- Pipeline stalling mechanism
- NOP insertion for control hazards

### ✅ **Pipeline Control**
- Enable/disable signals for each pipeline register
- Reset functionality for all stages
- Clock gating for hazard handling

## Files Modified/Created

### **Modified Files:**
1. **RiscVTop.v** - Completely rewritten as 5-stage pipelined processor
2. **fowarding.v** - Fixed logic errors and simplified structure
3. **TestRiscV.v** - Updated testbench for pipeline testing

### **Integrated Existing Files:**
- `PipeIFID.v`, `PipeIDEX.v`, `PipeEXMEM.v`, `PipeMEMWB.v`
- `Hazard_Unit.v`, `rs1checar.v`, `rs2checar.v`
- `Mux2x1.v`, `Mux3x1.v`
- All original processor components (ALU, Control Unit, Memory, etc.)

## Test Sequence

The testbench includes instructions that specifically test:

1. **No Hazard**: `addi x3, x1, 10`
2. **RAW Hazard + Forwarding**: `add x4, x3, x2` (uses x3 from previous instruction)
3. **Double Forwarding**: `sub x5, x4, x1` (uses x4 from previous instruction)
4. **Load Instruction**: `lw x6, 0(x0)`
5. **Load-Use Hazard**: `add x7, x6, x5` (requires pipeline stall)
6. **Store Instruction**: `sw x7, 4(x0)`

## How to Run

```bash
# Make script executable
chmod +x compile_and_run.sh

# Compile and run
./compile_and_run.sh

# Or manually:
iverilog -o riscv_pipeline TestRiscV.v
vvp riscv_pipeline
gtkwave riscv_tb.vcd  # View waveforms
```

## Expected Behavior

- **Pipeline fills over 5 cycles**
- **Forwarding messages** appear when RAW hazards are resolved
- **Stall messages** appear for load-use hazards
- **Correct final register values** as specified in testbench
- **No data corruption** due to hazards

## Architecture Diagram

```
[IF] -> [IF/ID] -> [ID] -> [ID/EX] -> [EX] -> [EX/MEM] -> [MEM] -> [MEM/WB] -> [WB]
                    |                   ^                    ^
                    v                   |                    |
              [Hazard Unit]        [Forwarding Unit]   [Forwarding Unit]
                    |                   |                    |
                    v                   v                    v
              [Stall Control]      [ALU Mux A]         [ALU Mux B]
```

The processor now successfully integrates all three major components (pipeline, forwarding, hazard detection) into a working 5-stage pipelined RISC-V processor.