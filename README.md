# TinyML-on-FPGA-Handwritten-Digit-Recognition-with-an-INT8-Neural-Network-Verilog-

# TinyML on FPGA: Handwritten Digit Recognition with an INT8 Neural Network (Verilog)

A neural network that recognises handwritten digits (0 to 9), running **entirely in hardware** on an FPGA. There is no CPU, no software and no IP core. It is written in plain Verilog and uses a single multiply-accumulate (MAC) unit.

You load a 28×28 image of a digit, flip a switch, and the FPGA shows the predicted digit on 4 LEDs in binary.

```
28x28 image ──► [ 784 → 64 → 32 → 16 → 10 neural network, INT8, one MAC unit ] ──► digit on LEDs
```

| Model | Test accuracy (MNIST, 10,000 images) |
|-------|-------------------------------------:|
| Floating-point (PyTorch) | ~96% |
| INT8, naive conversion of the float weights | ~80% |
| **INT8, Quantization-Aware Training (this project)** | **~95%** |

> The main lesson: **simply rounding a trained network to INT8 cost about 16 points of accuracy. Training the network with the hardware's rounding built in cost only about 1.**

---

## Background (for readers new to this)

**MNIST** is a standard dataset of 70,000 handwritten digits, each a 28×28 grayscale image (784 pixels).

**A neural network** here is four layers of "neurons". Each neuron takes every input from the previous layer, multiplies each input by a learned number (a *weight*), adds them all up, adds a *bias*, and applies a simple rule called **ReLU** (negative result becomes 0). The 10 neurons of the last layer each score one digit, and the highest score wins.

**A MAC (multiply-accumulate)** is the one operation that does almost all the work: `acc = acc + weight × input`. This design has exactly one MAC unit and reuses it for every multiplication in the network (about 53,000 of them).

**Quantization** means storing numbers with fewer bits. Training normally uses 32-bit floating point. FPGAs are far more efficient with small integers, so this design uses **INT8** (8-bit signed integers from -128 to 127). The price is rounding error, which is why accuracy can drop.

---

## How the number format works

Every value (weight, bias, activation) is an INT8 number that represents a fraction in **Q1.7** format: `real value = integer / 128`.

Each layer does this in hardware:

```
acc    = Σ (weight_int8 × input_int8)      32-bit accumulator, no overflow
acc    = acc + bias_int8
acc    = acc + 64                          rounding offset
acc    = acc >>> 7                         arithmetic shift = divide by 128
output = clamp(acc, 0, 127)                saturate to INT8, then ReLU
```

The camera-free input step is `pixel (0 to 1) → floor(pixel × 128) → INT8`.

The `+64` before the `>>> 7` makes the divide-by-128 round to the nearest integer instead of always rounding down.

---

## Repository Structure

| File | Description |
|------|-------------|
| `single_mac.v` | The whole neural network: control FSM, one MAC unit, weight/bias/image memories, argmax |
| `constraints.xdc` | Pin constraints (Arty S7, 12 MHz clock) |
| `train_qat.py` | Google Colab notebook/script: float training, QAT, exact integer check, confusion matrix, export |
| `matlab_export.m` | Converts int8 weights, biases and the test image into binary text files |
| `weights.txt` | All weights, one 8-bit binary value per line (52,896 lines) |
| `baises.txt` | All biases, one 8-bit binary value per line (122 lines). The spelling matches the Verilog path |
| `picture.txt` | The 784-pixel input image, one 8-bit binary value per line |

---

## Network Size

| Layer | Inputs → Outputs | Weights | Biases | ReLU |
|-------|------------------|--------:|-------:|:----:|
| 1 | 784 → 64 | 50,176 | 64 | yes |
| 2 | 64 → 32 | 2,048 | 32 | yes |
| 3 | 32 → 16 | 512 | 16 | yes |
| 4 | 16 → 10 | 160 | 10 | no (see notes) |
| **Total** | | **52,896** | **122** | |

Weights are stored layer after layer. Within a layer, all weights of neuron 0 come first, then neuron 1, and so on. That is the order the MAC unit reads them in.

---

## How the Hardware Works

### One MAC unit, reused for everything

Instead of building thousands of multipliers, a control **FSM (finite state machine)** walks through the network one neuron at a time:

```
For every neuron in the layer:
    read weight + input  →  multiply  →  add to accumulator      (repeat for every input)
    add bias → round (+64) → shift (>>> 7) → saturate / ReLU
    push the result into an output shift register
After the layer:
    copy the shift register back into the image memory (it becomes the next layer's input)
```

This is slow but tiny. It runs the whole network in roughly 55,000 clock cycles, which is only a few milliseconds at 12 MHz.

### Main blocks

| Block | What it does |
|-------|--------------|
| `weights[]`, `biases[]`, `pic[]` | Three memories loaded from the text files with `$readmemb` |
| FSM (states `s6` to `s27`) | Controls reads, MAC timing, bias add and layer switching |
| MAC (`accu`) | Signed 8×8 multiply into a 32-bit accumulator |
| Post-processing | `+bias`, `+64`, `>>>7`, clamp to 0 to 127 (this gives ReLU too) |
| `out[0:63]` shift register | Collects each neuron's result |
| `pic[]` write-back | Reuses the image memory to hold each layer's output as the next layer's input |
| Argmax | Finds the largest of the 10 final outputs and sends its digit number to `mm[3:0]` |

### FSM flow

```
IDLE(s6) ─start─► Layer 1 (s7–s9) ─► copy back (s10)
                  Layer 2 (s11–s13) ─► copy back (s15–s16)
                  Layer 3 (s18–s20) ─► copy back (s21–s22)
                  Layer 4 (s24–s26) ─► DONE (s27) ─start low─► IDLE
```

