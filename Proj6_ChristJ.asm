TITLE Project 6 - String Primitives And Macros - Proj6_ChristJ.asm
; Author:                Jacobi Christ
; Last Modified:         06/04/2024
; OSU email address:     ChristJ@oregonstate.edu
; Course number/section: CS271 Section 405
; Project Number:        6
; Due Date:              06/09/2024
; Description:           This program asks the user to input 10 strings. Next it
;                        parses those strings into ten signed integers. Finally
;                        it calculates and displays various information about the
;                        integers like total sum and average.
INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints a string to the console
;
; Preconditions: None
;
; Receives:
; CHAR* message[reg, label, imm]
;
; Returns: None
; ---------------------------------------------------------------------------------
mDisplayString MACRO message:REQ
   ; Backup registers
   PUSH EDX
   ; cout << message
   MOV  EDX, message
   CALL WriteString
   ; Restore registers
   POP  EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Reads a string from the user
;
; Preconditions: None
;
; Receives:
; DWORD bufferSize[reg, label, imm]
; CHAR* prompt[reg, label, imm]
;
; Returns:
; DWORD length[reg, label, imm]
; CHAR* buffer[reg, label, imm]
; ---------------------------------------------------------------------------------
mGetString MACRO buffer:REQ, bufferSize:REQ, length:REQ, prompt:REQ
   ; cout << prompt
   mDisplayString prompt
   ; Reserve one DWORD worth of space on the stack
   PUSH 00000000h
   ; Backup registers
   PUSH EAX
   PUSH ECX
   PUSH EDX
   ; This madness of push/pop allows this macro to work even when buffer = ECX
   ; and bufferSize = EDX which is the exact opposite of what Irvine expects.
   ; Using push/pop lets me swap them and makes the macro consistent.
   PUSH buffer
   PUSH bufferSize
   POP  ECX
   POP  EDX
   ; Read string into *EDX and store the length in EAX
   CALL ReadString
   ; Push EAX into that one DWORD worth of space we reserved earlier. The reason
   ; we dont just use normal push is because we need length to be underneath
   ; or register backups so we can pop length after restoring the registers.
   ; If we popped first then length would likely be overridden by the backed up
   ; registers.
   MOV  DWORD PTR [ESP + (3 * TYPE(DWORD))], EAX
   ; Restore registers
   POP  EDX
   POP  ECX
   POP  EAX
   ; Pop length into wherever it goes
   POP  length
ENDM

.const
   ; Constant Strings
   introMessage1    BYTE   "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,"Written by: Finlay Christ",13,10,13,10,"Please provide ",0
   introMessage2    BYTE   " signed decimal integers.",13,10,"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",13,10,13,10,0
   promptMessage    BYTE   "Please enter a signed number: ",0
   errorMessage     BYTE   "ERROR: You did not enter a signed number or your number was too big.",13,10,0
   datasetMessage   BYTE   "You entered the following numbers:",13,10,0
   sumMessage       BYTE   13,10,"The sum of these numbers is: ",0
   averageMessage   BYTE   13,10,"The truncated average is: ",0
   farewellMessage  BYTE   13,10,13,10,"Thanks for playing!",13,10,0
   spacerMessage    BYTE   ", ",0

.code
; ---------------------------------------------------------------------------------
; Name: main
; Description: Calls all other procedures to create the experience promised in
;              the program description.
; Preconditions: None
; Postconditions: None (process will exit)
; Receives: None
; Returns: None
; ---------------------------------------------------------------------------------
main PROC
   ; Init stack alignment check
   PUSH 12345678h

   ; placeValues{EDI} = SDWORD[] { 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000 }
   PUSH 1
   PUSH 10
   PUSH 100
   PUSH 1000
   PUSH 10000
   PUSH 100000
   PUSH 1000000
   PUSH 10000000
   PUSH 100000000
   PUSH 1000000000
   MOV  EDI, ESP

   ; placeValuesReversed{EDX} = SDWORD[] { 1000000000, 100000000, 10000000, 1000000, 100000, 10000, 1000, 100, 10, 1 }
   PUSH 1000000000
   PUSH 100000000
   PUSH 10000000
   PUSH 1000000
   PUSH 100000
   PUSH 10000
   PUSH 1000
   PUSH 100
   PUSH 10
   PUSH 1
   MOV  EDX, ESP

   ; dataset{ESI} = stackalloc(10 * sizeof(DWORD))
   SUB  ESP, 10 * TYPE(DWORD)
   MOV  ESI, ESP
   
   ; cout << introMessage1
   mDisplayString OFFSET introMessage1
   ; WriteVal(10, placeValues{EDI})
   PUSH EDI
   PUSH 10
   CALL WriteVal
   ; cout << introMessage2
   mDisplayString OFFSET introMessage2
   
   ; Backup dataset{ESI}
   PUSH ESI
   ; for (index{ECX} = 10; index{ECX} > 0; index{ECX}--) { ... }
   MOV  ECX, 10
