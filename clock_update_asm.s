.text                           # IMPORTANT: subsequent stuff is executable
.global  set_tod_from_ports
        
## ENTRY POINT FOR REQUIRED FUNCTION
set_tod_from_ports:
        ## assembly instructions here
        ##rdi is a poitner to a tod_t struct
        ##ecx is represeting TIME OF DAY PORTS
        movl  TIME_OF_DAY_PORT(%rip), %ecx    # copy global var to reg ecx
        cmpl	$0, %ecx #if global variable less than 0
        jl     .error #jump to error
        cmpl	$1382400, %ecx #if global variable greater than 1382400, greater than 24 hours
        jg      .error #jump
        movl    %ecx, %r8d #move ecx to r8d
        addl    $8, %r8d #add 8 to setup for rounding
        sarl	$4, %r8d #shift edx by 4 to divide by 16
        movl    %r8d, 0(%rdi) #put day_secs into rdi for day_secs
        movl    %r8d, %eax #r8d is day_secs, will divide

        cqto              # prep for division
	movl    $60,%esi  #divides by 60
        idivl   %esi      #equivalent to tod->time_secs = secs % 60;
        movw    %dx,4(%rdi)    #dx is remainder of division, put into time_secs

        #dividing time mins
        movl    %r8d, %eax #r8d is day_secs
        cqto
        movl    $3600,%esi #divide by 3600,  (secs % 3600)
        idivl   %esi       #dx will be divided again by 60 for time_mins

        movl    %edx, %eax #move quotient to eax
        cqto
        movl    $60, %esi #divide by 60 again for total of tod->time_mins = (secs % 3600)/60
        idivl   %esi
        movw    %ax,6(%rdi) #ax is time_mins

        movb    $1,10(%rdi) #ampm is be default AM
        movl    %r8d, %eax #r8d is still day secs
        cqto
        movl    $3600, %esi #divide by 3600
        idivl   %esi
        movl    %eax, %r9d #r9d hours

        movw    %ax,8(%rdi) #time_hours is tod -> time_hours = secs / 3600
        cmpl	$43200, %r8d #if time given is in pm or above 12 hours
        jg      .above12 #set to pm

.aboveorunder:
        cmpl    $12,%r9d #conditional that checks if hours is 0 or 12
        je      .zero #jump
        cmpl    $0,%r9d #if hours is 0
        je      .twelve #jump
        movl    $0,%eax #if not, just return 0 and function was successful
        ret


.above12:
        movb    $2,10(%rdi) #make ampm to two
        subl    $12, %r9d #subtract 12 from time_hours if it's pm, to make day_hours
        movw    %r9w,8(%rdi) #day_hours
        jmp     .aboveorunder #jumps

.zero:
        movw    $12 ,8(%rdi) #set time_hours to 12
        movl    $0,%eax #return 0
        ret
.twelve:
        movw    $12 ,8(%rdi) #set time_hours to 12
        movl    $0,%eax #return 0
        ret

.error:
        movl $1, %eax #error
        ret #return 1

### Data area associated with the next function
.data                           # IMPORTANT: use .data directive for data section
	
my_int:                         # declare location an single int
        .int 1234               # value 1234

other_int:                      # declare another accessible via name 'other_int'
        .int 0b0101             # binary value as per C '0b' convention

my_array:                       # declare multiple ints in a row 
        .int 0b1110111                 # for an array. Each are spaced
        .int 0b0100100                 # 4 bytes from each other
        .int 0b1011101
        .int 0b1101101
        .int 0b0101110
        .int 0b1101011
        .int 0b1111011
        .int 0b0100101
        .int 0b1111111
        .int 0b1101111



        //0b1110111, 0b0100100, 0b1011101, 0b1101101, 0b0101110, 0b1101011, 0b1111011, 0b0100101, 0b1111111, 0b1101111, 0b0000000


.text                           # IMPORTANT: switch back to executable code after .data section
.global  set_display_from_tod

