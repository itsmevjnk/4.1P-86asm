                                                        ; bootload.asm - 4.1P Name Tester task written in x86 assembly.
                                                        ; (c) 2023 Thanh Vinh Nguyen (itsmevjnk).
                                                        ; Written for the SIT102 9.5H Something Awesome task.

                BITS    16                              ; This is the NASM directive that specifies that this will be
                                                        ; assembled for 16-bit x86.
                ORG     7C00h                           ; This specifies that our code will start from 0000:7C00h.
                                                        ; While there are conflicting information on where the bootloader
                                                        ; is executed (0000:7C00h versus 07C0:0000h), we will be mostly
                                                        ; using near JMP/CALLs with relative addresses, so it does not
                                                        ; really matter. What matters more is the data segment, which we
                                                        ; will set below.

START:                                                  ; Bootloader initialisation code.
                XOR     AX,     AX                      ; Set AX to 0. This instruction takes 2 bytes, and is therefore
                                                        ; more compact than MOV AX, 0.
                MOV     DS,     AX                      ; Set data segment to 0000h.
                MOV     ES,     AX                      ; Set extra segment to 0000h.
                MOV     SS,     AX                      ; Set stack segment to 0000h.
                MOV     SP,     7C00h                   ; Set stack top to the start of our code.

                                                        ; The initialisation process is now complete, and we can move on
                                                        ; to the main code.

MENU:                                                   ; Menu handler.
                MOV     SI,     .S_MENU                 ; Print the menu.
                CALL    PUTS
.INPUT:         CALL    GETC                            ; Get selection from keyboard.
                                                        ; Go to different features depending on user input.
                CMP     AL,     '1'                     ; Custom message generator?
                JE      CUST_MSG
                CMP     AL,     '2'                     ; Guess That Number game?
                JE      GUESS
                CMP     AL,     '0'                     ; Reboot?
                JE      REBOOT                
                JMP     .INPUT                          ; Invalid selection - go back to input and wait.
.S_MENU:                                                ; The string printed for the menu. We use abbreviations here to
                                                        ; save some space.
                DB      0Dh, 0Ah                        ; CR + NL characters.                                                      
                DB      "1:Cust. msg. gen."                                       
                DB      0Dh, 0Ah
                DB      "2:Guess num."
                DB      0Dh, 0Ah
                DB      "0:Reboot"
                DB      0Dh, 0Ah
                DB      "Sel.:", 0                      ; The string is null-terminated!   

                                                        ; --------------------------------------------------------------
                                                        ; FEATURES
                                                        ; --------------------------------------------------------------

CUST_MSG:                                               ; Custom message generator.
                CALL    PUTC_NL                         ; Print the valid selection and go to the next line.
                MOV     SI,     .S_PROMPT               ; Print the prompt string.
                CALL    PUTS
                MOV     DI,     BUFFER                  ; Read the user's input.
                XOR     DX,     DX
                CALL    GETS
                MOV     SI,     .S_GREET_1              ; Print greeting.
                CALL    PUTS
                MOV     SI,     BUFFER                  ; Print the user's original input.
                CALL    PUTS
                MOV     DI,     SI                      ; Convert the name to UPPERCASE. We do not have to reload since
                                                        ; the original value of SI is preserved.
                CALL    TOUPPER
                MOV     SI,     .S_GREET_2              ; Print the UPPERCASE name.
                CALL    PUTS
                MOV     SI,     BUFFER
                CALL    PUTS
                CALL    TOLOWER                         ; Convert the name to lowercase. Now we do not even have to load
                                                        ; DI as it was left untouched.
                MOV     SI,     .S_GREET_3              ; Print the lowercase name.
                CALL    PUTS
                MOV     SI,     BUFFER
                CALL    PUTS
                MOV     SI,     .S_GREET_4              ; Print ending dot and newline to end the greeting.
                CALL    PUTS
                JMP     MENU                            ; Return to the menu.
