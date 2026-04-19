# Croc SoC — VLSI Design Study & Implementation

**BITS Pilani | M.Tech VLSI Design | Advance VLSI Design**  
**Submitted by:** Arpan Jain (`2025HT08066`)  
**Mentor:** Abhinav Shahu | Member of Consulting Staff, Siemens EDA  
**Date:** April 2026

---

## Overview

This repository documents the complete study and implementation of the **Croc System-on-Chip** developed by the [PULP Platform](https://pulp-platform.org) at ETH Zurich. Croc is an open-source, education-focused SoC designed to demonstrate the full ASIC design flow using freely available tools.

---

## SoC Architecture

| Component | Details |
|-----------|---------|
| **CPU Core** | CVE2 (minimal RISC-V RV32IMC fork of Ibex) |
| **Bus Interconnect** | OBI (Open Bus Interface) Crossbar |
| **Memory** | 2x SRAM banks × 512 words × 32-bit = 4KB total |
| **Debug** | JTAG Debug Module (0x0000_0000) |
| **Boot ROM** | 0x0200_0000 |
| **UART** | 0x0300_2000 |
| **GPIO** | 0x0300_5000 |
| **Timer** | 0x0300_A000 |
| **Technology** | IHP 130nm Open-Source PDK |
| **Boot Mode** | JTAG only |

---

## Repository Structure

```
croc-soc-vlsi/
├── croc/               # Croc SoC source (PULP Platform) — RTL, scripts, PDK
│   ├── rtl/            # SystemVerilog RTL files
│   ├── sw/             # Software (hello world, boot ROM)
│   ├── verilator/      # Verilator simulation scripts
│   ├── vsim/           # Questa/Modelsim simulation scripts
│   ├── yosys/          # Synthesis scripts (Yosys + IHP 130nm)
│   ├── openroad/       # Place & Route scripts (OpenROAD)
│   └── klayout/        # Layout finishing (KLayout → GDS)
├── testbench/          # Custom RD/WR testbenches (this assignment)
├── results/
│   ├── simulation/     # Simulation waveforms & logs
│   ├── synthesis/      # Synthesis reports (area, timing, power)
│   └── layout/         # Floorplan & layout screenshots
└── report/             # BITS Pilani assignment report (PDF)
```

---

## Tools Used

| Tool | Purpose | License |
|------|---------|---------|
| **Git** | Version control | Free |
| **Bender** | RTL dependency manager | Apache 2.0 |
| **Verilator** | SystemVerilog simulation | LGPL |
| **Yosys + yosys-slang** | Logic synthesis | ISC / MIT |
| **OpenROAD** | Place & Route | BSD |
| **KLayout** | GDS layout viewer | GPL |
| **IHP Open PDK** | 130nm process design kit | Apache 2.0 |
| **Docker (IIC-OSIC-TOOLS)** | Pre-built tool container | MIT |

---

## How to Run

### 1. Clone with submodules
```bash
git clone --recurse-submodules https://github.com/pulp-platform/croc.git croc
```

### 2. Start Docker tool environment (Windows)
```powershell
cd croc
scripts/start_vnc.bat
# Open browser → localhost → password: abc123
```

### 3. Compile & Simulate
```bash
cd sw && make all
cd ../verilator && ./run_verilator.sh --build --run ../sw/bin/helloworld.hex
```

### 4. Synthesis
```bash
cd yosys && ./run_synthesis.sh --synth
```

### 5. Place & Route + Layout
```bash
cd ../openroad && ./run_backend.sh --all
cd ../klayout && ./run_finishing.sh --gds
```

---

## Assignment Tasks Completed

- [x] Git version control setup & workflow
- [x] Croc SoC architecture study
- [x] RTL compilation (SystemVerilog via Verilator)
- [x] Custom RD/WR testbench development
- [x] Synthesis with Yosys (IHP 130nm)
- [x] Floorplan & Place-and-Route (OpenROAD)
- [x] Layout generation (KLayout)
- [x] Final report (see `report/`)

---

## References

- [Croc GitHub Repository](https://github.com/pulp-platform/croc)
- [PULP Platform](https://pulp-platform.org)
- [Croc SoC Documentation — ETH Zurich](https://vlsi.ethz.ch/wiki/Croc)
- [IHP Open PDK](https://github.com/IHP-GmbH/IHP-Open-PDK)
- [IIC-OSIC-TOOLS (Docker)](https://github.com/iic-jku/IIC-OSIC-TOOLS)
- [OBI Specification](https://github.com/openhwgroup/obi)
