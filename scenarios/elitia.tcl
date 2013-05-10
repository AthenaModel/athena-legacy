send NBHOOD:CREATE -n CITY -longname {Capital City} -refpoint C66D46 -polygon {B74D40 D32C24 D60E06 C26E52}
send NBHOOD:CREATE -n EL -longname Elitia -refpoint E62D58 -polygon {D14D58 F17C28 F63D50 E76E06 F55E88 E20F39}
send NBHOOD:UPDATE -n CITY -longname {Capital City} -local YES -urbanization URBAN -controller NONE -vtygain { 1.0} -refpoint F47E12 -polygon {F63D50 E76E06 F55E88 G31E58}
send NBHOOD:CREATE -n PE -longname Peonia -urbanization RURAL -refpoint G21D98 -polygon {F17C28 F63D50 G31E58 H69E28 H57D10 G51C22}
send NBHOOD:UPDATE -n EL -longname Elitia -local YES -urbanization RURAL -controller NONE -vtygain { 1.0} -refpoint E62D58 -polygon {D14D58 F17C28 F63D50 E76E06 F55E88 E20F39}
send NBREL:UPDATE -id {EL CITY} -proximity NEAR
send NBREL:UPDATE -id {CITY EL} -proximity FAR
send NBREL:UPDATE -id {PE CITY} -proximity FAR
send NBREL:UPDATE -id {PE EL} -proximity FAR
send NBREL:UPDATE -id {CITY PE} -proximity REMOTE
send ACTOR:CREATE -a GOV -longname {Elitian Government} -income_goods 1M
send ACTOR:CREATE -a PELF -longname {Peonian Liberation Front} -income_goods 250K
send ACTOR:CREATE -a EPP -longname {Elitian People's Party} -income_goods 1M
send ACTOR:UPDATE -a GOV -longname {Elitian Government} -cash_reserve 0.00 -income_goods 5.000M -cash_on_hand 0.00
send ACTOR:UPDATE -a PELF -longname {Peonian Liberation Front} -cash_reserve 0.00 -income_goods 250,000 -cash_on_hand 250K -shares_black_nr 1
send FRCGROUP:CREATE -g ARMY -longname {Elitian Army} -a GOV -shape FRIEND -base_personnel 20000 -cost 5000 -attack_cost 3000 -local 1
send FRCGROUP:CREATE -g PELFM -longname {PELF Militia} -a PELF -shape ENEMY -forcetype IRREGULAR -base_personnel 6000 -demeanor AGGRESSIVE -cost 1000 -attack_cost 500 -uniformed 0 -local 1
send ACTOR:UPDATE -a PELF -longname {Peonian Liberation Front} -cash_reserve 0.00 -income_goods 250,000 -cash_on_hand 500k
send CIVGROUP:CREATE -g PEONR -longname {Rural Peons} -n PE -demeanor AGGRESSIVE
send CIVGROUP:CREATE -g PEONU -longname {Urban Peons} -n CITY -color #AA7744
send CIVGROUP:UPDATE -g PEONR -longname {Rural Peons} -n PE -color #AA7744 -shape NEUTRAL -demeanor AGGRESSIVE -basepop 10000
send CIVGROUP:UPDATE -g PEONR -longname {Rural Peons} -n PE -color #AA7744 -shape NEUTRAL -demeanor AGGRESSIVE -basepop 40000
send CIVGROUP:CREATE -g ELR -longname {Rural Elitians} -n EL -basepop 50000
send CIVGROUP:UPDATE -g PEONR -longname {Rural Peons} -n PE -color #AA7744 -shape NEUTRAL -demeanor AGGRESSIVE -basepop 40000
send CIVGROUP:CREATE -g ELU -longname {Urban Elitians} -n CITY -basepop 30000
send BSYSTEM:TOPIC:CREATE -tid PI -title {Peonian Independence}
send BSYSTEM:TOPIC:CREATE -tid DEM -title Democracy
send BSYSTEM:BELIEF:UPDATE -id {GOV DEM} -position S-
send BSYSTEM:BELIEF:UPDATE -id {GOV DEM} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {GOV PI} -position S-
send BSYSTEM:BELIEF:UPDATE -id {GOV PI} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {EPP DEM} -position S+
send BSYSTEM:BELIEF:UPDATE -id {EPP DEM} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {PELF DEM} -position W+
send BSYSTEM:BELIEF:UPDATE -id {PELF DEM} -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {PELF PI} -position P+
send BSYSTEM:BELIEF:UPDATE -id {PELF PI} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {EPP PI} -position W+
send BSYSTEM:BELIEF:UPDATE -id {EPP PI} -emphasis DWEAK
send BSYSTEM:PLAYBOX:UPDATE -gamma 0.7
send BSYSTEM:BELIEF:UPDATE -id {EPP DEM} -emphasis DEXTREME
send BSYSTEM:PLAYBOX:UPDATE -gamma 0.5
send BSYSTEM:PLAYBOX:UPDATE -gamma 0.7
send BSYSTEM:ENTITY:UPDATE -eid PELF -commonality 0.80
send BSYSTEM:BELIEF:UPDATE -id {PEONR DEM} -position W+
send BSYSTEM:BELIEF:UPDATE -id {PEONR DEM} -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {PEONR PI} -position S+
send BSYSTEM:BELIEF:UPDATE -id {PEONR PI} -emphasis DSTRONG
send BSYSTEM:ENTITY:UPDATE -eid PEONR -commonality 0.80
send BSYSTEM:ENTITY:UPDATE -eid PEONR -commonality 0.60
send BSYSTEM:BELIEF:UPDATE -id {PEONU DEM} -position S+
send BSYSTEM:BELIEF:UPDATE -id {PEONU DEM} -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {PEONU PI} -position S+
send BSYSTEM:BELIEF:UPDATE -id {PEONU PI} -emphasis DWEAK
send BSYSTEM:ENTITY:UPDATE -eid PEONU -commonality 0.70
send BSYSTEM:ENTITY:UPDATE -eid PEONU -commonality 0.45
send BSYSTEM:BELIEF:UPDATE -id {ELU DEM} -position W-
send BSYSTEM:BELIEF:UPDATE -id {ELU DEM} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {ELU PI} -position P-
send BSYSTEM:BELIEF:UPDATE -id {ELU PI} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {ELR DEM} -position W+
send BSYSTEM:BELIEF:UPDATE -id {ELR DEM} -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {ELR PI} -position P-
send BSYSTEM:BELIEF:UPDATE -id {ELR PI} -emphasis DSTRONG
send CIVGROUP:UPDATE -g ELU -longname {Urban Elitians} -n CITY -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 300000
send CIVGROUP:UPDATE -g PEONU -longname {Urban Peons} -n CITY -color #AA7744 -shape NEUTRAL -demeanor AVERAGE -basepop 50000
send CIVGROUP:UPDATE -g ELR -longname {Rural Elitians} -n EL -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 300000
send CIVGROUP:UPDATE -g ELR -longname {Rural Elitians} -n EL -color #45DD11 -shape NEUTRAL -demeanor AVERAGE -basepop 600000
send CIVGROUP:UPDATE -g PEONR -longname {Rural Peons} -n PE -color #AA7744 -shape NEUTRAL -demeanor AGGRESSIVE -basepop 800000
send NBHOOD:UPDATE -n CITY -longname {Capital City} -local YES -urbanization URBAN -controller GOV -vtygain { 1.0} -refpoint F47E12 -polygon {F63D50 E76E06 F55E88 G31E58}
send NBHOOD:UPDATE -n EL -longname Elitia -local YES -urbanization RURAL -controller GOV -vtygain { 1.0} -refpoint E62D58 -polygon {D14D58 F17C28 F63D50 E76E06 F55E88 E20F39}
send NBHOOD:UPDATE -n PE -longname Peonia -local YES -urbanization RURAL -controller GOV -vtygain { 1.0} -refpoint G21D98 -polygon {F17C28 F63D50 G31E58 H69E28 H57D10 G51C22}
send GOAL:CREATE -owner EPP -narrative {Democracy in Elitia}
send GOAL:CREATE -owner GOV -narrative {Maintain Control}
send GOAL:CREATE -owner PELF -narrative {Free Peonia}
send CONDITION:CONTROL:CREATE -cc_id 2 -a GOV -list1 {CITY EL PE}
send CONDITION:CONTROL:CREATE -cc_id 3 -a PELF -list1 PE
send CONDITION:CONTROL:CREATE -cc_id 1 -a PELF -list1 {CITY EL}
send TACTIC:FUND:CREATE -owner EPP -a PELF -x1 500K
send CONDITION:CONTROL:UPDATE -condition_id 3 -a EPP -list1 {CITY EL}
send CONDITION:UNMET:CREATE -cc_id 4 -list1 1
send CAP:CREATE -k CBS -longname {Corps Broadcasting System} -owner GOV -capacity 1.00 -cost 100 -nlist {CITY EL} -glist {ELR ELU}
send CAP:CREATE -k FOX -longname {Fox Snooze} -owner PELF -capacity 0.90 -cost 20 -nlist {EL PE} -glist {ELR ELU PEONR PEONU}
send BSYSTEM:TOPIC:CREATE -tid PAT -title Patriotism -affinity 0
send BSYSTEM:TOPIC:CREATE -tid PUPPIES -title Puppies! -affinity 0
send HOOK:CREATE -hook_id PUPGOOD -longname {Puppies Are Good!}
send HOOK:TOPIC:CREATE -hook_id PUPGOOD -topic_id PUPPIES -position S+
send IOM:CREATE -iom_id NOPUPPIES -longname {The Gov't wants to eat our puppies.} -hook_id PUPGOOD
send IOM:CREATE -iom_id PATRIOT -longname {Be a patriot!} -hook_id PUPGOOD
send HOOK:CREATE -hook_id HPAT -longname {Patriotism and Puppies}
send HOOK:TOPIC:CREATE -hook_id HPAT -topic_id PAT -position S+
send HOOK:TOPIC:CREATE -hook_id HPAT -topic_id PUPPIES -position P+
send HOOK:TOPIC:STATE -id {HPAT PAT} -state disabled
send HOOK:TOPIC:STATE -id {HPAT PAT} -state normal
send IOM:UPDATE -iom_id PATRIOT -longname {Be a patriot!} -hook_id HPAT
send IOM:UPDATE -iom_id PATRIOT -longname {Be a patriot!  Support our puppies!} -hook_id HPAT
send PAYLOAD:COOP:CREATE -iom_id NOPUPPIES -g ARMY -mag -8.5
send PAYLOAD:HREL:CREATE -iom_id PATRIOT -g ARMY -mag 7.0
send PAYLOAD:VREL:CREATE -iom_id PATRIOT -a GOV -mag 13.0
send CIVGROUP:CREATE -g SA -n PE -basepop 100000 -sa_flag 1 -lfp 0
send CIVGROUP:CREATE -g NOBODY -n CITY -basepop 0
send CURSE:CREATE -curse_id FLOOD -longname {Flood in Peonia} -s 1.00 -p 0.50 -q 0.10
send INJECT:SAT:CREATE -curse_id FLOOD -longname {Flood in Peonia} -g @VICTIMS -c QOL -mag -4.5
send INJECT:VREL:CREATE -curse_id FLOOD -longname {Flood in Peonia} -g @VICTIMS -a @GOVT -mag -3.5