.S_PROMPT:      DB      "Name:", 0                      ; Prompt string.
.S_GREET_1:     DB      "Howdy, ", 0                    ; Greet string #1 (first to be printed).
.S_GREET_2:     DB      " (UPP:", 0                     ; Greet string #2 (after original name).
.S_GREET_3:     DB      ", low:", 0                     ; Greet string #3 (after uppercase name).
.S_GREET_4:     DB      ")!", 0Dh, 0Ah, 0               ; Greet string #4 (last to be printed - ending dot and newline).

GUESS:                                                  ; Guess That Number game.
                CALL    PUTC                            ; Print the valid selection. New line is handled by the prompt.
.GENERATE:      CALL    RANDOM                          ; Generate a random number and store it in DX.
.INPUT:         MOV     SI,     .S_PROMPT               ; Print the prompt string.
                CALL    PUTS
                MOV     DI,     BUFFER                  ; Read user input.
                PUSH    DX                              ; Preserve the random number...
                MOV     DL,     1
                CALL    GETS
                POP     DX                              ; ...and restore it after we're done.
                MOV     SI,     DI                      ; Convert our input into number in CX.
                CALL    STOI
                CMP     CX,     DX                      ; Compare the randomly generated number with the guessed number.
                JE      .CORRECT
                JA      .HIGH
                MOV     SI,     .S_LOW                  ; Guessed number is too low
                CALL    PUTS
                JMP     .INPUT
.HIGH:          MOV     SI,     .S_HIGH                 ; Guessed number is too high
                CALL    PUTS
                JMP     .INPUT
.CORRECT:       MOV     SI,     .S_CORRECT              ; Correct number guessed.
                CALL    PUTS
                JMP     MENU                            ; Return to menu.
.S_PROMPT:      DB      0Dh, 0Ah, "Num:", 0             ; Prompt string.
.S_CORRECT:     DB      "Yep!", 0Dh, 0Ah, 0             ; String to be printed when the correct number has been guessed.
.S_HIGH:        DB      "2 hi...", 0                    ; String to be printed when the guessed number is too high.
.S_LOW:         DB      "2 lo...", 0                    ; String to be printed when the guessed number is too low.

REBOOT:                                                 ; Reboot the system.
                CALL    PUTC_NL                         ; Print the valid selection and go to the next line.
                INT     19h                             ; Reboot the computer using INT 19h.
                JMP     $                               ; But if that ever falls through, then we can just hang here.

                                                        ; --------------------------------------------------------------
                                                        ; COMMON FUNCTIONS
                                                        ; --------------------------------------------------------------

GETC:                                                   ; Get a character from the keyboard (without echoing) and store
                                                        ; in AL (keyboard scancode in AH).
                XOR     AH,     AH                      ; INT 16h, AH = 00h - wait for keypress and read character.
                INT     16h                             ; This function returns values in the whole of AX, so we do not
                                                        ; need to push anything to the stack.
                RET                                     ; Return to caller.

PUTC:                                                   ; Print a character stored in AL.
                PUSHA                                   ; Push all registers to the stack to keep their contents safe.
                                                        ; In reality, only AX and BX need to be protected, but PUSHA is
                                                        ; only 1 byte long.
                MOV     AH,     0Eh                     ; INT 10h, AH = 0Eh - teletype output.
                XOR     BH,     BH                      ; Set output page to 0.
                INT     10h                             ; Make a call to interrupt 10h.
                POPA                                    ; Restore register contents.
                RET                                     ; Return to caller.

PUTC_NL:                                                ; Similar to PUTC, but also prints a newline character.
                CALL    PUTC                            ; First call PUTC.
PUTNL:                                                  ; Print a newline character alone. PUTC_NL will eventually flow
                                                        ; into this too.
                PUSH    SI                              ; Then we call PUTS on the newline characters string below.
                MOV     SI, .S_NL
                CALL    PUTS
                POP     SI
                RET
