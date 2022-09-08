# FPGA Neopixel Peripheral

## Project Overview
Project for Georgia Tech ECE 2031.

## Neopixel Modes
- Set 16-bit color: Sets a 16-bit color to an address using a single OUT to specify the address and a single OUT to specify the color
- Set 24-bit color: Three OUT statements from the user and interprets them as RGB vectors, then sends that information to whichever pixel address is specified
- Set All: Increments through all addresses and sets the color to each pixel that was specified in the OUT statement
- Auto-increment: Loops through multiple OUT statements to send color to the pixel data, and the address is incremented every time
- Gradient: Utilizes a single OUT statement and it sets all the pixels to a color changing gradient
- Fade: Sends a single color to the peripheral and sets all the LEDs to that color and decrease and increase the brightness over time
- Flow: Sets the color vector and constantly incrementing/decrementing its RGB values to make a smooth, dynamic color-shifting gradient which updates with each clock cycle
