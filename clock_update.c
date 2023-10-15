#include "clock.h"
#include <stdio.h>

// Reads the time of day from the TIME_OF_DAY_PORT global variable. If
// the port's value is invalid (negative or larger than 16 times the
// number of seconds in a day) does nothing to tod and returns 1 to
// indicate an error. Otherwise, this function uses the port value to
// calculate the number of seconds from start of day (port value is
// 16*number of seconds from midnight). Rounds seconds up if there at
// least 8/16 have passed. Uses shifts and masks for this calculation
// to be efficient. Then uses division on the seconds since the
// begining of the day to calculate the time of day broken into hours,
// minutes, seconds, and sets the AM/PM designation with 1 for AM and
// 2 for PM. By the end, all fields of the `tod` struct are filled in
// and 0 is returned for success.
 // 
// CONSTRAINT: Uses only integer operations. No floating point
// operations are used as the target machine does not have a FPU.
// 
// CONSTRAINT: Limit the complexity of code as much as possible. Do
// not use deeply nested conditional structures. Seek to make the code
// as short, and simple as possible. Code longer than 40 lines may be
// penalized for complexity.
int set_tod_from_ports(tod_t *tod){
    if (TIME_OF_DAY_PORT < 0 || TIME_OF_DAY_PORT > 16* 86400){
        return 1;
    }
    int secs = (TIME_OF_DAY_PORT +8) >> 4; //seconds into the day, +8 which will round it
    tod-> day_secs = secs;
    int hours = secs / 3600;
    tod -> time_hours = hours;
    tod->time_mins = (secs % 3600)/60;
    tod->time_secs = secs % 60;
    tod->ampm = 1; //sets ampm to default am
    if (secs > 43200){//if it is pm
        tod->ampm = 2;//set to pm
        tod -> time_hours = hours-12;
    }
    if (hours == 0|| hours == 12){ //if hours are 0 or 12, set display time to 12
        tod -> time_hours = 12;
    }
//    int mins = (secs - hours*3600)/60; 


    return 0;
}

// Accepts a tod and alters the bits in the int pointed at by display
// to reflect how the LCD clock should appear. If any time_** fields
// of tod are negative or too large (e.g. bigger than 12 for hours,
// bigger than 59 for min/sec) or if the AM/PM is not 1 or 2, no
// change is made to display and 1 is returned to indicate an
// error. The display pattern is constructed via shifting bit patterns
// representing digits and using logical operations to combine them.
// May make use of an array of bit masks corresponding to the pattern
// for each digit of the clock to make the task easier.  Returns 0 to
// indicate success. This function DOES NOT modify any global
// variables
// 
// CONSTRAINT: Limit the complexity of code as much as possible. Do
// not use deeply nested conditional structures. Seek to make the code
// as short, and simple as possible. Code longer than 85 lines may be
// penalized for complexity.
// int set_display_from_tod(tod_t tod, int *display){
//     int temp_display = 0; //makes a temporary location to hold the display
//     if (tod.time_hours > 12 || tod.time_hours < 0 || tod.time_mins > 59 || tod.time_mins < 0){ //checks to see if any of the time fields are out of bounds
//         return 1;
//     }
//     int num_list[] = {0b1110111, 0b0100100, 0b1011101, 0b1101101, 0b0101110, 0b1101011, 0b1111011, 0b0100101, 0b1111111, 0b1101111, 0b0000000}; //a list of what needs to be on to represent each number
//     int min_ones = tod.time_mins%10; //ones digit for minutes
//     int min_tens = tod.time_mins/10; //tens digit for miniutes
//     int hour_ones = tod.time_hours%10; //ones digits for hours
//     temp_display|= num_list[min_ones]; //sets minutes one digit section of display
//     temp_display|= num_list[min_tens] << 7; //sets minutes tens digit section of display
//     temp_display|= num_list[hour_ones] << 14; //sets hours ones digit section of display
//     if(tod.time_hours >= 10){
//         temp_display|= num_list[1] << 21; //if hours are above ten, fill in tens digit of hours
//     }
//     if (tod.ampm == 1){ //sets am and pm
//         temp_display|= 1 << 28; 
//     }
//     else{
//         temp_display|= 1 << 29;
//     }
//     *display = temp_display; //sets display to temporary display
//     return 0;
// }
int set_display_from_tod(tod_t tod, int *display){
    if (tod.time_hours > 12 || tod.time_hours < 0 || tod.time_mins > 59 || tod.time_mins < 0){ //checks to see if any of the time fields are out of bounds
        return 1;
    }
    *display = 0;
    int num_list[] = {0b1110111, 0b0100100, 0b1011101, 0b1101101, 0b0101110, 0b1101011, 0b1111011, 0b0100101, 0b1111111, 0b1101111, 0b0000000}; //a list of what needs to be on to represent each number
    int min_ones = tod.time_mins%10; //ones digit for minutes
    int min_tens = tod.time_mins/10; //tens digit for miniutes
    int hour_ones = tod.time_hours%10; //ones digits for hours
    //int temp_display = 0; //makes a temporary location to hold the display
    *display = *display | num_list[min_ones]; //sets minutes one digit section of display
    *display = *display | num_list[min_tens] << 7; //sets minutes tens digit section of display
    *display = *display | num_list[hour_ones] << 14; //sets hours ones digit section of display
    if(tod.time_hours >= 10){
        *display = *display | num_list[1] << 21; //if hours are above ten, fill in tens digit of hours
    }
    if (tod.ampm == 1){ //sets am and pm
        *display = *display |1 << 28; 
    }
    else{
        *display = *display |1 << 29;
    }
//    // *display = temp_display; //sets display to temporary display
    return 0;
}


// Examines the TIME_OF_DAY_PORT global variable to determine hour,
// minute, and am/pm.  Sets the global variable CLOCK_DISPLAY_PORT bits
// to show the proper time.  If TIME_OF_DAY_PORT appears to be in error
// (to large/small) makes no change to CLOCK_DISPLAY_PORT and returns 1
// to indicate an error. Otherwise returns 0 to indicate success.
//
// Makes use of the previous two functions: set_tod_from_ports() and
// set_display_from_tod().
// 
// CONSTRAINT: Does not allocate any heap memory as malloc() is NOT
// available on the target microcontroller.  Uses stack and global
// memory only.
int clock_update(){
    tod_t clock = {};
    int check = set_tod_from_ports(&clock); //if set tod works
    if (check ==1){ //loop out if doesn't work
        return 1;
    }
    else{ 
        set_display_from_tod(clock, &CLOCK_DISPLAY_PORT); //set clock display
    }
    return 0;
}