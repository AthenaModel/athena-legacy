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
# Scaling
#
# For some reason, tk scaling is defaulting to 2.37660818713; it clearly
# ought to be 1.0.  Apparently, this is a common problem on Linux; the
# X server doesn't really know what its pixel resolution is.
#
# TBD: This may no longer be a problem.
#
# tk scaling 1.0

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
# Option Database Settings
#
# This section redefines a number of option database settings to give
# a better default appearance.

set ::marsgui::defaultBackground [. cget -background]

# Tile Theme Settings
ttk::style theme settings alt {
    # Set the alt theme to use the same background as Tk.  This makes
    # Tile at least minimally useable
    ttk::style configure . -background $::marsgui::defaultBackground
}

# Now, use the alt theme for tile widgets.
ttk::style theme use alt

# All widgets
option add *selectBorderWidth 0

# menu widget
option add *Menu.activeBackground  "royal blue"
option add *Menu.activeForeground  white
option add *Menu.activeBorderWidth 0                
option add *Menu.borderWidth       1
option add *Menu.tearOff           no
option add *Menu.font              TkDefaultFont

# frame widget
option add *Frame.borderWidth  1
option add *Frame.relief       raised

# label widget
option add *Label.font                    TkDefaultFont

# button widget
option add *Button.activeBackground       $::marsgui::defaultBackground
option add *Button.borderWidth            1
option add *Button.font                   TkDefaultFont

# menubutton widget
option add *Menubutton.font               TkDefaultFont

# checkbutton widget
option add *Checkbutton.activeBackground  $::marsgui::defaultBackground
option add *Checkbutton.selectColor       $::marsgui::defaultBackground
option add *Checkbutton.borderWidth       1
option add *Checkbutton.font              TkDefaultFont

# radiobutton widget
option add *Radiobutton.activeBackground  $::marsgui::defaultBackground
option add *Radiobutton.selectColor       $::marsgui::defaultBackground
option add *Radiobutton.borderWidth       1
option add *Radiobutton.font              TkDefaultFont

# scrollbar widget
option add *Scrollbar.activeBackground    $::marsgui::defaultBackground
option add *Scrollbar.elementBorderWidth  1
option add *Scrollbar.borderWidth         1
option add *Scrollbar.width               10

# text widget
option add *Text.setGrid            false
option add *Text.foreground         black
option add *Text.background         white
option add *Text.selectBorderWidth  0
option add *Text.relief             flat
option add *Text.borderWidth        0

# listbox widget
option add *Listbox.setGrid            false
option add *Listbox.foreground         black
option add *Listbox.background         white
option add *Listbox.borderWidth        1
option add *Listbox.selectBorderWidth  0
option add *Listbox.font               TkDefaultFont

# entry widget
option add *Entry.foreground  black
option add *Entry.background  white
option add *Entry.borderWidth 1

# spinbox widget
option add *Spinbox.background white
option add *Spinbox.foreground black
option add *Spinbox.borderWidth 1
option add *Spinbox.repeatInterval 15

# BWidget ComboBox widget
option add *ComboBox*Entry.background  white
option add *ComboBox*Entry.foreground  black
option add *ComboBox.borderWidth       1
option add *ComboBox*selectBackground  white
option add *ComboBox*selectForeground  black
option add *ComboBox*selectBorderWidth 0

#BWidget dynamic help (tool tip) defaults
DynamicHelp::configure -background #FFFF99



