# Exporting  from current data
# Exported @ Wed Feb 05 08:14:38 PST 2014
# Written by Athena version 6.0.x
#
# Note: if header has no commands following it, then
# there was no data of that kind to export.

#-----------------------------------------------------------------
# Date and Time Parameters

send SIM:STARTDATE -startdate 2012W01
send SIM:STARTTICK -starttick 0

#-----------------------------------------------------------------
# Model Parameters


#-----------------------------------------------------------------
# Base Entities: Actors

send ACTOR:CREATE -a GOV -longname {Elitian Government} -auto_maintain 0 -atype INCOME -cash_reserve 0.00 -cash_on_hand 0.00 -income_goods 5.000M -shares_black_nr 0 -income_black_tax 0.00 -income_pop 0.00 -income_graft 0.00 -income_world 0.00 -budget 0.00
send ACTOR:CREATE -a PELF -longname {Peonian Liberation Front} -auto_maintain 0 -atype INCOME -cash_reserve 0.00 -cash_on_hand 500,000 -income_goods 250,000 -shares_black_nr 1 -income_black_tax 0.00 -income_pop 0.00 -income_graft 0.00 -income_world 0.00 -budget 0.00
send ACTOR:CREATE -a EPP -longname {Elitian People's Party} -auto_maintain 0 -atype INCOME -cash_reserve 0.00 -cash_on_hand 0.00 -income_goods 1.000M -shares_black_nr 0 -income_black_tax 0.00 -income_pop 0.00 -income_graft 0.00 -income_world 0.00 -budget 0.00
send ACTOR:SUPPORTS -a GOV -supports SELF
send ACTOR:SUPPORTS -a PELF -supports SELF
send ACTOR:SUPPORTS -a EPP -supports SELF

#-----------------------------------------------------------------
# Base Entities: Neighborhoods

send NBHOOD:CREATE -n CITY -longname {Capital City} -local YES -pcf { 1.0} -urbanization URBAN -controller GOV -refpoint F47E12 -polygon {F63D50 E76E06 F55E88 G31E58}
send NBHOOD:CREATE -n EL -longname Elitia -local YES -pcf { 1.0} -urbanization RURAL -controller GOV -refpoint E62D58 -polygon {D14D58 F17C28 F63D50 E76E06 F55E88 E20F39}
send NBHOOD:CREATE -n PE -longname Peonia -local YES -pcf { 1.0} -urbanization RURAL -controller GOV -refpoint G21D98 -polygon {F17C28 F63D50 G31E58 H69E28 H57D10 G51C22}
send NBHOOD:CREATE -n IN -longname Incognitia -local NO -pcf { 0.0} -urbanization RURAL -controller NONE -refpoint D75C54 -polygon {D14D58 C59C34 E80B25 F17C28}
send NBREL:UPDATE -id {EL CITY} -proximity NEAR
send NBREL:UPDATE -id {CITY EL} -proximity FAR
send NBREL:UPDATE -id {PE CITY} -proximity REMOTE
send NBREL:UPDATE -id {PE EL} -proximity FAR
send NBREL:UPDATE -id {CITY PE} -proximity REMOTE
send NBREL:UPDATE -id {EL PE} -proximity FAR
send NBREL:UPDATE -id {IN CITY} -proximity REMOTE
send NBREL:UPDATE -id {IN EL} -proximity REMOTE
send NBREL:UPDATE -id {IN PE} -proximity REMOTE
send NBREL:UPDATE -id {CITY IN} -proximity REMOTE
send NBREL:UPDATE -id {EL IN} -proximity REMOTE
send NBREL:UPDATE -id {PE IN} -proximity REMOTE

#-----------------------------------------------------------------
# Base Entities: Civilian Groups

send CIVGROUP:CREATE -g PEONR -longname {Rural Peons} -n PE -color #AA7744 -shape NEUTRAL -demeanor AGGRESSIVE -basepop 800000 -pop_cr 0.0 -sa_flag 0 -lfp 60 -housing AT_HOME -hist_flag 0 -upc 0.0
send CIVGROUP:CREATE -g PEONU -longname {Urban Peons} -n CITY -color #AA7744 -shape NEUTRAL -demeanor AVERAGE -basepop 50000 -pop_cr 0.0 -sa_flag 0 -lfp 60 -housing AT_HOME -hist_flag 0 -upc 0.0
send CIVGROUP:CREATE -g ELR -longname {Rural Elitians} -n EL -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 600000 -pop_cr 0.0 -sa_flag 0 -lfp 60 -housing AT_HOME -hist_flag 0 -upc 0.0
send CIVGROUP:CREATE -g ELU -longname {Urban Elitians} -n CITY -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 300000 -pop_cr 0.0 -sa_flag 0 -lfp 60 -housing AT_HOME -hist_flag 0 -upc 0.0
send CIVGROUP:CREATE -g SA -longname SA -n PE -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 100000 -pop_cr 0.0 -sa_flag 1 -lfp 0 -housing AT_HOME -hist_flag 0 -upc 0.0
send CIVGROUP:CREATE -g NOBODY -longname NOBODY -n CITY -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 0 -pop_cr 0.0 -sa_flag 0 -lfp 60 -housing AT_HOME -hist_flag 0 -upc 0.0
send CIVGROUP:CREATE -g ICS -longname Incognitians -n IN -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 10000 -pop_cr 0.0 -sa_flag 0 -lfp 60 -housing AT_HOME -hist_flag 0 -upc 0.0

#-----------------------------------------------------------------
# Base Entities: Force Groups

send FRCGROUP:CREATE -g ARMY -longname {Elitian Army} -a GOV -color #3B61FF -shape FRIEND -forcetype REGULAR -training FULL -base_personnel 20000 -demeanor AVERAGE -cost 5,000.00 -attack_cost 3,000.00 -uniformed 1 -local 1
send FRCGROUP:CREATE -g PELFM -longname {PELF Militia} -a PELF -color #3B61FF -shape ENEMY -forcetype IRREGULAR -training FULL -base_personnel 6000 -demeanor AGGRESSIVE -cost 1,000.00 -attack_cost 500.00 -uniformed 0 -local 1

#-----------------------------------------------------------------
# Base Entities: Organization Groups


#-----------------------------------------------------------------
# Belief Systems

send BSYSTEM:PLAYBOX:UPDATE -gamma 0.7
send BSYSTEM:ENTITY:UPDATE -eid GOV -commonality 1.0
send BSYSTEM:ENTITY:UPDATE -eid PELF -commonality 0.8
send BSYSTEM:ENTITY:UPDATE -eid EPP -commonality 1.0
send BSYSTEM:ENTITY:UPDATE -eid PEONR -commonality 0.6
send BSYSTEM:ENTITY:UPDATE -eid PEONU -commonality 0.45
send BSYSTEM:ENTITY:UPDATE -eid ELR -commonality 1.0
send BSYSTEM:ENTITY:UPDATE -eid ELU -commonality 1.0
send BSYSTEM:ENTITY:UPDATE -eid SA -commonality 1.0
send BSYSTEM:ENTITY:UPDATE -eid NOBODY -commonality 1.0
send BSYSTEM:ENTITY:UPDATE -eid ICS -commonality 1.0
send BSYSTEM:TOPIC:CREATE -tid PI -title {Peonian Independence} -affinity 1
send BSYSTEM:TOPIC:CREATE -tid DEM -title Democracy -affinity 1
send BSYSTEM:TOPIC:CREATE -tid PAT -title Patriotism -affinity 0
send BSYSTEM:TOPIC:CREATE -tid PUPPIES -title Puppies! -affinity 0
send BSYSTEM:BELIEF:UPDATE -id {ELR PI} -position P- -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {ELU PI} -position P- -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {EPP PI} -position W+ -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {GOV PI} -position S- -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {ICS PI} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {NOBODY PI} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PELF PI} -position P+ -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {PEONR PI} -position S+ -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {PEONU PI} -position S+ -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {SA PI} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {ELR DEM} -position W+ -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {ELU DEM} -position W- -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {EPP DEM} -position S+ -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {GOV DEM} -position S- -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {ICS DEM} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {NOBODY DEM} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PELF DEM} -position W+ -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {PEONR DEM} -position W+ -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {PEONU DEM} -position S+ -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {SA DEM} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {ELR PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {ELU PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {EPP PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {GOV PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {ICS PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {NOBODY PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PELF PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PEONR PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PEONU PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {SA PAT} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {ELR PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {ELU PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {EPP PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {GOV PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {ICS PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {NOBODY PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PELF PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PEONR PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {PEONU PUPPIES} -position A -emphasis NEITHER
send BSYSTEM:BELIEF:UPDATE -id {SA PUPPIES} -position A -emphasis NEITHER

#-----------------------------------------------------------------
# Attitudes


#-----------------------------------------------------------------
# Environmental Situations


#-----------------------------------------------------------------
# Economics: SAM Inputs


#-----------------------------------------------------------------
# Plant Infrastructure:

send PLANT:SHARES:CREATE -a GOV -n CITY -rho 1.0 -num 1
send PLANT:SHARES:CREATE -a GOV -n EL -rho 1.0 -num 1

#-----------------------------------------------------------------
# CURSEs

send CURSE:CREATE -curse_id FLOOD -longname {Flood in Peonia} -cause UNIQUE -s 1.0 -p 0.5 -q 0.1
send CURSE:CREATE -curse_id FIRE -longname {Fire in Elitia} -cause UNIQUE -s 1.0 -p 0.2 -q 0.05
send INJECT:COOP:CREATE -curse_id FLOOD -mode transient -f @CIV1 -g @FRC1 -mag 1.0
send INJECT:HREL:CREATE -curse_id FLOOD -mode transient -f @FRC1 -g @CIV1 -mag -11.0
send INJECT:SAT:CREATE -curse_id FLOOD -mode transient -g @CIV2 -c SFT -mag -4.5
send INJECT:SAT:CREATE -curse_id FIRE -mode transient -g @CIVGRP2 -c QOL -mag -10.5
send INJECT:VREL:CREATE -curse_id FLOOD -mode transient -g @GRP1 -a @ACT1 -mag -8.0

#-----------------------------------------------------------------
# Communication Asset Packages (CAPs)

send CAP:CREATE -k CBS -longname {Corps Broadcasting System} -owner GOV -capacity 1.0 -cost 100.0
send CAP:CREATE -k FOX -longname {Fox Snooze} -owner PELF -capacity 0.9 -cost 20.0
send CAP:NBCOV:SET -id {CBS CITY} -nbcov 1.00
send CAP:NBCOV:SET -id {CBS EL} -nbcov 1.00
send CAP:NBCOV:SET -id {FOX EL} -nbcov 1.00
send CAP:NBCOV:SET -id {FOX PE} -nbcov 1.00
send CAP:PEN:SET -id {FOX PEONR} -pen 1.00
send CAP:PEN:SET -id {CBS ELR} -pen 1.00
send CAP:PEN:SET -id {FOX ELR} -pen 1.00
send CAP:PEN:SET -id {CBS ELU} -pen 1.00

#-----------------------------------------------------------------
# Semantic Hooks

send HOOK:CREATE -hook_id PUPGOOD -longname {Puppies Are Good!}
send HOOK:CREATE -hook_id HPAT -longname {Patriotism and Puppies}
send HOOK:TOPIC:CREATE -hook_id PUPGOOD -topic_id PUPPIES -position 0.6
send HOOK:TOPIC:CREATE -hook_id HPAT -topic_id PAT -position 0.6
send HOOK:TOPIC:CREATE -hook_id HPAT -topic_id PUPPIES -position 0.9

#-----------------------------------------------------------------
# Information Operations Messages (IOMs)

send IOM:CREATE -iom_id NOPUPPIES -longname {The Gov't wants to eat our puppies.} -hook_id PUPGOOD
send IOM:CREATE -iom_id PATRIOT -longname {Be a patriot! Support our puppies!} -hook_id HPAT
send PAYLOAD:COOP:CREATE -iom_id NOPUPPIES -g ARMY -mag -8.5
send PAYLOAD:HREL:CREATE -iom_id PATRIOT -g ARMY -mag 7.0
send PAYLOAD:VREL:CREATE -iom_id PATRIOT -a GOV -mag 13.0

#-----------------------------------------------------------------
# Magic Attitude Drivers (MADs)


#-----------------------------------------------------------------
# Strategy: EPP


#-----------------------------------------------------------------
# Strategy: GOV

block add GOV -onlock 0 -once 0 -intent {} -tmode ALWAYS -t1 {} -t2 {} -cmode ALL -emode ALL
tactic add - BUILD -n CITY -mode CASH -num 1 -amount 100000.0


#-----------------------------------------------------------------
# Strategy: PELF


#-----------------------------------------------------------------
# Strategy: SYSTEM


#-----------------------------------------------------------------
# Bookmarks


#-----------------------------------------------------------------
# Executive Scripts


# *** End of Script ***
