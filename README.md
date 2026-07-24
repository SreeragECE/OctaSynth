# 🎹 OctaSynth
### An FPGA-Based Digital Musical Keyboard

OctaSynth is a real-time digital musical keyboard implemented in **Verilog HDL** on the **Boolean FPGA Board**. The project interfaces with the **Digilent Pmod KYPD (4×4 Matrix Keypad)** to generate musical notes through **Direct Digital Synthesis (DDS)** using a **128-sample sine wave Look-Up Table (LUT)** and **PWM-based audio output**.

The design demonstrates FPGA-based digital signal processing, hardware interfacing, and modular RTL design by combining keypad scanning, debouncing, waveform generation, octave control, and audio synthesis into a single embedded hardware system.

---

## 📌 Project Highlights

- 🎹 4×4 Matrix Keypad Interface (Digilent Pmod KYPD)
- ⚡ Real-Time Musical Note Generation
- 🔄 Digital Debounce Logic
- 🎼 Direct Digital Synthesis (DDS)
- 🌊 128-Sample Sine Wave Look-Up Table
- 🔊 8-bit PWM Audio Output
- 🎵 Multi-Octave Support
- 💡 LED Indicators for Notes and Octaves
- ⚙️ Fully implemented in Verilog HDL

---

## 🛠 Hardware Requirements

- Boolean FPGA Board (Spartan-7)
- Digilent Pmod KYPD
- Speaker / Audio Jack
- Vivado Design Suite

---

## 🧠 System Architecture

The project follows the signal flow shown below.

```
          +-----------------------+
          | Digilent Pmod KYPD    |
          +-----------+-----------+
                      |
                      v
              Keypad Scanner
                      |
                      v
              Debounce Logic
                      |
                      v
          Note & Octave Decoder
                      |
                      v
          Frequency Divider (DDS)
                      |
                      v
          128-Sample Sine LUT
                      |
                      v
              PWM Audio Generator
                      |
                      v
              Speaker / Audio Out

             LED Status Indicators
```

---

## ⚙️ Working Principle

1. The FPGA continuously scans the rows of the 4×4 matrix keypad.
2. Pressed keys are detected through row-column scanning.
3. A digital debounce circuit filters mechanical switch bouncing.
4. The stable key is mapped to a musical note.
5. Dedicated keys increase or decrease the current octave.
6. A programmable divider generates the correct DDS stepping rate.
7. A 128-entry sine wave LUT produces waveform samples.
8. An 8-bit PWM generator converts the digital waveform into an analog-like audio signal.
9. LEDs indicate the currently selected note and active octave.

---

## 🎵 Musical Features

- Notes C, D, E, F, G, A, B and High C
- Octave Selection
  - Octave 4
  - Octave 5
  - Octave 6
- Dedicated Octave Up/Down Keys
- Stable Tone Generation
- Continuous Real-Time Playback

---

## 📂 Repository Structure

```
OctaSynth/
│
├── rtl/
│   └── Verilog HDL source files
│
├── constraints/
│   └── Boolean FPGA Board XDC files
│
├── simulation/
│   └── Testbenches and simulation waveforms
│
├── docs/
│   └── Project report and documentation
│
├── images/
│   └── Hardware setup and project images
│
├── demo/
│   └── Demo video link
│
└── README.md
```

---

## 📊 Key Design Specifications

| Parameter | Value |
|-----------|-------|
| Language | Verilog HDL |
| FPGA Board | Boolean FPGA Board (Spartan-7) |
| System Clock | 100 MHz |
| Keypad | Digilent Pmod KYPD |
| LUT Size | 128 Samples |
| Audio Output | PWM |
| Debounce Time | 20 ms |
| Keypad Scan Period | 1 ms |
| Octaves Supported | 4–6 |
| Waveform | Sine |

---

## 📸 Results

The project was successfully implemented on the Boolean FPGA Board.

✔ Correct keypad scanning

✔ Stable debounce operation

✔ Smooth sine-wave generation

✔ Reliable octave switching

✔ Real-time PWM audio output

✔ LED indication of active notes and octave

*(Hardware images and simulation waveforms are available in the `images/` directory.)*

---

## 🎥 Demo

A demonstration video showing the hardware implementation and real-time musical tone generation is available in the **demo** folder.

---

## 📖 Documentation

The complete project report, including:

- Theory
- Methodology
- RTL Design
- Verilog Source Code
- XDC Constraints
- Results
- Conclusion

is available in the **docs** folder.

---

## 🚀 Future Improvements

- Polyphonic note generation
- Multiple waveform support (Square, Triangle, Sawtooth)
- ADSR envelope generation
- MIDI interface
- OLED display integration
- Volume and tempo control
- External Audio DAC support

---

## 👨‍💻 Author

**Sreerag S Nair**

M.Tech – Micro & Nano Electronics

GitHub: **SreeragECE**

---

## 📜 License

This project is intended for educational and learning purposes. Feel free to explore, modify, and extend the design with appropriate attribution.

---

⭐ If you found this project helpful, consider giving it a star!
