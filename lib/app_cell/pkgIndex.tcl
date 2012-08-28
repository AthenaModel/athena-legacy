#-------------------------------------------------------------------------
#
# TITLE:
#	pkgIndex.tcl
#
# AUTHOR:
#	William H. Duquette
#
# DESCRIPTION:
#	Athena: app_cell(n) package index file

# Application Main Package

package ifneeded app_cell 1.0 \
    [list source [file join $dir app_cell.tcl]]




