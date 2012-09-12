#-----------------------------------------------------------------------
# TITLE:
#    dynaforms.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_cell(n) dynaform definitions
#
#    This module contains dynaforms defined for use by the application.
#
#-----------------------------------------------------------------------

dynaform define SnapshotExport {
    rc "Please select the snapshot to export."
    rc
    enumlong snapshot -dictcmd {::snapshot namedict}
}
