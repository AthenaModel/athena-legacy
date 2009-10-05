package require marsutil
package require util
namespace import ::marsutil::* 
namespace import util::*

proc profile {label command {count 10000}} {
    puts "$label: [time $command $count]"
}

enum nbhoods {
    PA01      PA01
    PA02      PA02 
    PA03      PA03 
    PA04      PA04 
    PA05      PA05
    PA06      PA06 
    PA07      PA07 
    PA08      PA08 
    PA09      PA09 
    PA10      PA10
    PA11      PA11 
    PA12      PA12 
    PA13      PA13 
    PA14      PA14 
    PA15      PA15
    GH01      GH01 
    GH02      GH02 
    GH03      GH03 
    GH04      GH04 
    GH05      GH05
    GH06      GH06 
    GH07      GH07 
    GH08      GH08 
    GH09      GH09 
    GH10      GH10
    GH11      GH11 
    GH12      GH12 
    GH13      GH13 
    GH14      GH14 
    GH15      GH15
    GH16      GH16 
    PY01      PY01 
    PY02      PY02 
    PY03      PY03 
    PY04      PY04
    PY05      PY05 
    PY06      PY06 
    PY07      PY07 
    PY08      PY08 
    PY09      PY09
    PY10      PY10 
    PY11      PY11 
    PY12      PY12 
    KH01      KH01 
    KH02      KH02
    KH03      KH03 
    KH04      KH04 
    KH05      KH05 
    KH06      KH06 
    KH07      KH07
    KH08      KH08 
    KH09      KH09 
    KH10      KH10 
    KH11      KH11 
    KH12      KH12
} 

set names [nbhoods names]

# [$enum name $index]
proc case_enum_name_index {} {
    set i [expr {int(rand()*55)}]
    return [nbhoods name $i]
}

# [$enum index2name $index]
proc case_enum_index2name_index {} {
    set i [expr {int(rand()*55)}]
    return [nbhoods index2name $i]
}

# [lindex $names $index]
proc case_lindex_names_index {} {
    set i [expr {int(rand()*55)}]
    return [lindex $::names $i]
}

# [index2name $index]
proc index2name {index} {
    return [lindex $::names $index]
}

proc case_index2name_index {} {
    set i [expr {int(rand()*55)}]
    return [index2name $i]
}

profile {$enum name $index}       case_enum_name_index
profile {$enum index2name $index} case_enum_index2name_index
profile {lindex $::names $index}  case_lindex_names_index
profile {index2name $index}       case_index2name_index

proc case_enum_index_name {} {
    set i [expr {int(rand()*55)}]
    set name [lindex $::names $i]
    return [nbhoods index $name]
}

puts ""
profile {$enum index $name} case_enum_index_name