_loopStart1:
   ; ReadVal(currentPtr{ESI}, promptMessage, errorMessage, placeValuesReversed{EDX})
   PUSH EDX
   PUSH OFFSET errorMessage
   PUSH OFFSET promptMessage
   PUSH ESI
   CALL ReadVal
   ; for...
   ADD  ESI, TYPE(DWORD)
   LOOP _loopStart1
   ; cout << endl
   CALL CrLf
   ; Restore dataset{ESI}
   POP  ESI
   
   ; cout < datasetMessage
   mDisplayString OFFSET datasetMessage
   ; Backup dataset{ESI}
   PUSH ESI
   ; for (index{ECX} = 10; index{ECX} > 0; index{ECX}--) { ... }
   MOV  ECX, 10
_loopStart2:
   ; WriteVal(*ESI, placeValues{EDI})
   PUSH EDI
   PUSH [ESI]
   CALL WriteVal
   ; if (ECX > 1) { cout << spacer }
   CMP  ECX, 1
   JBE  _skipSpacer
   mDisplayString OFFSET spacerMessage
_skipSpacer:
   ; for...
   ADD  ESI, TYPE(DWORD)
   LOOP _loopStart2
   ; cout << endl
   CALL CrLf
   ; Restore dataset{ESI}
   POP  ESI
   
   ; cout < sumMessage
   mDisplayString OFFSET sumMessage
   ; Backup dataset{ESI}
   PUSH ESI
   ; sum{EAX} = 0
   MOV  EAX, 0
   ; for (index{ECX} = 10; index{ECX} > 0; index{ECX}--) { ... }
   MOV  ECX, 10
_loopStart3:
   ; sum{EAX} += *ESI
   ADD  EAX, [ESI]
   ; for...
   ADD  ESI, TYPE(DWORD)
   LOOP _loopStart3
   ; WriteVal(sum{EAX}, placeValues{EDI})
   PUSH EDI
   PUSH EAX
   CALL WriteVal
   ; cout < endl
   CALL CrLf
   ; Restore dataset{ESI}
   POP  ESI
   
   ; cout < averageMessage
   mDisplayString OFFSET averageMessage
   ; divisor{EBX} = 10
   MOV  EBX, 10
   ; average{EAX} = sum{EAX} / 10
   CDQ
   IDIV EBX
   ; WriteVal(average{EAX}, placeValues{EDI})
   PUSH EDI
   PUSH EAX
   CALL WriteVal
   ; cout < endl
   CALL CrLf
   
   ; Free placeValuesReversed{EDX}
   ; stackfree(10 * sizeof(SDWORD))
   ADD  ESP, 10 * TYPE(DWORD)

   ; Free placeValues{EDI}
   ; stackfree(10 * sizeof(SDWORD))
   ADD  ESP, 10 * TYPE(DWORD)

   ; Free dataset{ESI}
   ; stackfree(10 * sizeof(DWORD))
   ADD  ESP, 10 * TYPE(DWORD)
   
   ; Verify stack alignment
   POP  EAX
   CMP  EAX, 12345678h
   JE   _stackValid
   INT  3
_stackValid:
   
   ; return 0
   Invoke ExitProcess,0
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
; Description: Reads an SDWORD from the user
; Preconditions: None
; Postconditions: None
; Receives: SDWORD* output (on stack)
;           CHAR* prompt (on stack)
;           CHAR* error (on stack)
;           SDWORD* placeValues (on stack)
; Returns: An SDWORD in the memory pointed to by output
; ---------------------------------------------------------------------------------
ReadVal PROC
   ; Align stack frame
   PUSH EBP
   MOV  EBP, ESP
   ; Backup registers
   PUSH EAX
   PUSH EBX
   PUSH ECX
   PUSH EDX
   PUSH ESI
   PUSH EDI
   ; buffer{ESI} = stackalloc(13 * sizeof(BYTE))
   SUB  ESP, 13 * TYPE(BYTE)
   MOV  ESI, ESP

