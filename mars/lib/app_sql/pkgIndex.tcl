#-------------------------------------------------------------------------
#
# TITLE:
#	pkgIndex.tcl
#
# AUTHOR:
#	William H. Duquette
#
# DESCRIPTION:
#	JNEM: app_sql(n) package index file

package ifneeded app_sql 1.0 \
    [list source [file join $dir app_sql.tcl]]



