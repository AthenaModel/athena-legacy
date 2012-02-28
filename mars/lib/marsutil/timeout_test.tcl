#-----------------------------------------------------------------------
# TITLE:
#    timeout_test.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Test script for timeout(n).
#
#-----------------------------------------------------------------------

package require marsutil
package require util

set counter 0

proc handler {} {
    global counter

    puts "Execute [incr counter]"
   
    if {$counter == 4} {
        puts "Destroy Timer 3"
        timer3 destroy
    }

    if {$counter == 7} {
        puts "Reschedule Repetitive Timer Explicitly!"
        timer1 schedule
    }

    if {$counter == 10} {
        puts "Cancelling!"
        timer1 cancel
    }
}

::util::timeout idleTimer \
    -interval idle \
    -command [list puts "idleTimer!"]

::util::timeout timer1 \
    -command handler \
    -repetition yes

::util::timeout timer2 \
    -command [list puts "Timer 2!"] \
    -interval 5000

::util::timeout timer3 \
    -command [list puts "Timer 3!"] \
    -repetition yes

idleTimer schedule
timer1 schedule
timer2 schedule
timer3 schedule

after 15000 exit

vwait dummy

    
