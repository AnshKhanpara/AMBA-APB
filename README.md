# ⚡ AMBA APB Master–Slave Interface (APB4)

[![Language](https://img.shields.io/badge/Language-Verilog_HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Protocol](https://img.shields.io/badge/Protocol-AMBA_APB4-orange.svg)](https://developer.arm.com/documentation/ihi0024/latest/)
[![Status](https://img.shields.io/badge/Status-Verified-success.svg)](#)

## 📋 Overview
This project involves the design and implementation of a **32-bit AMBA Advanced Peripheral Bus (APB) Master-Slave Interface**. The design is fully compliant with the **APB4** protocol specifications, written in **Verilog HDL**, and features protocol-accurate Finite State Machine (FSM) control for robust peripheral communication.

The implementation focuses on low-power, low-bandwidth data transfers with advanced error handling and data integrity verification, making it ideal for connecting primary processors to general-purpose peripherals.

---

## ✨ APB4 Key Features Implemented
This design goes beyond the standard APB interface by integrating advanced **APB4** specific enhancements:

- 🛡️ **Protection Control (PPROT):** Implemented protection signals to support secure/non-secure and privileged/unprivileged transaction visibility.
- 🎯 **Byte-Level Strobes (PSTRB):** Integrated write strobes enabling partial or unaligned data transfers over the 32-bit bus.
- ⚠️ **Slave Error Signaling (PSLVERR):** Developed native error signaling from the slave back to the master indicating transfer failures.

---

## 🛠️ Design Architecture & Integrity
- **FSM Control Logic:** Protocol-accurate Finite State Machines govern the setup, access, and idle phases of the AMBA APB specification.
- **Data Integrity (Parity):** Integrated custom parity generation on the master side and parity checking on the slave side to ensure robust and corruption-free data transmission.
- **Address Validation:** Developed strict address decoding and range validation logic, preventing unauthorized or out-of-bounds memory accesses and appropriately triggering `PSLVERR`.

---

## 💻 Technologies & Protocols
- **Hardware Description Language:** Verilog HDL
- **Specification:** ARM AMBA APB (v4.0)
- **Methodology:** FSM Design, Synchronous Digital Logic, Protocol Verification

---

## 🎯 Learning Outcomes
This implementation demonstrates practical mastery in:
- Industry-standard bus protocols (AMBA).
- Finite State Machine (FSM) design for transaction control.
- Hardware-level data integrity (Parity) and error handling.
- Developing synthesizable IP blocks for System-on-Chip (SoC) integration.

---
*If you find this project interesting or helpful, feel free to ⭐ star the repository!*
