package require marsgui
namespace import ::marsgui::*

proc returncmd {text} {
    puts "-returncmd <$text>"
}

proc keycmd {char keysym} {
    if {![string is print -strict $char]} {
        set char "---"
    }
    puts "-key <$char> <$keysym>"
}

proc changecmd {text} {
    puts "-changecmd <$text>"
}

button .set \
    -text "Set!" \
    -command [list .ce set "Howdy!"]

button .clear \
    -text "Clear!" \
    -command [list .ce clear]

commandentry .ce \
    -background $::marsgui::defaultBackground \
    -clearbtn 1 \
    -keycmd keycmd \
    -returncmd returncmd \
    -changecmd changecmd

pack .set -side left
pack .clear -side right
pack .ce



