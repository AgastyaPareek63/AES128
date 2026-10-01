# AES-128 RTL Encryption Engine

An RTL implementation of the AES-128 encryption algorithm designed for FPGA/SoC deployment on Xilinx Zynq platforms.

The project implements a modular, synthesizable AES-128 encryption engine with AXI4-Lite memory-mapped control, a 128-bit SEC-DED ECC FIFO for data buffering and integrity, and a shared BRAM architecture for secure communication with a separate decryption engine.

## Key Features

- AES-128 encryption
- 128-bit plaintext and key
- 10-round AES encryption
- Key Expansion for 11 round keys
- SubBytes
- ShiftRows
- MixColumns
- AddRoundKey
- FSM-based encryption control
- AXI4-Lite memory-mapped interface
- 128-bit SEC-DED FIFO integration
- Error detection and single-bit correction
- Shared BRAM architecture for encryption/decryption communication
- Modular and reusable RTL architecture
- Designed for Xilinx Vivado and Zynq-based FPGA systems

## Architecture

```text
                              AES-128 AXI FIFO
                        │
          ┌─────────────┴─────────────┐
          │                           │
          ▼                           ▼
     AXI4-Lite                    FIFO Control
     Registers
          │
          ▼
     Plaintext 128-bit
     Key 128-bit
     START
          │
          ▼
 ┌────────────────────────────┐
 │      128-bit FIFO          │
 │                            │
 │      SEC-DED ECC           │
 │                            │
 │ DATA_WIDTH  = 128         │
 │ PARITY_BITS = 8           │
 │ ECC_WIDTH   = 137         │
 │ DEPTH       = 16          │
 └──────────────┬─────────────┘
                │
                │ 128-bit plaintext
                ▼
       ┌────────────────────┐
       │   AES-128 Core     │
       │                    │
       │ Key Expansion      │
       │        ↓           │
       │ AddRoundKey        │
       │        ↓           │
       │ Round 1            │
       │        ↓           │
       │ Round 2            │
       │        ↓           │
       │    ...             │
       │        ↓           │
       │ Round 9            │
       │        ↓           │
       │ Final Round 10     │
       └─────────┬──────────┘
                 │
                 ▼
          128-bit ciphertext
