#-------------------------------------------------------------------------
#
# TITLE:
#	pkgIndex.tcl
#
# AUTHOR:
#	William H. Duquette
#
# DESCRIPTION:
#	Athena: app_sim(n) package index file

# Application Main Package

package ifneeded app_sim 1.0 \
    [list source [file join $dir app_sim.tcl]]

# Thread Main Packages

package ifneeded app_sim_engine 1.0 \
    [list source [file join $dir engine app_sim_engine.tcl]]

package ifneeded app_sim_logger 1.0 \
    [list source [file join $dir logger app_sim_logger.tcl]]

# Functionality Packages

package ifneeded app_sim_shared 1.0 \
    [list source [file join $dir shared app_sim_shared.tcl]]

package ifneeded app_sim_ui 1.0 \
    [list source [file join $dir ui app_sim_ui.tcl]]