_promptAgain:
   ; Backup buffer{ESI}
   PUSH ESI
   ; Prompt for 12 chars into buffer{ESI} and length into length{ECX}
   mGetString ESI, 12, ECX, [EBP + (3 * TYPE(DWORD))]
   
   ; if (length{ECX} != 0) { goto _bufferNotEmpty }
   CMP  ECX, 0
   JNE  _bufferNotEmpty
   ; Push a garbage value because error invalid assumes sign{EDI} will be on the stack
   PUSH 00000000h
   ; goto _errorInvalid
   JMP  _errorInvalid
_bufferNotEmpty:
   
   ; value{EAX} = *pointer{ESI}
   MOV  EAX, 0
   MOV  AL, [ESI]
   ; sign{EDX} = 0 // No Sign
   MOV  EDX, 0
   ; if (value{EAX} == '-') { goto _minusSign }
   CMP  AL, 2Dh
   JE   _minusSign
   ; if (value{EAX} == '+') { goto _hasSign } else { goto _exitSignCheck }
   CMP  AL, 2Bh
   JE   _hasSign
   JMP  _exitSignCheck
_minusSign:
   ; sign{EDX} = 1 // Minus
   MOV  EDX, 1
_hasSign:
   ; pointer{ESI} += sizeof(CHAR)
   ADD  ESI, TYPE(BYTE)
   ; length{ECX}--
   DEC  ECX
_exitSignCheck:
   ; Backup sign{EDX}
   PUSH EDX
   
   ; if (length{ECX} <= 0) { goto _errorInvalid }
   CMP  ECX, 0
   JBE  _errorInvalid
   ; if (length{ECX} > 10) { goto _errorInvalid }
   CMP  ECX, 10
   JA   _errorInvalid
   
   ; output{EDI} = 0
   MOV  EDI, 0
   ; for {index{ECX} = length{ECX}; index{ECX} > 0; index{ECX}--}
_loopStart:
   ; value{EAX} = *pointer{ESI}
   MOV  EAX, 0
   MOV  AL, [ESI]
   ; if (value{EAX} < '0') { goto _errorInvalid }
   CMP  EAX, 30h
   JB   _errorInvalid
   ; if (value{EAX} > '9') { goto _errorInvalid }
   CMP  EAX, 39h
   JA   _errorInvalid
   ; pointer{ESI} += sizeof(CHAR)
   ADD  ESI, TYPE(BYTE)
   ; value{EAX} -= '0'
   SUB  EAX, 30h
   ; placeValue{EBX} = placeValues[index{ECX} - 1]
   MOV  EBX, [EBP + (5 * TYPE(DWORD))]
   MOV  EBX, [EBX + (ECX * TYPE(DWORD)) - TYPE(DWORD)]
   ; value{EAX} *= placeValue{EBX}
   CDQ
   IMUL EBX
   ; if last operation overflowed goto _errorInvalid
   JO   _errorInvalid
   ; output{EDI} += value{EAX}
   ADD  EDI, EAX
   ; if last operation overflowed goto _errorInvalid
   JO   _errorInvalid
   ; for..
   LOOP _loopStart
   
   ; Restore sign{EDX}
   POP  EDX
   ; if (sign{EDX} != 1) { goto _skipNegative }
   CMP  EDX, 1
   JNE  _skipNegative
   ; output{EDI} = -output{EDI}
   NEG  EDI
_skipNegative:

   ; output = output{EDX}
   MOV  EAX, [EBP + (2 * TYPE(DWORD))]
   MOV  DWORD PTR [EAX], EDI
   ; Remove backup of buffer{ESI} from stack
   POP  ESI
   ; stackfree(13 * sizeof(BYTE))
   ADD  ESP, 13 * TYPE(BYTE)
   ; Restore registers
   POP  EDI
   POP  ESI
   POP  EDX
   POP  ECX
   POP  EBX
   POP  EAX
   ; Return and free stack frame
   POP  EBP
   RET  4 * TYPE(DWORD)
