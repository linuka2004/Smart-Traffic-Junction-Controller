# Smart Traffic Junction Controller

A four-way traffic junction prototype programmed entirely in AVR
Assembly on an Arduino Uno (ATmega328P). The system combines timed
traffic signal sequencing, pedestrian crossing requests, and
automatic night operation based on ambient light.

## Features

- Timer-driven traffic signal sequencing
- Green, yellow, and all-red clearance phases
- Interrupt-based pedestrian push-button handling
- Deferred pedestrian requests until the current vehicle phase completes
- Five-second pedestrian crossing countdown with all vehicle signals red
- LDR-based ambient light sensing through the ADC
- Night mode with synchronized yellow signals flashing at 1 Hz
- Five-second light-level confirmation before returning to normal mode
- Register-level control of GPIO, timers, interrupts, and ADC

## Operating Modes

### Normal Mode

Cycles through the North–South and East–West traffic phases,
including yellow transitions and all-red clearance intervals.

### Pedestrian Crossing

Records a push-button request and completes the current vehicle
phase and clearance interval before activating the crossing.

All vehicle signals remain red during the five-second pedestrian
countdown. Normal traffic sequencing resumes afterward.

### Night Mode

Uses an LDR to detect low ambient light and activates flashing
yellow signals across all four approaches.

Normal operation resumes after the light level remains above
the configured threshold for five consecutive seconds.

## Technologies

- AVR Assembly
- Arduino Uno
- ATmega328P
- Hardware Timers
- External Interrupts
- Analog-to-Digital Conversion
- GPIO
- LDR Sensor
- State Machine Design

## Project Files

- `firmware/` — AVR Assembly source files
- `images/` — Prototype photographs
- `docs/` — Project report, cover page, schematics, and design notes

## Author

**Linuka Jayasinghe**  
Computer Systems Engineering Undergraduate  
Sri Lanka Institute of Information Technology (SLIIT)
