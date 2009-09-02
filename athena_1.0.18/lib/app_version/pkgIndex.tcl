#-------------------------------------------------------------------------
#
# TITLE:
#	pkgIndex.tcl
#
# AUTHOR:
#	William H. Duquette
#
# DESCRIPTION:
#	Athena: app(version) package index file

package ifneeded app_version 1.0 \
    [list source [file join $dir app_version.tcl]]