Each layer reuses the same three-step pattern: **compute** (stream weights and inputs through the MAC), **bias** (finish the arithmetic, a few cycles of pipeline delay), **next neuron**.

---

## Hardware Used

- Digilent **Arty S7** (Spartan-7), 12 MHz clock on pin F14
- Vivado for synthesis and programming

### Pin Mapping

| Signal | Pin | Direction | Description |
|--------|-----|-----------|-------------|
| `clk` | F14 | in | 12 MHz clock |
| `reset` | H14 | in | Active-high reset |
| `start` | H18 | in | Raise to start inference |
| `mm[3]` | H15 | out | Predicted digit, bit 3 (MSB) |
| `mm[2]` | E13 | out | Predicted digit, bit 2 |
| `mm[1]` | F13 | out | Predicted digit, bit 1 |
| `mm[0]` | E18 | out | Predicted digit, bit 0 (LSB) |

The LEDs show the digit in binary: `0111` = 7, `1001` = 9.

---

## Training Flow: How We Got From 80% to 95%

### Attempt 1: Train in float, convert to INT8 (80% accuracy)

1. Train the 784-64-32-16-10 network in Google Colab with normal floating-point weights. This gives **~96%**.
2. Convert weights and biases to INT8 in MATLAB: `round(value × 128)`.
3. Build a bit-exact **MATLAB reference** of the INT8 hardware arithmetic and check it against test images.
4. Write the Verilog to match the MATLAB reference exactly, and verify it against it.
5. Run it on the FPGA: **correct outputs**.

At this point everything looked like a success, but it had only been checked on a few images. When the full 10,000-image test set and a confusion matrix were run, the INT8 accuracy turned out to be only **~80%**. The hardware matched the MATLAB model perfectly, but the *method of converting* was costing 16 points of accuracy. A design that is mathematically correct is not necessarily a design that is *accurate*.

### Why it happens

A network trained in float never "knew" its weights would later be rounded to steps of 1/128. Each layer's small rounding errors add up through four layers.

### Attempt 2: Quantization-Aware Training (95% accuracy)

**QAT** trains the network while it is *already* experiencing the INT8 rounding, so it learns weights that survive it.

1. Pre-train in float for a few epochs (this makes QAT much more stable).
2. Put the **exact hardware arithmetic** into the PyTorch forward pass: quantized weights and biases, `floor(pixel × 128)` input, INT32 MAC, `+64`, `>>> 7`, saturation, ReLU.
3. Keep float "master" weights and use the **Straight-Through Estimator (STE)**. The forward pass uses rounded values, and the backward pass pretends rounding is the identity so gradients can still flow.
4. Clamp the master weights to the Q1.7 range after each step so they can't drift outside what the hardware can represent.
5. Fine-tune with a small learning rate, and keep the best epoch.
6. Re-run the test set with **real integer NumPy arithmetic** (not the simulated float forward pass) to confirm the exported INT8 files really give the accuracy.
7. Export the INT8 weights and biases as binary text files.

**The hardware and the MATLAB reference were not changed at all.** The QAT forward pass was written to copy that exact arithmetic, so only the weight *values* changed. Same Verilog, same bitstream, much better accuracy.

> QAT is the right choice whenever a network must run on one specific low-precision hardware implementation. The training can then compensate for the exact errors that hardware introduces.

---

## How to Reproduce

### 1. Train and export weights (Colab)
Run `train_qat.py` in Google Colab. It prints the accuracy comparison, saves `MNIST_QAT_Confusion_Matrix.png`, and downloads eight files:

```
weights_784_to_64   weights_64_to_32   weights_32_to_16   weights_16_to_10
biases_784_to_64    biases_64_to_32    biases_32_to_16    biases_16_to_10
```

### 2. Build the memory files
Combine the four weight files **in layer order** into `weights.txt`, and the four bias files into `baises.txt`. You can do this with `cat` (copy /b on Windows) or with the MATLAB script (`matlab_export.m`), which flattens each matrix neuron by neuron and writes 8-bit two's-complement binary with `dec2bin(x, 8)`.

Create `picture.txt` the same way from a 784-value INT8 image (`floor(pixel × 128)`, flattened row by row). Note that `dec2bin` handles negative numbers as two's complement only in newer MATLAB (R2020a or later).

### 3. Point Verilog at your files
In `single_mac.v`, edit the three `$readmemb` paths:

```verilog
$readmemb("D:/fpga/prj/tinyML/weights.txt", weights);
$readmemb("D:/fpga/prj/tinyML/baises.txt",  biases);
$readmemb("D:/fpga/prj/tinyML/picture.txt", pic);
```

### 4. Build and run
1. Create a Vivado project for the Arty S7. Add `single_mac.v` and `constraints.xdc`.
2. Generate the bitstream and program the board.
3. Pulse **reset**.
4. Raise **start**. After a few milliseconds the LEDs show the predicted digit in binary.
5. Lower **start** to return to idle.

---

## Known Limitations

- The memory contents are fixed when the bitstream is built (`$readmemb`). To test another image, change `picture.txt` and re-synthesize.
- The image memory is reused to store hidden-layer results, so the original image is overwritten during a run. Re-program the board to run the same image again.
- It is a single MAC unit, so it favours small area over speed. Adding more MAC units would make it much faster.
- 12 MHz is a slow clock. The design could run much faster with a PLL/MMCM.

## Possible Improvements

- Load images at run time over UART instead of baking them into the bitstream
- Use several MAC units in parallel
- Show the digit on a 7-segment display or on VGA
- Try a small convolutional network

## Requirements

- Python 3 with PyTorch, torchvision, scikit-learn, seaborn (Google Colab works out of the box)
- MATLAB R2020a or later
- Xilinx Vivado

## License

MIT