.S_NL:          DB      0Dh, 0Ah, 0                     ; Newline characters (CR + NL).         

GETS:                                                   ; Get a line from the keyboard and store it in the location
                                                        ; specified by ES:DI. Set DL = 1 to only allow number input.
                PUSHA                                   ; Save all registers.
                XOR     CX,     CX                      ; We'll use CX to keep track of the number of characters in the
                                                        ; string.
.NEXT_CHAR:     CALL    GETC                            ; Read the next character.
                CMP     AL,     0Dh                     ; Has the ENTER key been pressed?
                JE      .DONE                           ; If so, that's it! No more reading.
                CMP     AL,     08h                     ; Has the Backspace key been pressed?
                JE      .BSPACE                         ; If so, head over to its handler code.
                CMP     DL,     0                       ; Is input limited to only numbers?
                JE      .STORE                          ; Nope, we can proceed.
                CMP     AL,     '0'                     ; Check if the character is within range.
                JB      .NEXT_CHAR
                CMP     AL,     '9'
                JA      .NEXT_CHAR
.STORE:         STOSB                                   ; Store AL to ES:DI.
                CALL    PUTC                            ; Also print the character too.
                INC     CX                              ; And increment the character count.
                JMP     .NEXT_CHAR                      ; Then get back to reading the next character.
.BSPACE:        CMP     CX,     0                       ; Are there any characters in the output buffer?
                JE      .NEXT_CHAR                      ; No characters, so we will skip this.
                DEC     DI                              ; Otherwise, go back by 1 character.
                DEC     CX
                MOV     SI, .S_BSPACE                   ; Print the clearance string (below).
                CALL    PUTS
                JMP     .NEXT_CHAR                      ; Then get back to reading.
.S_BSPACE:      DB      08h, " ", 08h, 0                ; Backspace clearance string (backspace, space, then backspace
                                                        ; again)
.DONE:          XOR     AL,     AL                      ; Push the null termination to the output buffer.
                STOSB
                CALL    PUTNL                           ; Print newline.
                POPA                                    ; Restore all registers...
                RET                                     ; ...then return to caller.

PUTS:                                                   ; Print a string located in DS:SI.
                PUSHA                                   ; Push all registers to the stack to keep their contents safe.
                MOV     AH,     0Eh                     ; INT 10h, AH = 0Eh - teletype output.
                XOR     BH,     BH                      ; Set output page to 0.
.NEXT_CHAR:     LODSB                                   ; Load the byte from DS:SI to AL, then increment SI.
                CMP     AL,     0                       ; Check if the byte that we have just loaded is zero
                                                        ; (null-terminated string).
                JE      .DONE                           ; If it's zero, then we stop here.
                INT     10h                             ; Make a call to interrupt 10h...
                JMP     .NEXT_CHAR                      ; ...then continue with the next character.
.DONE:          POPA                                    ; When we finish, be sure to pop the registers out.
                RET                                     ; Then we can finally return to the code that calls us.

TOUPPER:                                                ; Convert a string stored in DS:SI to UPPERCASE and store it in
                                                        ; ES:DI.
                PUSHA                                   ; Save all registers.
.NEXT_CHAR:     LODSB                                   ; Load a byte from DS:SI to check.
                MOV     AH,     AL                      ; Make a copy of the character for testing.
                CMP     AH,     'a'                     ; Check if the character is within the lowercase lower bound.
                JB      .STORE                          ; Nope!
                SUB     AH,     'a'                     ; Normalise the character to zero-based. Now it has to be in the
                CMP     AH,     25                      ; [0;25] range.
                JA      .STORE                          ; If not, then it's not of interest.
                AND     AL,     11011111b               ; Turn off the uppercase bit (bit 5), which is possible because
                                                        ; of how the ASCII code is constructed.