_errorInvalid:
   ; cout < errorMessage
   mDisplayString [EBP + (4 * TYPE(DWORD))]
   ; Remove backup of sign{EDX} from stack
   POP  EDX
   ; Restore buffer{ESI}
   POP  ESI
   ; goto promptAgain
   JMP  _promptAgain
ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
; Description: Writes a SDWORD to the console
; Preconditions: None
; Postconditions: None
; Receives: SDWORD value (on stack)
;           SDWORD* placeValues (on stack)
; Returns: None
; ---------------------------------------------------------------------------------
WriteVal PROC
   ; Align stack frame
   PUSH EBP
   MOV  EBP, ESP
   ; Backup registers
   PUSH EAX
   PUSH EBX
   PUSH ECX
   PUSH EDX
   PUSH ESI
   PUSH EDI
   ; value{EAX} = value
   MOV  EAX, [EBP + (2 * TYPE(DWORD))]
   ; buffer{ESI} = stackalloc(12 * sizeof(CHAR))
   SUB  ESP, 12 * TYPE(BYTE)
   MOV  ESI, ESP
   ; Backup buffer{ESI} for later
   PUSH ESI

   ; if(value{EAX} >= 0) { goto _skipMinus }
   CMP  EAX, 0
   JGE  _skipMinus
   ; value{EAX} = -value{EAX}
   NEG  EAX
   ; *currentChar{ESI} = '-'
   MOV  BYTE PTR [ESI], 2Dh
   ; ESI += sizeof(CHAR)
   ADD  ESI, TYPE(BYTE)
_skipMinus:
   ; printedCharYet{EDI} = 0
   MOV  EDI, 0

   ; for(index{ECX} = 0; index{ECX} < 10; index{ECX}++)
   MOV  ECX, 0
_loopStart:
   CMP  ECX, 10
   JAE  _loopBreak
   ; placeValue{EBX} = placeValues[ECX]
   MOV  EBX, [EBP + (3 * TYPE(DWORD))]
   MOV  EBX, [EBX + (ECX * TYPE(DWORD))]
   ; value{EAX} = value{EAX} / placeValue{EBX}
   CDQ
   IDIV EBX
   ; if (value{EAX} == 0) { goto _valueZero } else { ... }
   CMP  EAX, 0
   JE   _valueZero
   ; value{EAX} += '0'
   ADD  EAX, 30h
   ; *currentChar{ESI} = AL
   MOV  [ESI], AL
   ; currentChar{ESI} += sizeof(CHAR)
   ADD  ESI, TYPE(BYTE)
   ; printedCharYet{EDI} = 1
   MOV  EDI, 1
   JMP  _loopContinue
_valueZero:
   ; if (printedCharYet{EDI} == 0) { goto skipZero }
   CMP  EDI, 0
   JE   _loopContinue
   ; *currentChar{ESI} = '0'
   MOV  BYTE PTR [ESI], 30h
   ; currentChar{ESI} += sizeof(CHAR)
   ADD  ESI, TYPE(BYTE)
_loopContinue:
   ; value{EAX} = remainder{EDX}
   MOV  EAX, EDX
   ; for...
   INC  ECX
   JMP  _loopStart
_loopBreak:

   ; if (printedCharYet{EDI} != 0) { goto _skipSaftyZero }
   CMP  EDI, 0
   JNE  _skipSaftyZero
   ; *currentChar{ESI} = '0'
   MOV  BYTE PTR [ESI], 30h
   ; currentChar{ESI} += sizeof(CHAR)
   ADD  ESI, TYPE(BYTE)
_skipSaftyZero:
   ; *currentChar{ESI} = 'null'
   MOV  BYTE PTR [ESI], 00h

   ; Restore buffer{ESI}
   POP  ESI
   ; cout << ESI
   mDisplayString ESI
   ; stackfree(12 * sizeof(CHAR))
   ADD  ESP, 12 * TYPE(BYTE)
   ; Restore registers
   POP  EDI
   POP  ESI
   POP  EDX
   POP  ECX
   POP  EBX
   POP  EAX
   ; Return and free stack frame
   POP  EBP
   RET  2 * TYPE(DWORD)
WriteVal ENDP

END main