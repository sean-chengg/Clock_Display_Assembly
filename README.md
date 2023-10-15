# Clock_Display_Assembly
Digital Clock Simulation in Assembly For CSCI 2021 SPR 23 with Professor Kauffman at UMN 

Created a

- An internal clock that increments 16 times per second. The value reported by the clock is stored in a special hardware location that is presented as a global variable.
- A digital display with a control port; setting certain global variables will change the display to show information to a user of the clock.
- User code that you will need to write to update the display based on the value reported by the internal clock.
- A simulator program with Makefile to test your code


Contributions:
clock_update_asm.s
clock_update.c

Provided: clock.h clock_main.c clock_sim.c

Testing: test_clock_update.c test_clock.org testy
