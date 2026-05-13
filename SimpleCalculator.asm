;*****************************************************************************
; Author: Roman Salazar
; Date: 05/9/2026
; Revision: 1.7
;
; Description:
; A multi-digit calculator for the LC-3. Supports +, -, *, and /.
; Uses a scaling method (x100) for division to provide decimal precision
; and a custom integer-to-ASCII routine for multi-digit display.
;
; Register Usage:
; R0: System I/O (TRAPs), math results, and character passing.
; R1: First Operand (extracted from PARSEINPUT).
; R2: Second Operand (extracted from PARSEINPUT) / General Counter.
; R3: Operator Character (e.g., '+', '-', '*', '/') / Temp Comparison.
; R4: Operation Dispatcher (Waterfall) / Quotient Counter / Digit Temp.
; R5: Divisor (Negative) for Division / Temp logic.
; R6: Temporary math results / Remainder storage.
; R7: Return Address for subroutines (JSR/RET linkage).
;
;****************************************************************************/

.ORIG x3000



MAIN
        JSR WELFUN

LOOPED
        JSR TAKEINPUT
        
        ; Check for 'q' to quit
        LEA R0, INPUTBUF
        LDR R0, R0, #0
        LD  R1, QUITCHAR
        NOT R1, R1
        ADD R1, R1, #1
        ADD R0, R0, R1  ; If user input q (decimal 113) + -113 = 0, then quit, otherwise, cont.
        BRz DONE

        JSR PARSEINPUT  ; Determine the operation
        JSR HANDLEOP    ; Handle the determined operation
        BRnzp LOOPED    ; Repeatedly ask for input unless user enters 'q'

DONE
        LEA R0, BYEMSG
        TRAP x22    ;PRINT Goodbye Message
        TRAP x25    ;HALT

;-------- Functions ------------
WELFUN  ST R7, SRWEL
        LEA R0, WELCOME
        TRAP x22
        LD R7, SRWEL
        RET
SRWEL   .BLKW 1

TAKEINPUT
        ST R7, SRIN
        LEA R0, PROMPT
        TRAP x22
        LEA R1, INPUTBUF
INL     TRAP x20    ; INL (input loop)
        TRAP x21      
        ADD R2, R0, #-10 ; Newline? If so, end the user input (detects enter key)
        BRz IND ; Move to IND if user presses enter
        STR R0, R1, #0
        ADD R1, R1, #1
        BRnzp INL
IND     AND R0, R0, #0 ; IND (input done)
        STR R0, R1, #0  
        LD R7, SRIN
        RET
SRIN    .BLKW 1 ; Save Register input

PARSEINPUT
        LEA R0, INPUTBUF    ; Intentionally simple parser (Assumes user only enters single digit values and operator is always second)
        LDR R1, R0, #0  
        LDR R3, R0, #1  
        LDR R2, R0, #2  
        LD R4, NEG48
        ADD R1, R1, R4  
        ADD R2, R2, R4  
        RET

HANDLEOP    ; Essentially directs traffic for the operation
        ST R7, SRDIS            ;Waterfall method (Use the individual subroutines to determine what kind of operation is occurring)
        LD R4, PLUS
        JSR COMP ; is R4 - plus = 0 if so, do the add operation
        BRz DOADD
        LD R4, MINUS
        JSR COMP
        BRz DOSUB
        LD R4, MUL
        JSR COMP
        BRz DOMUL
        LD R4, DIV
        JSR COMP
        BRz DODIV
        BRnzp DISR
COMP    NOT R4, R4  ; R3 should store operator char Is r3 - r4 = 0? If so, the correct operator is found.
        ADD R4, R4, #1
        ADD R4, R3, R4
        RET
DOADD   JSR ADDOP
        BRnzp DISR
DOSUB   JSR SUBOP
        BRnzp DISR
DOMUL   JSR MULOP
        BRnzp DISR
DODIV   JSR DIVOP
DISR    LD R7, SRDIS
        RET
SRDIS   .BLKW 1 ; Space for return address

; =====================================================
; OPERATIONS
; =====================================================
ADDOP   ST R7, SROP ; Save the return ticket
        ADD R0, R1, R2
        JSR PRINTINT
        LD R7, SROP ; Place ticket back in R7
        RET
SUBOP   ST R7, SROP
        NOT R2, R2
        ADD R2, R2, #1
        ADD R0, R1, R2
        JSR PRINTINT
        LD R7, SROP
        RET
MULOP   ST R7, SROP
        AND R0, R0, #0
        ADD R4, R2, #0
        BRz MULD
MULL    ADD R0, R0, R1
        ADD R4, R4, #-1
        BRp MULL
MULD    JSR PRINTINT
        LD R7, SROP
        RET
DIVOP   ST R7, SROP
        AND R0, R0, #0
        LD R4, HUNDRED
