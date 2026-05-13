LC-3 Single-Digit Calculator 
This program is a functional assembly-level calculator for the LC-3 (Little Computer 3) architecture. It supports basic arithmetic operations including addition, subtraction, multiplication, and division, featuring a custom 
integer-to-string output routine that handles multi-digit results and negative numbers.

## Installation
https://github.com/chiragsakhuja/lc3tools/releases/download/v2.0.2/LC3Tools-2.0.2.dmg
 -Version 2.0.2 LC3TOOLS
 
## Core Features
Arithmetic Operations: Supports +, -, *, and /.Multi-Digit Output: Includes a sophisticated PRINTINT subroutine that extracts hundreds, tens, and ones places for display. Negative Number Support: Correctly identifies and displays negative results by printing a '-' sign and performing a 2's complement conversion. Fixed-Point Division: Implements a unique division method that scales the quotient by 100 to provide two decimal places of precision. Interactive Shell: Operates in a loop, prompting the user for input until the q (quit) command is received.

## Implementation Details 
1. Input & Parsing The program uses a buffer-based input method. The PARSEINPUT routine assumes a fixed format for simplicity:Index 0: First operand (single digit)Index 1: Operator (+, -, *, /)Index 2: Second operand (single digit)2. The "Waterfall" Handler The HANDLEOP routine uses a "waterfall" comparison method. It systematically compares the operator character against known constants (ASCII values for +, -, etc.) and branches to the corresponding execution block. 3. Division Logic Rather than standard integer division, this implementation: Scales the dividend by 100. Repeatedly subtracts the divisor to find the quotient. Uses PRINTDECIMAL to insert a. before the last two digits, effectively simulating fixed-point arithmetic. The main issue is that it only works for division.

## Subroutine Map
Subroutine Description 
TAKEINPUT
Captures user string and stores it in INPUTBUF until a Newline is hit. 
HANDLEOP
Directs the program flow based on the operator detected.PRINTINTConverts a 16-bit signed integer into ASCII characters for the console.
EXTRACTDIGITA 
helper that uses repeated subtraction to find how many times a power of 10 fits into a value.ADDOP / 
SUBOP
Performs 16-bit addition and subtraction.
MULOP
Performs multiplication via repeated addition.

## Usage Instructions Assemble: 
Use an LC-3 assembler (like LC3TOOLS) to create the file. Run: Load into an LC-3 simulator.Input Format: Enter expressions without spaces, e.g., 5+2 or 9*3.Exit: Type q at the prompt to terminate the program.

## Technical Constraints Operand Limit: 
Currently designed for single-digit operands (0-9). Overflow: Standard LC-3 16-bit limitations apply (Range: -32,768 to 32,767). Memory Map: The program starts at address x3000.
