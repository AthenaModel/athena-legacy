#-------------------------------------------------------------------------
#
# TITLE:
#	pkgIndex.tcl
#
# AUTHOR:
#	William H. Duquette
#
# DESCRIPTION:
#	Mars: simlib(n) package index file

package ifneeded simlib 1.0 [list source [file join $dir simlib1.tcl]]
package ifneeded simlib 2.0 [list source [file join $dir simlib2.tcl]]




