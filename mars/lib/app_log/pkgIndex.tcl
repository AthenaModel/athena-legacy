#-------------------------------------------------------------------------
#
# TITLE:
#	pkgIndex.tcl
#
# AUTHOR:
#	William H. Duquette
#
# DESCRIPTION:
#	Mars: app_log(n) package index file

package ifneeded app_log 1.0 \
    [list source [file join $dir app_log.tcl]]