## ENTRY POINT FOR REQUIRED FUNCTION
set_display_from_tod:
        ## assembly instructions here

	## two useful techniques for this problem
        // movl    my_int(%rip),%eax    # load my_int into register eax
        // leaq    my_array(%rip),%rdx  # load pointer to beginning of my_array into rdx

        movq    %rsi, %r8   ## rsi = time_hours, goes into r8
        movq    %rsi, %r11  ## rsi = time_hours, goes into r11 to hold for a while so AMPM can be modifed            
        andl    $0xFFFF, %r8d  ##compare r8 to get time_hours
        cmpl	$12, %r8d ##compare 12 and time_hours
        jg      .exit ##failed, greater than 12
        cmpl	$0, %r8d ##compare 0 and time.hours
        jl      .exit ##failed, less than 0

        movq    %rdi, %r9 ##get time mins out
        sarq    $48, %r9 ##shift 48 bits to isolate
        andq    $0xFFFF, %r9 ##isolate the bits to get just time mins
        cmpl	$59, %r9d ##if time mins greater than 59
        jg      .exit ##jump to exit
        cmpl    $0, %r9d ##if time mins less than 0
        jl      .exit ##jump to exit
        pushq   %r13 #open up r13 and 14
        pushq   %r14
        movq    %rdx, %r13 #makes r13 = pointer, will put back in later
        movq    $0, %r14 #14

        leaq    my_array(%rip),%rcx  # load pointer to beginning of my_array into rdx, rdx is beginning of the array

        #min ones
        movl    %r9d, %eax #r9 is time_minutes
        cqto
        movl    $10, %esi #divide by 10
        idivl   %esi
        movl    %eax, %r10d ##r10d is tens digit of mins
        movl    %edx, %r9d ##r9d is ones digit of mins

        movl    (%rcx, %r9, 4), %r9d #get bit mas
        orl     %r9d, %r14d #or with num_list[min_ones], onto display

        movl    (%rcx, %r10, 4), %r10d #get bit mas
        sall    $7, %r10d #shift to put into display
        orl     %r10d, %r14d #or with num_list[min_tens], onto display

        pushq   %r12 ##push whole register, make sure to do pop %12
        movq    %r11, %r9 #saves RSI for ampm use later in 12s
        andl    $0xFFFF, %r11d #isolates r11, from here on should be hours

        movl    %r11d, %eax #r11 time_hours
        cqto
        movl    $10, %esi #divide by 10
        idivl   %esi
        movl    %edx, %r8d ##r8d is first digit of hours
        #hours divison completed

        movq    %r11, %r12 #r12 holds total hours
        movl    (%rcx, %r8, 4), %r11d #get bit mas, r8 is singles digit
        sall    $14, %r11d #sets display
        orl     %r11d, %r14d #or with num_list[hour_ones]

        cmpq	$10, %r12 ##compare 10 and time_hours
        jge     .dbl_digithr ##failed, greater than 10
        jmp     .AMPM #jump to AMPM
        
.dbl_digithr:
        movl    $0b0100100, %r10d #get bit mask for one
        sall    $21, %r10d #shift 21 to the left to get to the right place
        orl     %r10d, %r14d #or with num_list[min_tens]
        jmp     .AMPM

.AMPM:
        sarq    $16, %r9 ##shift by 16 bits, r9 is rsi holding over
        andl    $0xFF, %r9d ##bitmas
        cmpl    $1, %r9d ##if am is one
        je      .AM1 #go to am
        cmpl    $2, %r9d ##if pm is two
        je      .PM2 ##pm is two
        jmp     .exit

.AM1:
        movq    $1, %r9 ##am
        salq    $28, %r9
        orl     %r9d, %r14d #add am
        jmp     .final

.PM2:
        movq    $1, %r9 #pm
        salq    $29, %r9
        orl     %r9d, %r14d #add pm
        jmp     .final

.final:
        movl   %r14d, (%r13) ##move temp display back into display
        popq   %r12 ##remove r12 from memory
        popq   %r13 ##remove r13 from memory
        popq   %r14 ##remove r14 from memory
        movl    $0, %eax
        ret


.exit: ##exit out
        movl    $1, %eax
        ret
        
.text
.global clock_update
        
## ENTRY POINT FOR REQUIRED FUNCTION
clock_update:
        subq  $24, %rsp    ##grows stack by 8 bytes, and then in 16 bytes increments
        movq %rsp, %rdi  #stack pointer goes into rdi
        call set_tod_from_ports  # calls set_clock_from_ports, rdi is argument
        cmpl $0, %eax #set_tod_from_ports call compared to 0
        jne .NOT0 # jumps to finish if eax is NOT 0
        movq (%rsp),%rdi #retrieves rsp memory address
	movq 8(%rsp), %rsi #rsp memeory address is reterieved, put into rsi
        leaq CLOCK_DISPLAY_PORT(%rip),%rdx 
        call set_display_from_tod # set_display_tod function called, edi rsi arguments
        cmpl $0, %eax	# compares return
        jne .NOT0 #is return isnt zero
        jmp .FINISH # jump to FINISH

.NOT0:
        addq    $24, %rsp
        movl    $1, %eax # return 1 if there is some error
        ret

.FINISH:
        addq    $24, %rsp
        movl    $0, %eax
        ret 	# return




