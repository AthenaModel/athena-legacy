package require marsutil
package require simlib
namespace import -force marsutil::* simlib::*

# FIRST, create an RDB

sqldocument urdb
urdb register ::simlib::ucurve
urdb open :memory:
urdb clear


# NEXT, create a ucurve(n)
ucurve cm -rdb ::urdb -autoseparators on -undo on

# NEXT, add some curve types
cm ctype add AUT  -100.0 100.0 -alpha 0.1 -gamma 0.0
cm ctype add CUL  -100.0 100.0 -alpha 0.1 -gamma 0.0
cm ctype add QOL  -100.0 100.0 -alpha 0.1 -gamma 0.0
cm ctype add SFT  -100.0 100.0 -alpha 0.1 -gamma 0.05
cm ctype add coop    0.0 100.0 -alpha 0.1 -gamma 0.05
cm ctype add hrel   -1.0   1.0 -alpha 0.1 -gamma 0.05
cm ctype add vrel   -1.0   1.0 -alpha 0.1 -gamma 0.05

cm curve add AUT 40 30 0 40 40 0 -20 0 0

cm effect 11 12 1 -10 2 -20 3 -30

