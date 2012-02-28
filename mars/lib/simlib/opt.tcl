loadperf -nbhoods 20 -civgroups 8 -frcgroups 4
mass level -type sat
mass level -type coop
set ds [mass slope -type sat]
set dc [mass slope -type coop]
step
mass slope -type sat -driver $ds
mass slope -type coop -driver $dc