DIVM    ADD R0, R0, R1
        ADD R4, R4, #-1
        BRp DIVM
        AND R4, R4, #0
        NOT R5, R2
        ADD R5, R5, #1
        
DIVL2   ADD R6, R0, R5 ;Example 7 / 2 -> Take 7 * 100 = 700 -> 700 -2 - 2 - 2 and so on. Count the number of times
                             ; we subtract the divisor from the total n times 700 - 2(n) = 0 when n = 350 
        BRn DIVFIN
        ADD R0, R6, #0
        ADD R4, R4, #1
        BRnzp DIVL2
DIVFIN  ADD R0, R4, #0  ; Move final val from r4 to r0
        JSR PRINTDECIMAL
        LD R7, SROP
        RET
SROP    .BLKW 1


; --------------------------------------------------------
PRINTINT
        ST R7, SRPINT
        ST R0, ORIGR0    ; Save original value
        
        ; Reset Flag
        AND R0, R0, #0
        ST R0, PRINTEDFLAG

        LD R0, ORIGR0
        BRzp PSTART
        
        ; Handle Negative
        LD R0, MINUS_CHAR
        TRAP x21
        LD R0, ORIGR0
        NOT R0, R0
        ADD R0, R0, #1
        ST R0, ORIGR0    ; Work with positive version
                         ; Floating point is achieved by scaling the original value and then shifting over the necessary numer of slots
PSTART  ; 1. Hundreds
        LD R0, ORIGR0
        LD R1, NEG100     
        JSR EXTRACTDIGIT    ; Ex: 350 - 100 * n = negative or zero when? n = 4 so use n = 3 for the number of 100s
        ADD R1, R0, #0   ; R1 = Digit   Continually subtracts from the value say 350 until the result is    
        BRz SKIPH
        LD R2, ASCII0
        ADD R0, R1, R2
        TRAP x21
        AND R2, R2, #0
        ADD R2, R2, #1
        ST R2, PRINTEDFLAG
SKIPH                   ; skips unnecessary remaning 0s after extract
        ; 2. Tens
        LD R0, REMAINR0
        LD R1, NEG10
        JSR EXTRACTDIGIT
        ADD R1, R0, #0   ; R1 = Digit
        LD R2, PRINTEDFLAG
        ADD R2, R2, R1   ; If either is > 0, we print
        BRz SKIPT
        LD R2, ASCII0
        ADD R0, R1, R2
        TRAP x21
        AND R2, R2, #0
        ADD R2, R2, #1
        ST R2, PRINTEDFLAG
SKIPT                           ; Skips unnecessary remaning zeros after the extract operation
        ; 3. Ones (Always Print)
        LD R0, REMAINR0
        LD R2, ASCII0
        ADD R0, R0, R2
        TRAP x21

        LD R0, NEWLINE
        TRAP x21
        LD R7, SRPINT
        RET

EXTRACTDIGIT
        AND R2, R2, #0  ; Counter
EDL     ADD R3, R0, R1  ; Value + (-10 or -100) 
        BRn EDD
        ADD R0, R3, #0
        ADD R2, R2, #1
        BRnzp EDL
EDD     ST R0, REMAINR0 ; Remainder for next pass
        ADD R0, R2, #0  ; Return digit in R0
        RET

SRPINT      .BLKW 1
ORIGR0      .BLKW 1
REMAINR0    .BLKW 1
PRINTEDFLAG .BLKW 1

;- Print the decimal value
PRINTDECIMAL
        ST R7, SRPD
        ST R0, SAVEVAL
        
        LD R1, NEG100
        JSR EXTRACTDIGIT
        LD R2, ASCII0
        ADD R0, R0, R2
        TRAP x21
        
        LD R0, DOT
        TRAP x21
        
        LD R0, REMAINR0
        LD R1, NEG10
        JSR EXTRACTDIGIT
        LD R2, ASCII0
        ADD R0, R0, R2
        TRAP x21
        
        LD R0, REMAINR0
        LD R2, ASCII0
        ADD R0, R0, R2
        TRAP x21
        
        LD R0, NEWLINE
        TRAP x21
        LD R7, SRPD
        RET
SRPD     .BLKW 1
SAVEVAL  .BLKW 1


;-------------------------(DATA)-----------------------------
WELCOME   .STRINGZ "LC-3 Multi-Digit Calc (Rough version) \n"
PROMPT    .STRINGZ "> "
BYEMSG    .STRINGZ "\n Goodbye :) \n"
QUITCHAR  .FILL x0071
INPUTBUF  .BLKW 10

PLUS      .FILL x002B 
MINUS     .FILL x002D 
MUL       .FILL x002A 
DIV       .FILL x002F 
MINUS_CHAR .FILL x002D

ASCII0    .FILL x0030
NEG48     .FILL #-48
NEWLINE   .FILL x000A
DOT       .FILL x002E
HUNDRED   .FILL #100
NEG100    .FILL #-100
NEG10     .FILL #-10

.END
