#-----------------------------------------------------------------------
# TITLE:
#    global.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Mars marsgui(n) -- Global Definitions
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Cut, Copy, and Paste; Undo and Redo
#
# This code updates the standard Tk bindings for X so that
# the Windows keystrokes for these operations are available.
#
# Note the the Windows "Redo" key is typically Control-y; but that's
# also used for Paste on Solaris, and I don't want to break that, 
# especially as I doubt most people even know that Redo has a 
# Control key on Windows.

# Relate the virtual events to these keystrokes.  Widgets will get
# the virtual event on the keystroke, unless there's some other
# keybinding.

event add <<Cut>>       <Control-x>
event add <<Copy>>      <Control-c>
event add <<Paste>>     <Control-v>
event add <<Undo>>      <Control-z>
event add <<Redo>>      <Control-Z>  ;# Control-Shift-Z
event add <<SelectAll>> <Control-A>  ;# Control-Shift-A

# The Text widget has a <Control-v> binding that's obscure; remove it.
bind Text <Control-v> ""

#-----------------------------------------------------------------------
# Standard Font Creation
#
# Use pixel sizing; it's more general across machines.

font create codefont       -family {Luxi Mono}   -size -12 -weight normal
font create codefontitalic -family {Luxi Mono}   -size -12 -weight normal \
                           -slant italic
font create codefontbold   -family {Luxi Mono}   -size -12 -weight bold
font create tinyfont       -family {Luxi Sans}   -size  -9 -weight normal

font create messagefont    -family Helvetica -size -12
font create messagefontb   -family Helvetica -size -12 -weight bold
font create reportfont     -family Helvetica -size -14 -weight bold

#-----------------------------------------------------------------------
# Standard Icons
#
# The standard icon size is 16x16

foreach fileName [glob [file join $::marsgui::library *.xbm]] {
    set imageName "::marsgui::[file rootname [file tail $fileName]]_icon"
    image create bitmap $imageName -file $fileName
}

namespace eval ::marsgui::icon:: {}

foreach fileName [glob [file join $::marsgui::library *.gif]] {
    set imageName "::marsgui::icon::[file rootname [file tail $fileName]]"
    image create photo $imageName -file $fileName
}


#-------------------------------------------------------------------
# Entry Widget Behavior
#
# For some odd reason, if you paste via <<Paste>> into an entry widget
# when text is selected, the pasted text doesn't replace the selected
# text.  I don't know why this is, but it's counter-intuitive.  The
# default binding says explicitly that if we're on x11 *don't* delete
# the previously selected text.  This binding deletes this check,
# restoring the expected behavior.

bind Entry <<Paste>> {
    catch {
        catch {
            %W delete sel.first sel.last
        }

        %W insert insert [::tk::GetSelection %W CLIPBOARD]
        tk::EntrySeeInsert %W
    }
}

#-----------------------------------------------------------------------
# Text Widget Behavior
#
# The same thing applies to the Text Widget; pasting doesn't delete the
# selection.  Here the code is in the tk_textPaste command, which is
# patched below to fix the behavior.

proc ::tk_textPaste w {
    global tcl_platform
    if {![catch {::tk::GetSelection $w CLIPBOARD} sel]} {
	set oldSeparator [$w cget -autoseparators]
	if {$oldSeparator} {
	    $w configure -autoseparators 0
	    $w edit separator
	}

        # WHD: The next line used to execute only for non-x11 platforms.        
        catch { $w delete sel.first sel.last }
        
	$w insert insert $sel
	if {$oldSeparator} {
	    $w edit separator
	    $w configure -autoseparators 1
	}
    }
}

#-----------------------------------------------------------------------
# Ttk Theme Settings

# Use the clam theme for ttk widgets.
ttk::style theme use clam

# Get the default background and active background colors
# from the Ttk theme; we'll configure the classic widgets to use it
# as appropriate.

set ::marsgui::defaultBackground [ttk::style configure . -background]
set ::marsgui::activeBackground  [ttk::style lookup . -background active]

# Entrybutton.Toolbutton: A style for buttons used in entries.
ttk::style configure Entrybutton.Toolbutton -background white
ttk::style map Entrybutton.Toolbutton -background {disabled white}

# Text.Toolbutton: A style for tool buttons that have text instead
# of icons. 
ttk::style configure Text.Toolbutton -font tinyfont

# Give a combobox with focus the same kind of halo as a ttk::entry.
ttk::style map TCombobox \
    -lightcolor      [list  focus "#6f9dc6"] \
    -darkcolor       [list  focus "#6f9dc6"] \
    -fieldbackground [list disabled $::marsgui::defaultBackground]

# Menubox.TCombobox: A style for comboboxes used as pulldown menus.
ttk::style configure Menubox.TCombobox \
    -fieldbackground white -foreground black
# ttk::style map Menubox.TCombobox -fieldbackground {}
ttk::style map Menubox.TCombobox -foreground {}

# Tabless.TNotebook: A style for tabless ttk::notebook widgets
ttk::style layout Tabless.TNotebook.Tab null

# TEntry: Set background for readonly ttk::entry widgets
ttk::style map TEntry \
    -fieldbackground [list readonly $::marsgui::defaultBackground]

#-----------------------------------------------------------------------
# Option Database Settings
#
# This section redefines a number of option database settings to give
# a better default appearance.
#

. configure -background $::marsgui::defaultBackground

option add *background                      $::marsgui::defaultBackground

# menu widget
option add *Menu.tearOff                    no

# button widget
option add *Button.activeBackground         $marsgui::activeBackground
option add *Button.highlightThickness       0

# checkbutton widget
option add *Checkbutton.activeBackground    $marsgui::activeBackground
option add *Checkbutton.borderWidth         0
option add *Checkbutton.highlightThickness  0

# radiobutton widget
option add *Radiobutton.activeBackground    $::marsgui::activeBackground
option add *Radiobutton.borderWidth         0
option add *Radiobutton.highlightThickness  0

# scrollbar widget
option add *Scrollbar.activeBackground      $::marsgui::activeBackground
option add *Scrollbar.width                 14

# text widget
option add *Text.setGrid                    false
option add *Text.foreground                 black
option add *Text.background                 white
option add *Text.relief                     flat
option add *Text.borderWidth                0

# listbox widget
option add *Listbox.setGrid                 false
option add *Listbox.foreground              black
option add *Listbox.background              white

# entry widget
option add *Entry.foreground                black
option add *Entry.background                white

# spinbox widget
option add *Spinbox.background              white
option add *Spinbox.foreground              black
option add *Spinbox.repeatInterval          15

# BWidget ComboBox widget
option add *ComboBox*Entry.background       white
option add *ComboBox*Entry.foreground       black
option add *ComboBox.borderWidth            1
option add *ComboBox*selectBackground       white
option add *ComboBox*selectForeground       black

#BWidget dynamic help (tool tip) defaults
DynamicHelp::configure -background #FFFF99