.STORE:         STOSB                                   ; Store the (modified?) character to ES:DI.
                CMP     AL,     0                       ; Is the character a null termination?
                JNE .NEXT_CHAR                          ; If not, then we continue on.
                POPA                                    ; Restore all registers.
                RET                                     ; Return to caller.

TOLOWER:                                                ; Convert a string stored in DS:SI to lowercase and store it in
                                                        ; ES:DI.
                PUSHA                                   ; Save all registers.
.NEXT_CHAR:     LODSB                                   ; Load a byte from DS:SI to check.
                MOV     AH,     AL                      ; Make a copy of the character for testing.
                CMP     AH,     'A'                     ; Check if the character is within the uppercase lower bound.
                JB      .STORE                          ; Nope!
                SUB     AH,     'A'                     ; Normalise the character to zero-based. Now it has to be in the
                CMP     AH,     25                      ; [0;25] range.
                JA      .STORE                          ; If not, then it's not of interest.
                OR      AL,     00100000b               ; Turn on the uppercase bit (bit 5), which is possible because
                                                        ; of how the ASCII code is constructed.
.STORE:         STOSB                                   ; Store the (modified?) character to ES:DI.
                CMP     AL,     0                       ; Is the character a null termination?
                JNE .NEXT_CHAR                          ; If not, then we continue on.
                POPA                                    ; Restore all registers.
                RET                                     ; Return to caller.

RANDOM:                                                 ; Generate a random number between 1 and 100 and store it in DX.
                PUSH    AX                              ; Save AX and CX registers as they should not be touched.
                PUSH    CX
                XOR     AH,     AH                      ; INT 1Ah, AH = 00h - read system clock counter.
                INT     1Ah
                MOV     AX,     DX                      ; Multiply DX by CX and put it in DX:AX.
                MUL     CX
                ADD     DX,     AX                      ; Add AX into DX for more randomness.
                ADD     DL,     DH                      ; And also DH into DL. We'll be working on DL only.
                XOR     DH,     DH                      ; Because of this, we need to clear DH also.
.REDUCE:        SUB     DL,     100                     ; Subtract DL by 100 to hopefully get it down to the 0-99 range.
                CMP     DL,     100                     ; Have we reached our target yet?
                JAE     .REDUCE                         ; Nope.
                INC     DX                              ; Otherwise, bring the range to 1-100.
                POP     CX                              ; Since they're stored in a stack, we need to pop them out in the
                POP     AX                              ; reverse order.
                RET                                     ; Return to caller.

STOI:                                                   ; Convert number string in DS:SI to number and store it in CX.
                PUSH    AX                              ; Save registers.
                PUSH    DX
                XOR     AX,     AX                      ; Clear AX (so we can add AX straight into CX later).
                XOR     CX,     CX                      ; Also clear CX.
.NEXT:          LODSB                                   ; Load character from DS:SI.
                CMP     AL,     0                       ; Has we reached the end?
                JE      .DONE                           ; Yes!
                SUB     AL,     '0'                     ; Otherwise, normalise AL.
                PUSH    AX                              ; Put AX aside as we need to use it for MUL.
                XCHG    AX,     CX                      ; Swap AX-CX.
                MOV     DX,     10                      ; Multiply by 10.
                MUL     DX                              ; Result is in DX:AX, but we'll discard the DX part.
                POP     CX                              ; Pop to CX so we can add the multiplied value back there.
                ADD     CX,     AX                      ; Add the multiplied value.
                JMP     .NEXT                           ; Get the next character.
.DONE:          POP     DX                              ; Pop the saved registers.
                POP     AX
                RET

                TIMES   510-($-$$)      DB      0       ; Pad the bootloader so that it fits in one sector.
                                        DW      0AA55h  ; The bootloader signature, stored in the boot sector as 55AAh.
                                                        ; The byte order is inverted due to x86's endianness.

BUFFER:                                                 ; The memory space after the bootloader will be used as buffer
                                                        ; space for variables if needed.