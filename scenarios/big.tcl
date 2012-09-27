# big.tcl: Performance Optimization scenario
send NBHOOD:CREATE -n NB01 -refpoint A99B02 -polygon {A41A43 A41B62 B62B62 B62A43}
send NBHOOD:CREATE -n NB02 -refpoint C23B01 -polygon {B62A43 C80A44 C80B62 B62B62}
send NBHOOD:CREATE -n NB03 -refpoint D42B00 -polygon {C80B62 E01B62 E01A41 C80A44}
send NBHOOD:CREATE -n NB04 -refpoint E61B01 -polygon {E01A41 F19A43 F19B60 E01B62}
send NBHOOD:CREATE -n NB05 -refpoint F78B01 -polygon {F19A43 G39A43 G39B58 F19B60}
send NBHOOD:CREATE -n NB06 -refpoint A99C22 -polygon {A41B62 A41C80 B59C81 B62B62}
send NBHOOD:CREATE -n NB07 -refpoint C16C23 -polygon {B59C81 C79C80 C80B62 B62B62}
send NBHOOD:CREATE -n NB08 -refpoint D40C23 -polygon {C79C80 D99C81 E01B62 C80B62}
send NBHOOD:CREATE -n NB09 -refpoint E60C23 -polygon {D99C81 F20C81 F19B60 E01B62}
send NBHOOD:CREATE -n NB10 -refpoint F77C22 -polygon {F20C81 G40C81 G39B58 F19B60}
send NBHOOD:CREATE -n NB11 -refpoint B00D45 -polygon {A41C80 A41E07 B62E03 B59C81}
send NBHOOD:CREATE -n NB12 -refpoint C19D45 -polygon {B62E03 C82E02 C79C80 B59C81}
send NBHOOD:CREATE -n NB13 -refpoint D40D45 -polygon {C82E02 D99E02 D99C81 C79C80}
send NBHOOD:CREATE -n NB14 -refpoint E60D44 -polygon {D99E02 F19E02 F20C81 D99C81}
send NBHOOD:CREATE -n NB15 -refpoint F77D46 -polygon {F19E02 G41E03 G40C81 F20C81}
send NBHOOD:CREATE -n NB16 -refpoint B01E65 -polygon {A41E07 A41F19 B56F19 B62E03}
send NBHOOD:CREATE -n NB17 -refpoint C20E64 -polygon {B56F19 C80F19 C82E02 B62E03}
send NBHOOD:CREATE -n NB18 -refpoint D41E67 -polygon {C80F19 E00F19 D99E02 C82E02}
send NBHOOD:CREATE -n NB19 -refpoint E62E64 -polygon {E00F19 F18F18 F19E02 D99E02}
send NBHOOD:CREATE -n NB20 -refpoint F79E63 -polygon {F18F18 G39F18 G41E03 F19E02}
send ACTOR:CREATE -a A1 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A2 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A3 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A4 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A5 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:DELETE -a A1
send ACTOR:DELETE -a A2
send ACTOR:DELETE -a A3
send ACTOR:DELETE -a A5
send ACTOR:DELETE -a A4
send ACTOR:CREATE -a A01 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A02 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A03 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A04 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A05 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A06 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A07 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A08 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A09 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A10 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A11 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A12 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A13 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A14 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A15 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A16 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A17 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A18 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A19 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send ACTOR:CREATE -a A20 -cash_reserve 1m -cash_on_hand 1m -income_goods 1m -shares_black_nr 1 -income_black_tax 1m -income_pop 1m -income_graft 1m -income_world 1m
send CIVGROUP:CREATE -g CG01 -n NB01
send CIVGROUP:CREATE -g CG02 -n NB01
send CIVGROUP:CREATE -g CG03 -n NB01
send CIVGROUP:CREATE -g CG04 -n NB02
send CIVGROUP:CREATE -g CG05 -n NB02
send CIVGROUP:CREATE -g CG06 -n NB02
send CIVGROUP:CREATE -g CG07 -n NB03
send CIVGROUP:CREATE -g CG08 -n NB03
send CIVGROUP:CREATE -g CG09 -n NB03
send CIVGROUP:CREATE -g CG10 -n NB04
send CIVGROUP:CREATE -g CG11 -n NB04
send CIVGROUP:CREATE -g CG12 -n NB04
send CIVGROUP:CREATE -g CG13 -n NB05
send CIVGROUP:CREATE -g CG14 -n NB05
send CIVGROUP:CREATE -g CG15 -n NB05
send CIVGROUP:CREATE -g CG16 -n NB06
send CIVGROUP:CREATE -g CG17 -n NB06
send CIVGROUP:CREATE -g CG18 -n NB06
send CIVGROUP:CREATE -g CG19 -n NB07
send CIVGROUP:CREATE -g CG20 -n NB07
send CIVGROUP:CREATE -g CG21 -n NB07
send CIVGROUP:CREATE -g CG22 -n NB08
send CIVGROUP:CREATE -g CG23 -n NB08
send CIVGROUP:CREATE -g CG24 -n NB08
send CIVGROUP:CREATE -g CG25 -n NB09
send CIVGROUP:CREATE -g CG26 -n NB09
send CIVGROUP:CREATE -g CG27 -n NB09
send CIVGROUP:CREATE -g CG28 -n NB10
send CIVGROUP:CREATE -g CG29 -n NB10
send CIVGROUP:CREATE -g CG30 -n NB10
send CIVGROUP:CREATE -g CG31 -n NB11
send CIVGROUP:CREATE -g CG32 -n NB11
send CIVGROUP:CREATE -g CG33 -n NB11
send CIVGROUP:CREATE -g CG34 -n NB12
send CIVGROUP:CREATE -g CG35 -n NB12
send CIVGROUP:CREATE -g CG36 -n NB12
send CIVGROUP:CREATE -g CG37 -n NB13
send CIVGROUP:CREATE -g CG38 -n NB13
send CIVGROUP:CREATE -g CG39 -n NB13
send CIVGROUP:CREATE -g CG40 -n NB14
send CIVGROUP:CREATE -g CG41 -n NB14
send CIVGROUP:CREATE -g CG42 -n NB14
send CIVGROUP:CREATE -g CG43 -n NB15
send CIVGROUP:CREATE -g CG44 -n NB15
send CIVGROUP:CREATE -g CG45 -n NB15
send CIVGROUP:CREATE -g CG46 -n NB16
send CIVGROUP:CREATE -g CG47 -n NB16
send CIVGROUP:CREATE -g CG48 -n NB16
send CIVGROUP:CREATE -g CG49 -n NB17
send CIVGROUP:CREATE -g CG50 -n NB17
send CIVGROUP:CREATE -g CG51 -n NB17
send CIVGROUP:CREATE -g CG52 -n NB18
send CIVGROUP:CREATE -g CG53 -n NB18
send CIVGROUP:CREATE -g CG54 -n NB18
send CIVGROUP:CREATE -g CG55 -n NB19
send CIVGROUP:CREATE -g CG56 -n NB19
send CIVGROUP:CREATE -g CG57 -n NB19
send CIVGROUP:CREATE -g CG58 -n NB20
send CIVGROUP:CREATE -g CG59 -n NB20
send CIVGROUP:CREATE -g CG60 -n NB20
send FRCGROUP:CREATE -g FG01 -a A01 -base_personnel 1000 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG02 -a A01 -base_personnel 1000 -cost 100 -attack_cost 100
send FRCGROUP:UPDATE -g FG02 -longname FG02 -a A02 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:CREATE -g FG03 -a A03 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG04 -a A04 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG05 -a A05 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG06 -a A06 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG07 -a A07 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG08 -a A08 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG09 -a A09 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG10 -a A10 -cost 100 -attack_cost 100
send FRCGROUP:CREATE -g FG11 -a A11 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG12 -a A12 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG13 -a A13 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG14 -a A14 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG15 -a A15 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG16 -a A16 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG17 -a A17 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG18 -a A18 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG19 -a A19 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send FRCGROUP:CREATE -g FG20 -a A20 -color #FF0000 -cost 100 -attack_cost 100 -uniformed 0 -local 1
send TACTIC:DEPLOY:CREATE -owner A01 -g FG01 -text1 ALL -int1 {} -nlist {NB01 NB02}
send TACTIC:DEPLOY:CREATE -owner A02 -g FG02 -text1 ALL -int1 {} -nlist {NB03 NB04}
send TACTIC:DEPLOY:CREATE -owner A03 -g FG03 -text1 ALL -int1 {} -nlist {NB05 NB06}
send TACTIC:DEPLOY:CREATE -owner A04 -g FG04 -text1 ALL -int1 {} -nlist {NB07 NB08}
send TACTIC:DEPLOY:CREATE -owner A05 -g FG05 -text1 ALL -int1 {} -nlist {NB09 NB10}
send TACTIC:DEPLOY:CREATE -owner A06 -g FG06 -text1 ALL -int1 {} -nlist {NB11 NB12}
send TACTIC:DEPLOY:CREATE -owner A07 -g FG07 -text1 ALL -int1 {} -nlist {NB13 NB14}
send TACTIC:DEPLOY:CREATE -owner A08 -g FG08 -text1 ALL -int1 {} -nlist {NB15 NB16}
send TACTIC:DEPLOY:CREATE -owner A09 -g FG09 -text1 ALL -int1 {} -nlist {NB17 NB18}
send TACTIC:DEPLOY:CREATE -owner A10 -g FG10 -text1 ALL -int1 {} -nlist {NB19 NB20}
send TACTIC:DEPLOY:CREATE -owner A11 -g FG11 -text1 ALL -int1 {} -nlist {NB01 NB02}
send TACTIC:DEPLOY:CREATE -owner A12 -g FG12 -text1 ALL -int1 {} -nlist {NB03 NB04}
send TACTIC:DEPLOY:CREATE -owner A13 -g FG13 -text1 ALL -int1 {} -nlist {NB05 NB06}
send TACTIC:DEPLOY:CREATE -owner A14 -g FG14 -text1 ALL -int1 {} -nlist {NB07 NB08}
send TACTIC:DEPLOY:CREATE -owner A15 -g FG15 -text1 ALL -int1 {} -nlist {NB09 NB10}
send TACTIC:DEPLOY:CREATE -owner A16 -g FG16 -text1 ALL -int1 {} -nlist {NB11 NB12}
send TACTIC:DEPLOY:CREATE -owner A17 -g FG17 -text1 ALL -int1 {} -nlist {NB13 NB14}
send TACTIC:DEPLOY:CREATE -owner A18 -g FG18 -text1 ALL -int1 {} -nlist {NB15 NB16}
send TACTIC:DEPLOY:CREATE -owner A19 -g FG19 -text1 ALL -int1 {} -nlist {NB17 NB18}
send TACTIC:DEPLOY:CREATE -owner A20 -g FG20 -text1 ALL -int1 {} -nlist {NB19 NB20}
send FRCGROUP:UPDATE -g FG03 -longname FG03 -a A03 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG04 -longname FG04 -a A04 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG05 -longname FG05 -a A05 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG05 -longname FG05 -a A05 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG06 -longname FG06 -a A06 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG07 -longname FG07 -a A07 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG08 -longname FG08 -a A08 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG09 -longname FG09 -a A09 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG10 -longname FG10 -a A10 -color #3B61FF -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 1 -local 0
send FRCGROUP:UPDATE -g FG11 -longname FG11 -a A11 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG12 -longname FG12 -a A12 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG13 -longname FG13 -a A13 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG14 -longname FG14 -a A14 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG15 -longname FG15 -a A15 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG16 -longname FG16 -a A16 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG17 -longname FG17 -a A17 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG18 -longname FG18 -a A18 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG19 -longname FG19 -a A19 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send FRCGROUP:UPDATE -g FG20 -longname FG20 -a A20 -color #FF0000 -shape NEUTRAL -forcetype REGULAR -training FULL -base_personnel 1000 -demeanor AVERAGE -cost 100.00 -attack_cost 100.00 -uniformed 0 -local 1
send PARM:SET -parm econ.disable -value yes
send PARM:SET -parm econ.disable -value no
send PARM:SET -parm econ.disable -value yes
send CAP:CREATE -k CAP01 -owner A01 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08}
send CAP:CREATE -k CAP02 -owner A02 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15}
send CAP:CREATE -k CAP03 -owner A03 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17}
send CAP:CREATE -k CAP04 -owner A04 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21}
send CAP:CREATE -k CAP05 -owner A05 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24}
send CAP:CREATE -k CAP06 -owner A06 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27}
send CAP:CREATE -k CAP07 -owner A07 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33}
send CAP:CREATE -k CAP08 -owner A08 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38}
send CAP:CREATE -k CAP09 -owner A09 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43}
send CAP:CREATE -k CAP10 -owner A10 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49}
send CAP:CREATE -k CAP11 -owner A11 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53}
send CAP:CREATE -k CAP12 -owner A12 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57}
send CAP:CREATE -k CAP13 -owner A13 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57 CG58 CG59 CG60}
send CAP:CREATE -k CAP14 -owner A14 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57 CG58 CG59 CG60}
send CAP:CREATE -k CAP15 -owner A15 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57 CG58 CG59 CG60}
send CAP:CREATE -k CAP16 -owner A16 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57 CG58 CG59 CG60}
send CAP:CREATE -k CAP17 -owner A17 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57 CG58 CG59 CG60}
send CAP:CREATE -k CAP18 -owner A18 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57 CG58 CG59 CG60}
send CAP:CREATE -k CAP19 -owner A19 -capacity 1.00 -nlist {NB01 NB02 NB03 NB04 NB05 NB06 NB07 NB08 NB09 NB10 NB11 NB12 NB13 NB14 NB15 NB16 NB17 NB18 NB19 NB20} -glist {CG01 CG02 CG03 CG04 CG05 CG06 CG07 CG08 CG09 CG10 CG11 CG12 CG13 CG14 CG15 CG16 CG17 CG18 CG19 CG20 CG21 CG22 CG23 CG24 CG25 CG26 CG27 CG28 CG29 CG30 CG31 CG32 CG33 CG34 CG35 CG36 CG37 CG38 CG39 CG40 CG41 CG42 CG43 CG44 CG45 CG46 CG47 CG48 CG49 CG50 CG51 CG52 CG53 CG54 CG55 CG56 CG57 CG58 CG59 CG60}
send CAP:CREATE -k CAP20 -owner A20 -capacity 1.00 -nlist NB01 -glist {CG01 CG02 CG03}
send HOOK:CREATE -hook_id H01
send HOOK:CREATE -hook_id H02
send HOOK:CREATE -hook_id H03
send HOOK:CREATE -hook_id H04
send HOOK:CREATE -hook_id H05
send HOOK:CREATE -hook_id H06
send HOOK:CREATE -hook_id H07
send HOOK:CREATE -hook_id H08
send HOOK:CREATE -hook_id H09
send HOOK:CREATE -hook_id H10
send HOOK:CREATE -hook_id H11
send HOOK:CREATE -hook_id H12
send HOOK:CREATE -hook_id H13
send HOOK:CREATE -hook_id H14
send HOOK:CREATE -hook_id H15
send HOOK:CREATE -hook_id H16
send HOOK:CREATE -hook_id H17
send HOOK:CREATE -hook_id H18
send HOOK:CREATE -hook_id H19
send HOOK:CREATE -hook_id H20
send BSYSTEM:TOPIC:CREATE -tid T01 -title Topic01
send HOOK:TOPIC:CREATE -hook_id H01 -topic_id T01 -position P+
send HOOK:TOPIC:CREATE -hook_id H02 -topic_id T01 -position P-
send BSYSTEM:TOPIC:CREATE -tid T02 -title Topic02
send BSYSTEM:TOPIC:CREATE -tid T03 -title Topic03
send BSYSTEM:TOPIC:CREATE -tid T04 -title Topic04
send BSYSTEM:TOPIC:CREATE -tid T05 -title Topic05
send BSYSTEM:TOPIC:CREATE -tid T06 -title Topic06
send BSYSTEM:TOPIC:CREATE -tid T07 -title Topic07
send BSYSTEM:TOPIC:CREATE -tid T08 -title Topic08
send BSYSTEM:TOPIC:CREATE -tid T09 -title Topic09
send BSYSTEM:TOPIC:CREATE -tid T10 -title Topic10
send HOOK:TOPIC:CREATE -hook_id H03 -topic_id T02 -position P+
send HOOK:TOPIC:CREATE -hook_id H04 -topic_id T02 -position P-
send HOOK:TOPIC:CREATE -hook_id H05 -topic_id T03 -position P+
send HOOK:TOPIC:CREATE -hook_id H06 -topic_id T03 -position P-
send HOOK:TOPIC:CREATE -hook_id H07 -topic_id T04 -position P+
send HOOK:TOPIC:CREATE -hook_id H08 -topic_id T04 -position P-
send HOOK:TOPIC:CREATE -hook_id H09 -topic_id T05 -position P+
send HOOK:TOPIC:CREATE -hook_id H10 -topic_id T05 -position P-
send HOOK:TOPIC:CREATE -hook_id H11 -topic_id T06 -position P+
send HOOK:TOPIC:CREATE -hook_id H12 -topic_id T06 -position P-
send HOOK:TOPIC:CREATE -hook_id H13 -topic_id T07 -position P+
send HOOK:TOPIC:CREATE -hook_id H14 -topic_id T07 -position P-
send HOOK:TOPIC:CREATE -hook_id H15 -topic_id T08 -position P+
send HOOK:TOPIC:CREATE -hook_id H16 -topic_id T08 -position P-
send HOOK:TOPIC:CREATE -hook_id H17 -topic_id T09 -position P+
send HOOK:TOPIC:CREATE -hook_id H18 -topic_id T09 -position P-
send HOOK:TOPIC:CREATE -hook_id H19 -topic_id T10 -position P+
send HOOK:TOPIC:CREATE -hook_id H20 -topic_id T10 -position P-
send IOM:CREATE -iom_id M01 -hook_id H01
send IOM:CREATE -iom_id M02 -hook_id H02
send IOM:CREATE -iom_id M03 -hook_id H03
send IOM:CREATE -iom_id M04 -hook_id H04
send IOM:CREATE -iom_id M05 -hook_id H05
send IOM:CREATE -iom_id M06 -hook_id H06
send IOM:CREATE -iom_id M07 -hook_id H07
send IOM:CREATE -iom_id M08 -hook_id H08
send IOM:CREATE -iom_id M09 -hook_id H09
send IOM:CREATE -iom_id M10 -hook_id H10
send IOM:CREATE -iom_id M11 -hook_id H11
send IOM:CREATE -iom_id M12 -hook_id H12
send IOM:CREATE -iom_id M13 -hook_id H13
send IOM:CREATE -iom_id M14 -hook_id H14
send IOM:CREATE -iom_id M15 -hook_id H15
send IOM:CREATE -iom_id M16 -hook_id H16
send IOM:CREATE -iom_id M17 -hook_id H17
send IOM:CREATE -iom_id M18 -hook_id H18
send IOM:CREATE -iom_id M19 -hook_id H19
send IOM:CREATE -iom_id M20 -hook_id H20
send PAYLOAD:SAT:CREATE -iom_id M01 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M01 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M02 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M02 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M03 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M03 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M04 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M04 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M05 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M05 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M06 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M06 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M07 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M07 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M08 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M08 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M09 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M09 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M10 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M10 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M11 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M11 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M12 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M12 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M13 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M13 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M14 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M14 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M15 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M15 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M16 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M16 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M17 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M17 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M18 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M18 -c SFT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M19 -c AUT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M19 -c SFT -mag 7.5
send PAYLOAD:SAT:CREATE -iom_id M20 -c AUT -mag -7.5
send PAYLOAD:SAT:CREATE -iom_id M20 -c SFT -mag -7.5
send PAYLOAD:VREL:CREATE -iom_id M01 -a A01 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M02 -a A02 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M03 -a A03 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M04 -a A04 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M05 -a A05 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M06 -a A06 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M07 -a A07 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M08 -a A08 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M09 -a A09 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M10 -a A10 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M11 -a A11 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M12 -a A12 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M13 -a A13 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M14 -a A12 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M15 -a A15 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M16 -a A16 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M17 -a A17 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M18 -a A18 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M19 -a A19 -mag 10.0
send PAYLOAD:VREL:CREATE -iom_id M20 -a A20 -mag 10.0
send TACTIC:BROADCAST:CREATE -owner A01 -cap CAP01 -iom M01 -x1 0
send TACTIC:BROADCAST:CREATE -owner A02 -cap CAP02 -iom M02 -x1 0
send TACTIC:BROADCAST:CREATE -owner A03 -cap CAP03 -iom M03 -x1 0
send TACTIC:BROADCAST:CREATE -owner A04 -cap CAP04 -iom M04 -x1 0
send TACTIC:BROADCAST:CREATE -owner A05 -cap CAP05 -iom M05 -x1 0
send TACTIC:BROADCAST:CREATE -owner A06 -cap CAP06 -iom M06 -x1 0
send TACTIC:BROADCAST:CREATE -owner A07 -cap CAP07 -iom M07 -x1 0
send TACTIC:BROADCAST:CREATE -owner A08 -cap CAP08 -iom M08 -x1 0
send TACTIC:BROADCAST:CREATE -owner A09 -cap CAP09 -iom M09 -x1 0
send TACTIC:BROADCAST:CREATE -owner A10 -cap CAP10 -iom M10 -x1 0
send TACTIC:BROADCAST:CREATE -owner A11 -cap CAP11 -iom M11 -x1 0
send TACTIC:BROADCAST:CREATE -owner A12 -cap CAP12 -iom M12 -x1 0
send TACTIC:BROADCAST:CREATE -owner A13 -cap CAP13 -iom M13 -x1 0
send TACTIC:BROADCAST:CREATE -owner A14 -cap CAP14 -iom M14 -x1 0
send TACTIC:BROADCAST:CREATE -owner A15 -cap CAP15 -iom M15 -x1 0
send TACTIC:BROADCAST:CREATE -owner A16 -cap CAP16 -iom M16 -x1 0
send TACTIC:BROADCAST:CREATE -owner A17 -cap CAP17 -iom M17 -x1 0
send TACTIC:BROADCAST:CREATE -owner A18 -cap CAP18 -iom M18 -x1 0
send TACTIC:BROADCAST:CREATE -owner A19 -cap CAP19 -iom M19 -x1 0
send TACTIC:BROADCAST:CREATE -owner A20 -cap CAP20 -iom M20 -x1 0
send BSYSTEM:BELIEF:UPDATE -id {A01 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A01 T03} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T04} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T05} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T06} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T07} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T08} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T09} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T10} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A01 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A01 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T04} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T05} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T08} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T09} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A02 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A02 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T05} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T07} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T08} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T10} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A03 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A03 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T04} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T05} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T06} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T07} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T08} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T09} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A04 T10} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A04 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A04 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A05 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A05 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T06} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T07} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T08} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T09} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T10} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A05 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A05 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T04} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T06} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T07} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T08} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T09} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T10} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A06 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A06 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A07 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T03} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T04} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T05} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T06} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T07} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T08} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T09} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T10} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A07 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A07 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T04} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T05} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T08} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T09} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A08 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A08 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A09 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T05} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T07} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T08} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A09 T10} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A09 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A09 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T04} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T05} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T06} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T07} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T08} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T09} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T10} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A10 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A10 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A10 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A11 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T04} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T06} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T07} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T08} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T09} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T10} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A11 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A11 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A11 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T04} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T06} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T07} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T08} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T09} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T10} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A12 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A12 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A13 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A13 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A14 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A14 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A14 T03} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A14 T04} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A14 T05} -position P+
send BSYSTEM:BELIEF:UPDATE -id {A14 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A14 T07} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A14 T08} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A14 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A14 T10} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A14 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A14 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A14 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A15 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A15 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A15 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A15 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A15 T05} -position S+
send BSYSTEM:BELIEF:UPDATE -id {A15 T06} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A15 T07} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A15 T08} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A15 T09} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A15 T10} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A15 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A15 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A15 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A16 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A16 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A16 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A16 T04} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A16 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A16 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A17 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A17 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A17 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A17 T04} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A17 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A17 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A17 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A18 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {A18 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A18 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A18 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A18 T04} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A18 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A18 T06} -position W-
send BSYSTEM:BELIEF:UPDATE -id {A18 T07} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A18 T08} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A18 T09} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A18 T10} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A18 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A18 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {A19 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A19 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A19 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A19 T04} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A19 T05} -position S-
send BSYSTEM:BELIEF:UPDATE -id {A19 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A19 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A19 T08} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A19 T09} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A19 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {A19 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A19 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {A20 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {A20 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG01 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T03} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T04} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T05} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T06} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T07} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T08} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T09} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T10} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG01 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG01 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T05} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T07} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T08} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T10} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG02 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG02 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG03 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T04} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T06} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T07} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T08} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T09} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T10} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG03 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG03 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T04} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T06} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T07} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T08} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T10} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG05 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG05 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG06 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T04} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T05} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T07} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T08} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T09} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T10} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG06 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG06 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T04} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T05} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T08} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T09} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG07 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG07 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG07 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG08 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG08 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T05} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG08 T08} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T10} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG08 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG08 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG08 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG08 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG08 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG08 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG08 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG08 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG08 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG08 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG09 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG09 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG09 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG09 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG09 T07} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG09 T08} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG09 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG09 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG09 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG09 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG09 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG09 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG09 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG09 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG09 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG10 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T04} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T06} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T07} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T08} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T09} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T10} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG10 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG10 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG10 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG10 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG10 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG10 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG10 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG10 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG11 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG11 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG11 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG11 T04} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG11 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG11 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG11 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG11 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG11 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG11 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG12 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T04} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T05} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T06} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T07} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T08} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T09} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T10} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG12 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG12 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T04} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T05} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T08} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T09} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG13 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG13 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG14 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T04} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T05} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T08} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T09} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG14 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG14 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG14 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG14 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG14 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG14 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG14 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG14 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG14 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG14 T10} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG15 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T04} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T06} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T07} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T08} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG15 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG15 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG15 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG15 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG15 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG15 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG15 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG15 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG15 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG15 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG16 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG16 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG16 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG16 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG16 T06} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG16 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG16 T08} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG16 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG16 T10} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG16 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG16 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG16 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG16 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG16 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG16 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG16 T08} -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG16 T10} -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG17 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG17 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG17 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG17 T04} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG17 T05} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG17 T06} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG17 T07} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG17 T08} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG17 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG17 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG17 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG17 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG17 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG17 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG17 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG17 T08} -emphasis ASTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG17 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG18 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG18 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG18 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG18 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG18 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG18 T07} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG18 T08} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG18 T09} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG18 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG18 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG18 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG18 T04} -emphasis AWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG18 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG18 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG18 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG18 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG18 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG18 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG19 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T04} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T05} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T06} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T07} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T10} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG19 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG19 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG19 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG19 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG19 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG19 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG19 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG19 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG19 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG20 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T04} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T05} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T08} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T09} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG20 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG20 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG20 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG20 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG20 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG20 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG20 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG20 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG20 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG20 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG21 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T03} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T04} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T05} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T07} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T08} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T09} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T10} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG21 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG21 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG21 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG21 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG21 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG21 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG21 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG21 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG21 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG21 T10} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG22 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T04} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T05} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T06} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T07} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T08} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T09} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T10} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG22 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG22 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG22 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG22 T04} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG22 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG22 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG22 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG22 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG22 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG23 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG23 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG23 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG23 T07} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG23 T09} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG23 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG23 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG23 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG23 T05} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG23 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG23 T08} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG23 T09} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG23 T10} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG24 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG24 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG24 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG24 T07} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG24 T09} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG24 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG24 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG24 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG24 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG24 T05} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG24 T06} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG24 T07} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG24 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG25 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG25 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG25 T04} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG25 T06} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG25 T05} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG25 T08} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG25 T10} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG25 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG25 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG25 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG25 T04} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG25 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG25 T06} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG25 T07} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG25 T08} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG25 T09} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG27 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T04} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T05} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T06} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T07} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T08} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T09} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T10} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG27 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T04} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T05} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T06} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T07} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T08} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T09} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG27 T10} -emphasis DEXTREME
send BSYSTEM:PLAYBOX:UPDATE -gamma 0.5
send BSYSTEM:TOPIC:DELETE -tid T10
send BSYSTEM:TOPIC:DELETE -tid T09
send BSYSTEM:TOPIC:DELETE -tid T08
send BSYSTEM:TOPIC:DELETE -tid T07
send BSYSTEM:TOPIC:DELETE -tid T06
send BSYSTEM:TOPIC:DELETE -tid T05
send BSYSTEM:TOPIC:DELETE -tid T04
send HOOK:DELETE -hook_id H07
send HOOK:DELETE -hook_id H08
send HOOK:DELETE -hook_id H09
send HOOK:DELETE -hook_id H10
send HOOK:DELETE -hook_id H11
send HOOK:DELETE -hook_id H12
send HOOK:DELETE -hook_id H13
send HOOK:DELETE -hook_id H14
send HOOK:DELETE -hook_id H15
send HOOK:DELETE -hook_id H16
send HOOK:DELETE -hook_id H17
send HOOK:DELETE -hook_id H18
send HOOK:DELETE -hook_id H19
send HOOK:DELETE -hook_id H20
send IOM:UPDATE -iom_id M08 -longname M08 -hook_id H01
send IOM:UPDATE -iom_id M09 -longname M09 -hook_id H02
send IOM:UPDATE -iom_id M10 -longname M10 -hook_id H03
send IOM:UPDATE -iom_id M11 -longname M11 -hook_id H04
send IOM:UPDATE -iom_id M12 -longname M12 -hook_id H05
send IOM:UPDATE -iom_id M13 -longname M13 -hook_id H06
send IOM:UPDATE -iom_id M14 -longname M14 -hook_id H01
send IOM:UPDATE -iom_id M15 -longname M15 -hook_id H02
send IOM:UPDATE -iom_id M16 -longname M16 -hook_id H03
send IOM:UPDATE -iom_id M17 -longname M17 -hook_id H04
send IOM:UPDATE -iom_id M18 -longname M18 -hook_id H05
send IOM:UPDATE -iom_id M19 -longname M19 -hook_id H06
send IOM:UPDATE -iom_id M20 -longname M20 -hook_id H01
send IOM:UPDATE -iom_id M07 -longname M07 -hook_id H02
send BSYSTEM:BELIEF:UPDATE -id {CG29 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG29 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG29 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG29 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG29 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG29 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG30 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG30 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG30 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG30 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG30 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG30 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG31 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG31 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG31 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG31 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG31 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG31 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG32 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG32 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG32 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG32 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG33 T01} -position W-
send BSYSTEM:PLAYBOX:UPDATE -gamma 0.0
send BSYSTEM:PLAYBOX:UPDATE -gamma 0.4
send BSYSTEM:PLAYBOX:UPDATE -gamma 0.5
send BSYSTEM:BELIEF:UPDATE -id {CG34 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG34 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG34 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG34 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG34 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG34 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG35 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG35 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG35 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG35 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG35 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG35 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG36 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG36 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG36 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG36 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG36 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG36 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG37 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG37 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG37 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG37 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG37 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG37 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG38 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG38 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG38 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG38 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG38 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG38 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG39 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG39 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG39 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG39 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG39 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG39 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG39 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG40 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG40 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG40 T03} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG40 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG40 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG40 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG41 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG41 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG41 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG41 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG41 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG41 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG42 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG42 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG42 T03} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG42 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG42 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG42 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG43 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG43 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG43 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG43 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG44 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG44 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG44 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG44 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG44 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG44 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG45 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG45 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG45 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG45 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG45 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG45 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG46 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG46 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG46 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG46 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG46 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG46 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG47 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG47 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG47 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG47 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG47 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG47 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG48 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG48 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG48 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG48 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG48 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG48 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG49 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG49 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG49 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG49 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG49 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG49 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG50 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG50 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG50 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG50 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG50 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG50 T03} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG51 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG51 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG51 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG51 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG51 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG51 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG52 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG52 T02} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG52 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG52 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG52 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG52 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG53 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG53 T02} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG53 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG54 T01} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG54 T02} -position P+
send BSYSTEM:BELIEF:UPDATE -id {CG54 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG54 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG54 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG54 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG55 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG55 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG55 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG55 T01} -emphasis DWEAK
send BSYSTEM:BELIEF:UPDATE -id {CG55 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG55 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG56 T01} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG56 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG56 T03} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG56 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG56 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG56 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG57 T01} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG57 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG57 T03} -position S-
send BSYSTEM:BELIEF:UPDATE -id {CG57 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG57 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG57 T03} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG57 T02} -position W-
send BSYSTEM:BELIEF:UPDATE -id {CG58 T01} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG58 T02} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG58 T03} -position W+
send BSYSTEM:BELIEF:UPDATE -id {CG58 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG58 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG58 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG59 T01} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG59 T02} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG59 T03} -position S+
send BSYSTEM:BELIEF:UPDATE -id {CG59 T01} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG59 T02} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG59 T03} -emphasis DSTRONG
send BSYSTEM:BELIEF:UPDATE -id {CG60 T01} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG60 T02} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG60 T03} -position P-
send BSYSTEM:BELIEF:UPDATE -id {CG60 T01} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG60 T02} -emphasis DEXTREME
send BSYSTEM:BELIEF:UPDATE -id {CG60 T03} -emphasis DEXTREME
