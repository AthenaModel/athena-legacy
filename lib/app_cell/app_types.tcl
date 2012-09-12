#-----------------------------------------------------------------------
# FILE: app_types.tcl
#
#   Application Data Types
#
# PACKAGE:
#   app_cell(n) -- athena_cell(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

# esortcellby: Options for sorting tables of cells

enum esortcellby {
    name "Cell Name"
    line "Line Number"
}

# echeckstate: Has the model been checked or not, and to what effect?

enum echeckstate {
    unchecked "Unchecked"
    syntax    "Syntax Error"
    insane    "Sanity Error"
    checked   "Checked"
}

# esnapshottype: Kinds of snapshot saved by the snapshot model.

enum esnapshottype {
    import   "Import"
    model    "Model"
    solution "Solution"
}

