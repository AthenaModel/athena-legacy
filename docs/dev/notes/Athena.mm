<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237475113960" ID="Freemind_Link_868839690" MODIFIED="1237475134049" TEXT="Athena">
<node CREATED="1243527457709" ID="Freemind_Link_320906598" MODIFIED="1243527459755" POSITION="right" TEXT="Problems">
<node CREATED="1243527460189" ID="Freemind_Link_1011323624" MODIFIED="1243527474567" TEXT="Moving from snapshot to snapshot can be very slow"/>
</node>
<node CREATED="1237477449934" ID="Freemind_Link_919437009" MODIFIED="1237477452594" POSITION="right" TEXT="Simulation">
<node CREATED="1241624415166" FOLDED="true" ID="Freemind_Link_472031065" MODIFIED="1245882365270" TEXT="Displaced Civilians/Refugees">
<icon BUILTIN="full-1"/>
<node CREATED="1241624443469" ID="Freemind_Link_1269891450" MODIFIED="1245882297155" TEXT="Model refugees as civilian units with activity DISPLACED">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1243619917252" ID="Freemind_Link_1143793780" MODIFIED="1243619933292" TEXT="Effect on local civilians">
<node CREATED="1243619934178" ID="Freemind_Link_1928827775" MODIFIED="1245882301518" TEXT="Compute DISPLACED coverage"/>
<node CREATED="1243619945650" ID="Freemind_Link_1438494628" MODIFIED="1245882309925" TEXT="DISPLACED rule set">
<node CREATED="1241624467661" ID="Freemind_Link_1826431892" MODIFIED="1245882321256" TEXT="Local civilians respond to presence of DISPLACED units."/>
</node>
<node CREATED="1243627017794" ID="Freemind_Link_1047647382" MODIFIED="1243627027315" TEXT="Does neighborhood of origin actually matter?">
<node CREATED="1245882324928" ID="Freemind_Link_1740107134" MODIFIED="1245882328907" TEXT="No."/>
<node CREATED="1243627028259" ID="Freemind_Link_884907885" MODIFIED="1243627043853" TEXT="We don&apos;t have ngmf relationships."/>
</node>
</node>
<node CREATED="1243619978962" ID="Freemind_Link_1190169675" MODIFIED="1243620008101" TEXT="Ignore effect on civilians &quot;back home&quot;">
<node CREATED="1243620008802" ID="Freemind_Link_1698042443" MODIFIED="1243620084553" TEXT="A neighborhood group that generates refugees&#xa;generates them because it is already unhappy.&#xa;It probably doesn&apos;t become more so because&#xa;it has produced refugees."/>
<node CREATED="1245882338641" ID="Freemind_Link_1254223972" MODIFIED="1245882351069" TEXT="Plus, they might not know what&apos;s become of the refugees anyway."/>
</node>
</node>
<node CREATED="1238449599668" ID="Freemind_Link_228057198" MODIFIED="1245882375350" TEXT="Magic satisfaction inputs and adjustments">
<icon BUILTIN="full-2"/>
</node>
<node CREATED="1238449608020" ID="Freemind_Link_1639950112" MODIFIED="1245882379478" TEXT="Magic cooperation inputs and adjustments">
<icon BUILTIN="full-2"/>
</node>
<node CREATED="1243027998597" ID="Freemind_Link_1993004622" MODIFIED="1245882390862" TEXT="ORG active/inactive flag">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1243028014804" ID="Freemind_Link_290938405" MODIFIED="1243028020317" TEXT="Set as in JOUT rules"/>
<node CREATED="1243028020644" ID="Freemind_Link_82333428" MODIFIED="1243028030814" TEXT="Used in analysis of ORG activities"/>
</node>
<node CREATED="1237822733720" FOLDED="true" ID="Freemind_Link_1356652575" MODIFIED="1245882394142" TEXT="Reactive Decision Conditions">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237822742521" ID="Freemind_Link_656806568" MODIFIED="1237822753602" TEXT="Check RDCs at end of each tick"/>
<node CREATED="1237822754248" ID="Freemind_Link_1244752831" MODIFIED="1237822768786" TEXT="Simplest: pause simulation if RDC is met"/>
<node CREATED="1241531400361" ID="Freemind_Link_288992448" MODIFIED="1241531402236" TEXT="Parts">
<node CREATED="1241530211430" ID="Freemind_Link_1465150393" MODIFIED="1241530232389" TEXT="Condition">
<node CREATED="1241530371924" ID="Freemind_Link_1930782461" MODIFIED="1241530407559" TEXT="SQL-based conditions"/>
<node CREATED="1241530408716" ID="Freemind_Link_1613374353" MODIFIED="1241530466016" TEXT="GUI interface on top of that"/>
</node>
<node CREATED="1241530227624" ID="Freemind_Link_616423081" MODIFIED="1241530236851" TEXT="Action">
<node CREATED="1241530237670" ID="Freemind_Link_76436217" MODIFIED="1241530240114" TEXT="An order"/>
<node CREATED="1241530240430" ID="Freemind_Link_349576284" MODIFIED="1241530260946" TEXT="Initially, a parm-less order">
<node CREATED="1241530247438" ID="Freemind_Link_541185666" MODIFIED="1241530288365" TEXT="SIM:PAUSE"/>
</node>
</node>
</node>
<node CREATED="1241530475828" ID="Freemind_Link_1124585185" MODIFIED="1241530483160" TEXT="Scheduled orders are handled separately"/>
<node CREATED="1241531450249" ID="Freemind_Link_1973532751" MODIFIED="1241531454405" TEXT="Kinds of conditions">
<node CREATED="1241531454856" ID="Freemind_Link_1297130317" MODIFIED="1241531547972" TEXT="Level of attrition">
<node CREATED="1241531550337" ID="Freemind_Link_1352513347" MODIFIED="1241531554380" TEXT="To a nbhood group"/>
<node CREATED="1241531554728" ID="Freemind_Link_1753806039" MODIFIED="1241531559221" TEXT="To a force/ORG group"/>
<node CREATED="1241531471496" ID="Freemind_Link_687695655" MODIFIED="1241531474956" TEXT="In a neighborhood"/>
<node CREATED="1241531475320" ID="Freemind_Link_1374724522" MODIFIED="1241531485028" TEXT="Across the playbox"/>
</node>
<node CREATED="1241531486161" ID="Freemind_Link_1669522905" MODIFIED="1241531515525" TEXT="Decline in civilian population">
<node CREATED="1241531515936" ID="Freemind_Link_618610016" MODIFIED="1241531525412" TEXT="Of a nbhood group"/>
<node CREATED="1241531525896" ID="Freemind_Link_972695167" MODIFIED="1241531527996" TEXT="Of a nbhood"/>
<node CREATED="1241531528352" ID="Freemind_Link_1028715699" MODIFIED="1241531533185" TEXT="Of the playbox"/>
</node>
</node>
</node>
<node CREATED="1237568034086" FOLDED="true" ID="Freemind_Link_1406761834" MODIFIED="1237568069787" TEXT="Game truth variables">
<icon BUILTIN="help"/>
<node CREATED="1237568050726" ID="Freemind_Link_454367740" MODIFIED="1237568062559" TEXT="Like gtclient/gtserver, but within one app"/>
</node>
</node>
<node CREATED="1239210064249" ID="Freemind_Link_1216819379" MODIFIED="1239210065909" POSITION="right" TEXT="GRAM">
<node CREATED="1241215740273" ID="Freemind_Link_1519643380" MODIFIED="1245882867110" TEXT="Speed up gram_value update on cancel">
<icon BUILTIN="full-3"/>
</node>
<node CREATED="1241215792272" ID="Freemind_Link_1746105883" MODIFIED="1245882867112" TEXT="Grab acontrib assignment speed up from JRAM">
<icon BUILTIN="full-3"/>
</node>
<node CREATED="1245882571968" ID="Freemind_Link_1418176995" MODIFIED="1245882875317" TEXT="GRAM dump executive commands">
<icon BUILTIN="full-4"/>
</node>
<node CREATED="1241215767617" ID="Freemind_Link_1703805627" MODIFIED="1241215779674" TEXT="Accumulate acontrib directly into gram_contribs">
<node CREATED="1241215785360" ID="Freemind_Link_276110028" MODIFIED="1241215789775" TEXT="If it&apos;s faster to do so."/>
</node>
<node CREATED="1241215865953" ID="Freemind_Link_731499049" MODIFIED="1241215878509" TEXT="More epsilons?">
<node CREATED="1241215878848" ID="Freemind_Link_957640958" MODIFIED="1241215882778" TEXT="Level vs. Slope"/>
<node CREATED="1241215883249" ID="Freemind_Link_1735758744" MODIFIED="1241215886122" TEXT="Sat vs Coop"/>
</node>
<node CREATED="1247762885741" ID="Freemind_Link_1952865263" MODIFIED="1247762891249" TEXT="Smaller epsilons?"/>
<node CREATED="1239210066312" ID="Freemind_Link_854754922" MODIFIED="1247762787319" TEXT="Slope effect thresholds">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1239210082792" ID="Freemind_Link_319482527" MODIFIED="1247762797557" TEXT="Threshold other than +/- 100"/>
<node CREATED="1239210116617" ID="Freemind_Link_94705808" MODIFIED="1247762812375" TEXT="Effect does not contribute if level exceeds threshold"/>
<node CREATED="1247762822989" ID="Freemind_Link_1630695005" MODIFIED="1247762846166" TEXT="Effects do NOT scale to threshold">
<font BOLD="true" NAME="SansSerif" SIZE="12"/>
</node>
<node CREATED="1239210138568" ID="Freemind_Link_1017855387" MODIFIED="1239210156149" TEXT="Tendency to some value, say 0">
<node CREATED="1239210156872" ID="Freemind_Link_1635068076" MODIFIED="1239210189954" TEXT="Slope increasing to 0.0"/>
<node CREATED="1239210174983" ID="Freemind_Link_1430976267" MODIFIED="1239210183954" TEXT="Slope decreasing to 0.0"/>
</node>
</node>
<node CREATED="1239210066312" ID="Freemind_Link_1735127823" MODIFIED="1247762875474" TEXT="Slope effect bounds">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1247762862700" ID="Freemind_Link_339710939" MODIFIED="1247762878379" TEXT="Slope effect thresholds are preferred in the short run">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1239210082792" ID="Freemind_Link_21995878" MODIFIED="1239210115298" TEXT="Effect scales to bound other than +/- 100"/>
<node CREATED="1239210116617" ID="Freemind_Link_16044741" MODIFIED="1239210129458" TEXT="Effect is ignored if level exceeds bound"/>
<node CREATED="1239210138568" FOLDED="true" ID="Freemind_Link_1350980017" MODIFIED="1239210156149" TEXT="Tendency to some value, say 0">
<node CREATED="1239210156872" ID="Freemind_Link_196779551" MODIFIED="1239210189954" TEXT="Slope increasing to 0.0"/>
<node CREATED="1239210174983" ID="Freemind_Link_1653086417" MODIFIED="1239210183954" TEXT="Slope decreasing to 0.0"/>
</node>
<node CREATED="1239210193352" FOLDED="true" ID="Freemind_Link_737991295" MODIFIED="1239210210642" TEXT="Aggregating effects over causes is difficult">
<node CREATED="1239210212168" ID="Freemind_Link_29733535" MODIFIED="1239210224625" TEXT="Could associate each cause with a positive bound and a negative bound"/>
<node CREATED="1239210225832" FOLDED="true" ID="Freemind_Link_998066155" MODIFIED="1239210234770" TEXT="Don&apos;t really like that.">
<node CREATED="1239210241848" ID="Freemind_Link_1507885005" MODIFIED="1239210255954" TEXT="Some things are more important than others, even within the same cause."/>
</node>
</node>
</node>
<node CREATED="1241216187039" ID="Freemind_Link_490314084" MODIFIED="1245882428662" TEXT="Compute driver &quot;reach&quot; statistics">
<icon BUILTIN="messagebox_warning"/>
</node>
</node>
<node CREATED="1237475139158" ID="_" MODIFIED="1237477117490" POSITION="right" TEXT="Order">
<node CREATED="1237480217386" ID="Freemind_Link_96571795" MODIFIED="1245882444750" TEXT="Dump order history as script">
<arrowlink DESTINATION="Freemind_Link_860046120" ENDARROW="Default" ENDINCLINATION="75;0;" ID="Freemind_Arrow_Link_966523914" STARTARROW="None" STARTINCLINATION="75;0;"/>
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1238185877929" ID="Freemind_Link_1596050694" MODIFIED="1238185885379" TEXT="Need to know scripting format first"/>
</node>
<node CREATED="1237480209602" FOLDED="true" ID="Freemind_Link_860046120" MODIFIED="1245882447678" TEXT="Order scripting">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1238185910426" FOLDED="true" ID="Freemind_Link_1940884826" MODIFIED="1238185912932" TEXT="Uses">
<node CREATED="1238185655578" FOLDED="true" ID="Freemind_Link_136202823" MODIFIED="1238185664708" TEXT="Run script within existing scenario">
<node CREATED="1238185776810" ID="Freemind_Link_1966079268" MODIFIED="1238185799476" TEXT="Not intended to recreate previous run"/>
<node CREATED="1238185668699" FOLDED="true" ID="Freemind_Link_549143569" MODIFIED="1238185675908" TEXT="Ignore timestamps">
<node CREATED="1238185219419" FOLDED="true" ID="Freemind_Link_558616974" MODIFIED="1238185240359" TEXT="Run all orders now">
<node CREATED="1238185241979" ID="Freemind_Link_640319681" MODIFIED="1238185244309" TEXT="Log Failures"/>
<node CREATED="1238185244699" ID="Freemind_Link_118761070" MODIFIED="1238185248085" TEXT="Stop after first failure"/>
</node>
</node>
<node CREATED="1238185676299" FOLDED="true" ID="Freemind_Link_134673193" MODIFIED="1238185679892" TEXT="Honor timestamps">
<node CREATED="1238185710346" FOLDED="true" ID="Freemind_Link_1027973767" MODIFIED="1238185722580" TEXT="Options">
<node CREATED="1238185680442" ID="Freemind_Link_788668770" MODIFIED="1238185684564" TEXT="Without offset"/>
<node CREATED="1238185684922" ID="Freemind_Link_87005297" MODIFIED="1238185687028" TEXT="With offset"/>
</node>
<node CREATED="1238185730010" ID="Freemind_Link_984278862" MODIFIED="1238185747732" TEXT="Run orders timestamped now, now"/>
<node CREATED="1238185748137" ID="Freemind_Link_1818266246" MODIFIED="1238185755284" TEXT="Schedule other orders in eventq"/>
</node>
</node>
<node CREATED="1238185298203" FOLDED="true" ID="Freemind_Link_1182934650" MODIFIED="1238185380791" TEXT="Run up a CIF">
<node CREATED="1238185559819" ID="Freemind_Link_1475157012" MODIFIED="1238185568388" TEXT="Start with blank scenario"/>
<node CREATED="1238185570426" ID="Freemind_Link_521160338" MODIFIED="1238185575684" TEXT="Specify script on command-line"/>
<node CREATED="1238185381402" ID="Freemind_Link_1257379761" MODIFIED="1238185399188" TEXT="Run orders timestamped now, now"/>
<node CREATED="1238185399899" ID="Freemind_Link_513220195" MODIFIED="1238185448484" TEXT="Run later orders in Tick after everything else"/>
</node>
</node>
<node CREATED="1238185894985" ID="Freemind_Link_982239340" MODIFIED="1238185906771" TEXT="What do scripts look like?">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237480052010" ID="Freemind_Link_1129765376" MODIFIED="1245882452662" TEXT="Ability to validate orders without executing them">
<icon BUILTIN="full-3"/>
</node>
<node CREATED="1237480092962" FOLDED="true" ID="Freemind_Link_1722894145" MODIFIED="1245882456134" TEXT="Schedule orders ahead of time">
<arrowlink DESTINATION="Freemind_Link_1129765376" ENDARROW="Default" ENDINCLINATION="93;0;" ID="Freemind_Arrow_Link_906925163" STARTARROW="None" STARTINCLINATION="93;0;"/>
<icon BUILTIN="full-3"/>
<node CREATED="1237571826655" FOLDED="true" ID="Freemind_Link_358553126" MODIFIED="1237994632175" TEXT="&quot;order schedule&quot; command">
<node CREATED="1237571831262" ID="Freemind_Link_691473547" MODIFIED="1237571836200" TEXT="Schedules another order"/>
<node CREATED="1237994657557" FOLDED="true" ID="Freemind_Link_1225659272" MODIFIED="1237994673855" TEXT="CIF&apos;d as ORDER:SCHEDULE pseudo-order">
<node CREATED="1237571837118" ID="Freemind_Link_1205931009" MODIFIED="1237907725207" TEXT="No explicit dialog for this order"/>
<node CREATED="1237994680548" ID="Freemind_Link_1360872238" MODIFIED="1237994683823" TEXT="Can be undone"/>
</node>
<node CREATED="1237571868509" ID="Freemind_Link_351266681" MODIFIED="1237571875304" TEXT="Undone by cancelling scheduled order"/>
<node CREATED="1237482622421" FOLDED="true" ID="Freemind_Link_144828260" MODIFIED="1237482629632" TEXT="eventq">
<node CREATED="1237564183614" ID="Freemind_Link_1439004237" MODIFIED="1237564192023" TEXT="Event: scheduled order"/>
<node CREATED="1237482707941" ID="Freemind_Link_316875113" MODIFIED="1237482711247" TEXT="Queue browser"/>
<node CREATED="1237482851061" ID="Freemind_Link_1152163067" MODIFIED="1237482874725" TEXT="Event priorities?"/>
</node>
</node>
<node CREATED="1237571660719" FOLDED="true" ID="Freemind_Link_1311718344" MODIFIED="1237571813596" TEXT="Orders run by scheduled events" VSHIFT="-6">
<node CREATED="1237571721677" ID="Freemind_Link_402714946" MODIFIED="1237571728024" TEXT="Run by &quot;sim&quot;, not &quot;gui&quot;"/>
<node CREATED="1237571728750" ID="Freemind_Link_203596528" MODIFIED="1237571732296" TEXT="Not put in CIF"/>
<node CREATED="1237571732717" ID="Freemind_Link_739438388" MODIFIED="1237571735784" TEXT="Not undoable"/>
</node>
<node CREATED="1237994749045" FOLDED="true" ID="Freemind_Link_137028882" MODIFIED="1237994796554" TEXT="No SIM:SCHEDULE order">
<icon BUILTIN="flag"/>
<node CREATED="1237994759220" ID="Freemind_Link_884689448" MODIFIED="1237994787918" TEXT="&quot;order schedule&quot; must validate order states"/>
<node CREATED="1237994788501" ID="Freemind_Link_481627364" MODIFIED="1237994793104" TEXT="That&apos;s a framework issue."/>
</node>
</node>
<node CREATED="1237480262914" FOLDED="true" ID="Freemind_Link_325462962" MODIFIED="1245882463734" TEXT="Add *:MULTI orders as appropriate">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237480280162" ID="Freemind_Link_526459050" MODIFIED="1237480285749" TEXT="E.g., *:DELETE:MULTI"/>
</node>
<node CREATED="1241216212943" ID="Freemind_Link_1693598122" MODIFIED="1245882465846" TEXT="Test order return values">
<icon BUILTIN="messagebox_warning"/>
</node>
<node CREATED="1237481133242" ID="Freemind_Link_1851551577" MODIFIED="1243546073236" TEXT="Abstract order(sim) into order(n)">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237477120338" ID="Freemind_Link_191938982" MODIFIED="1243546063308" TEXT="Merge cif(sim) into order(sim) as &quot;order history&quot;">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237481099914" ID="Freemind_Link_1283162022" MODIFIED="1237481131391" TEXT="Abstract prepare/reject/returnOnError model for use in other code">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237477511538" ID="Freemind_Link_894463638" MODIFIED="1237477524514" POSITION="right" TEXT="Scenario">
<node CREATED="1243546243278" ID="Freemind_Link_1855932461" MODIFIED="1243546308604" TEXT="&quot;local&quot; flag should be on CIV and ORG groups as well">
<icon BUILTIN="help"/>
</node>
<node CREATED="1241547209100" ID="Freemind_Link_874223123" MODIFIED="1245882889854" TEXT="nbrel effects_delay">
<icon BUILTIN="full-4"/>
<node CREATED="1241547214268" ID="Freemind_Link_741184539" MODIFIED="1241547235353" TEXT="Athena allows effects_delay to be non-zero for HERE."/>
<node CREATED="1241547225964" ID="Freemind_Link_1772608855" MODIFIED="1243546140842" TEXT="GRAM assumes effects_delay is 0 for HERE."/>
<node CREATED="1243546142815" ID="Freemind_Link_1268107626" MODIFIED="1243546151992" TEXT="Require effects_delay to be 0.0 in Athena"/>
</node>
<node CREATED="1237477586106" ID="Freemind_Link_516563511" MODIFIED="1245882889856" TEXT="Require rel=1.0 when f=g">
<icon BUILTIN="full-4"/>
<node CREATED="1237477606906" ID="Freemind_Link_1462718131" MODIFIED="1243546199960" TEXT="Update the RELATIONSHIP:* orders and browser"/>
</node>
<node CREATED="1240255547518" FOLDED="true" ID="Freemind_Link_1642065644" MODIFIED="1245882889855" TEXT="parmdb(n): Allow changes to some parms while PAUSED, RUNNING">
<icon BUILTIN="full-4"/>
<node CREATED="1240255576590" ID="Freemind_Link_39749292" MODIFIED="1240255583784" TEXT="Some need to be locked."/>
<node CREATED="1240255585806" ID="Freemind_Link_654800573" MODIFIED="1240255589288" TEXT="Making sure locking works."/>
</node>
<node CREATED="1237480308963" ID="Freemind_Link_1212698036" MODIFIED="1245882899653" TEXT="Reciprocal flag in *:UPDATE">
<icon BUILTIN="full-5"/>
<node CREATED="1237480368626" ID="Freemind_Link_285045741" MODIFIED="1237480382381" TEXT="Sets same value for mn and nm, nfg and ngf"/>
<node CREATED="1237480331738" ID="Freemind_Link_1725501118" MODIFIED="1237480344757" TEXT="NBHOOD:RELATIONSHIP:UPDATE"/>
<node CREATED="1237480346154" ID="Freemind_Link_377220162" MODIFIED="1237480349469" TEXT="RELATIONSHIP:UPDATE"/>
</node>
<node CREATED="1237480977571" FOLDED="true" ID="Freemind_Link_590980119" MODIFIED="1245882506254" TEXT="MAP:EXPORT">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237480984002" ID="Freemind_Link_151089338" MODIFIED="1237480998630" TEXT="Exports the current map background as an image file"/>
</node>
<node CREATED="1241216225071" ID="Freemind_Link_1235588521" MODIFIED="1243459068126" TEXT="Naming conventions for scenario tables vs. model tables">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237482120338" FOLDED="true" ID="Freemind_Link_1183885189" MODIFIED="1238104926493" TEXT="Orders to rename entities">
<icon BUILTIN="help"/>
<node CREATED="1237482138802" ID="Freemind_Link_1495570394" MODIFIED="1237482143838" TEXT="Useful; can of worms."/>
</node>
</node>
<node CREATED="1243547508955" ID="Freemind_Link_1801589990" MODIFIED="1243547510924" POSITION="right" TEXT="Reports">
<node CREATED="1243547511644" ID="Freemind_Link_856756919" MODIFIED="1245882527534" TEXT="Scenario Report">
<icon BUILTIN="full-2"/>
<node CREATED="1243547523500" ID="Freemind_Link_241253623" MODIFIED="1243547529589" TEXT="Documents Scenario in detail"/>
<node CREATED="1243547530219" ID="Freemind_Link_1958129409" MODIFIED="1243547554469" TEXT="Possible not a report as such, but an HTML document like JNEM&apos;s dbdoc(n)"/>
</node>
<node CREATED="1243547558140" ID="Freemind_Link_1248382754" MODIFIED="1245882530670" TEXT="Contributions Report">
<icon BUILTIN="full-2"/>
<node CREATED="1243547565707" ID="Freemind_Link_1217705822" MODIFIED="1243547571125" TEXT="Like JNEM&apos;s satcurve report"/>
</node>
</node>
<node CREATED="1237479428630" ID="Freemind_Link_1070564721" MODIFIED="1237479469634" POSITION="right" TEXT="GUI">
<node CREATED="1239723521749" ID="Freemind_Link_1093494342" MODIFIED="1245882542782" TEXT="Save sim speed, duration as prefs">
<icon BUILTIN="messagebox_warning"/>
</node>
<node CREATED="1241215918369" ID="Freemind_Link_268023639" MODIFIED="1245882547118" TEXT="Stop button">
<icon BUILTIN="full-3"/>
<node CREATED="1241215931217" ID="Freemind_Link_1632396932" MODIFIED="1241215945706" TEXT="Enter time at tick 0"/>
<node CREATED="1243546337742" ID="Freemind_Link_1648827364" MODIFIED="1243546346296" TEXT="Fast: no need to save snapshot at time t"/>
</node>
<node CREATED="1241215894576" ID="Freemind_Link_1711563604" MODIFIED="1241215901322" TEXT="More GRAM browsers">
<node CREATED="1243546351758" ID="Freemind_Link_672128754" MODIFIED="1245882556366" TEXT="Drivers">
<icon BUILTIN="full-2"/>
</node>
<node CREATED="1243546354990" ID="Freemind_Link_53932115" MODIFIED="1245882560406" TEXT="Effects">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1243546374830" ID="Freemind_Link_1570233797" MODIFIED="1243546377470" TEXT="Sat">
<node CREATED="1243546377901" ID="Freemind_Link_754268158" MODIFIED="1243546379016" TEXT="Slope"/>
<node CREATED="1243546379581" ID="Freemind_Link_425307736" MODIFIED="1243546380951" TEXT="Level"/>
</node>
<node CREATED="1243546381965" ID="Freemind_Link_1985444991" MODIFIED="1243546383176" TEXT="Coop">
<node CREATED="1243546383614" ID="Freemind_Link_301164964" MODIFIED="1243546384759" TEXT="Slope"/>
<node CREATED="1243546385166" ID="Freemind_Link_978739363" MODIFIED="1243546386327" TEXT="Level"/>
</node>
</node>
</node>
<node CREATED="1238513070204" FOLDED="true" ID="Freemind_Link_66077028" MODIFIED="1245882910429" TEXT="Plot Tab">
<icon BUILTIN="full-4"/>
<node CREATED="1238513076429" ID="Freemind_Link_1251215369" MODIFIED="1238513086791" TEXT="Scrolling list of strip charts"/>
<node CREATED="1238513112382" FOLDED="true" ID="Freemind_Link_999492866" MODIFIED="1238513123384" TEXT="Time Series View">
<node CREATED="1238513123757" ID="Freemind_Link_474710164" MODIFIED="1238513127655" TEXT="SQL View"/>
<node CREATED="1238513128189" ID="Freemind_Link_1492949825" MODIFIED="1238513145479" TEXT="Columns: tick, value"/>
</node>
<node CREATED="1238513186078" FOLDED="true" ID="Freemind_Link_1267249555" MODIFIED="1238513191192" TEXT="viewfactory">
<node CREATED="1238513191869" ID="Freemind_Link_1269125596" MODIFIED="1238513237416" TEXT="Produces temporary time series views "/>
<node CREATED="1238513246284" FOLDED="true" ID="Freemind_Link_992877018" MODIFIED="1238513259719" TEXT="Examples:">
<node CREATED="1238513260109" ID="Freemind_Link_609283393" MODIFIED="1238513270071" TEXT="Satisfaction curve, n,g,c"/>
<node CREATED="1238513270718" ID="Freemind_Link_267874709" MODIFIED="1238513275175" TEXT="Satisfaction mood, n,g"/>
<node CREATED="1238513277725" ID="Freemind_Link_158106301" MODIFIED="1238513285303" TEXT="Cooperation level, n,f,g"/>
<node CREATED="1238513287789" ID="Freemind_Link_1112984383" MODIFIED="1238513291831" TEXT="Anything else we can think of"/>
</node>
</node>
<node CREATED="1238513306844" FOLDED="true" ID="Freemind_Link_1071430040" MODIFIED="1238513318408" TEXT="viewfactory dialog">
<node CREATED="1238513318845" ID="Freemind_Link_111701076" MODIFIED="1238513357287" TEXT="GUI to create a view given criteria"/>
<node CREATED="1238513340894" ID="Freemind_Link_1405768500" MODIFIED="1238513346167" TEXT="Like E-Mail rules GUI"/>
</node>
<node CREATED="1238513087837" FOLDED="true" ID="Freemind_Link_1527981066" MODIFIED="1238513111816" TEXT="View-based plot widget">
<node CREATED="1238513147901" ID="Freemind_Link_1318827185" MODIFIED="1238513179639" TEXT="Displays one or more time series views"/>
</node>
</node>
<node CREATED="1241216009376" ID="Freemind_Link_679327480" MODIFIED="1245882597310" TEXT="Splash screen/About box">
<icon BUILTIN="full-2"/>
</node>
<node CREATED="1237479490254" ID="Freemind_Link_1164487778" MODIFIED="1245882914397" TEXT="Order History Browser">
<icon BUILTIN="full-4"/>
</node>
<node CREATED="1237479513679" ID="Freemind_Link_123674584" MODIFIED="1245882918598" TEXT="appwin(sim): Windows Menu">
<icon BUILTIN="full-5"/>
</node>
<node CREATED="1237479823575" FOLDED="true" ID="Freemind_Link_1856908617" MODIFIED="1245882618094" TEXT="Preserve GUI layout">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237479839174" ID="Freemind_Link_254956277" MODIFIED="1237479844658" TEXT="Save on shutdown or request"/>
<node CREATED="1237479845294" ID="Freemind_Link_1346360849" MODIFIED="1237479851922" TEXT="Restore at startup"/>
</node>
<node CREATED="1238513993932" ID="Freemind_Link_26326231" MODIFIED="1245882622470" TEXT="History and Causality Visualization">
<icon BUILTIN="messagebox_warning"/>
</node>
<node CREATED="1237479525078" FOLDED="true" ID="Freemind_Link_122163295" MODIFIED="1239983812453" TEXT="appwin(sim): Optional Tabs">
<icon BUILTIN="help"/>
<node CREATED="1241214594644" ID="Freemind_Link_1984205013" MODIFIED="1241214609450" TEXT="May be obsolesced by hierarchical tab layout"/>
<node CREATED="1237479542494" ID="Freemind_Link_1417851375" MODIFIED="1237479555026" TEXT="Most/all tabs should be optional."/>
<node CREATED="1237479555774" ID="Freemind_Link_1026314275" MODIFIED="1237479568490" TEXT="Each tab has a checkbox on View menu"/>
<node CREATED="1237479569238" ID="Freemind_Link_1577478674" MODIFIED="1237479591914" TEXT="Disabled tabs don&apos;t exist, no CPU used"/>
</node>
<node CREATED="1241216036944" FOLDED="true" ID="Freemind_Link_559127107" MODIFIED="1241216053418" TEXT="&quot;URL&quot; based tab browsing">
<icon BUILTIN="help"/>
<node CREATED="1241216062751" ID="Freemind_Link_322438430" MODIFIED="1241216070954" TEXT="Tabs appear as requested"/>
<node CREATED="1241216071296" ID="Freemind_Link_781573337" MODIFIED="1241216074202" TEXT="Can have links to tabs"/>
<node CREATED="1241216074704" ID="Freemind_Link_825887682" MODIFIED="1241216078266" TEXT="Can have bookmarks to tabs"/>
<node CREATED="1241216084864" ID="Freemind_Link_1227873560" MODIFIED="1241216095226" TEXT="Links/bookmarks can include filter settings, views, etc."/>
</node>
</node>
<node CREATED="1237479990726" ID="Freemind_Link_1486904062" MODIFIED="1242242438803" POSITION="right" TEXT="Map GUI">
<node CREATED="1243610985766" ID="Freemind_Link_1124965888" MODIFIED="1243611022272" TEXT="Can mapviewer(sim) be modularized?"/>
<node CREATED="1237481843234" FOLDED="true" ID="Freemind_Link_1306844691" MODIFIED="1245882636814" TEXT="Set unit shapes based on relationships">
<icon BUILTIN="full-4"/>
<node CREATED="1237481854578" ID="Freemind_Link_720065925" MODIFIED="1237481862230" TEXT="WRT user-selected group"/>
<node CREATED="1237481862754" ID="Freemind_Link_1299949235" MODIFIED="1237481887774" TEXT="qgrouprel defines FRIEND, NEUTRAL, ENEMY"/>
</node>
<node CREATED="1237482154410" ID="Freemind_Link_1362932509" MODIFIED="1245882932949" TEXT="Enable/disable map background">
<icon BUILTIN="full-4"/>
</node>
<node CREATED="1237482166114" ID="Freemind_Link_639175641" MODIFIED="1245882932953" TEXT="Enable/disable nbhood display">
<icon BUILTIN="full-4"/>
</node>
<node CREATED="1237482173858" ID="Freemind_Link_270558674" MODIFIED="1245882932952" TEXT="Enable/disable unit icons">
<icon BUILTIN="full-4"/>
<node CREATED="1237482180474" ID="Freemind_Link_1659229339" MODIFIED="1237482185838" TEXT="By icon type"/>
</node>
<node CREATED="1242251888314" FOLDED="true" ID="Freemind_Link_540157612" MODIFIED="1245882932951" TEXT="Enable/disable envsit icons">
<icon BUILTIN="full-4"/>
<node CREATED="1242251898217" ID="Freemind_Link_901616595" MODIFIED="1242251900787" TEXT="All"/>
<node CREATED="1242251901338" ID="Freemind_Link_1052726683" MODIFIED="1242251902755" TEXT="Current"/>
<node CREATED="1242251903034" ID="Freemind_Link_1053169404" MODIFIED="1242251904515" TEXT="Ended"/>
<node CREATED="1242251904841" ID="Freemind_Link_1296804293" MODIFIED="1242251908099" TEXT="None"/>
</node>
<node CREATED="1242251949130" FOLDED="true" ID="Freemind_Link_1306195532" MODIFIED="1245882972519" TEXT="Envsit context menu">
<icon BUILTIN="full-4"/>
<node CREATED="1242251952906" ID="Freemind_Link_1286947887" MODIFIED="1242251956675" TEXT="Resolve Situation"/>
<node CREATED="1242251956970" ID="Freemind_Link_184985576" MODIFIED="1242251960147" TEXT="Delete Situation"/>
</node>
<node CREATED="1241813623814" ID="Freemind_Link_1926362182" MODIFIED="1245882942989" TEXT="Spawned envsits should be offset from their parent&apos;s location">
<icon BUILTIN="full-5"/>
</node>
<node CREATED="1242242263068" FOLDED="true" ID="Freemind_Link_812896575" MODIFIED="1245882948765" TEXT="Nbhood context menu">
<icon BUILTIN="full-5"/>
<node CREATED="1242242268299" ID="Freemind_Link_1520143269" MODIFIED="1242251988899" TEXT="Update Neighborhood"/>
<node CREATED="1242242274059" ID="Freemind_Link_1324604126" MODIFIED="1242251993812" TEXT="Delete Neighborhood"/>
</node>
<node CREATED="1243608727625" FOLDED="true" ID="Freemind_Link_165747052" MODIFIED="1245882695006" TEXT="Coloring Neighborhoods">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1243609801832" ID="Freemind_Link_908576864" MODIFIED="1243609806894" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1243610891990" ID="Freemind_Link_1084808438" MODIFIED="1243610905184" TEXT="A simple coloring mechanism is already in place"/>
<node CREATED="1243610905941" ID="Freemind_Link_1360045819" MODIFIED="1243610918879" TEXT="This is a more advanced capability"/>
<node CREATED="1243608736874" ID="Freemind_Link_882934496" MODIFIED="1243608763924" TEXT="A coloring is a dictionary of neighborhood names and Tk color strings"/>
<node CREATED="1243608789963" ID="Freemind_Link_1893917931" MODIFIED="1243608810628" TEXT="The nbcolor module is responsible for returning particular colorings."/>
<node CREATED="1243608838682" ID="Freemind_Link_45215652" MODIFIED="1243608876884" TEXT="Instances of nbcolor can be set up to return any desired coloring."/>
<node CREATED="1243608877386" ID="Freemind_Link_78227239" MODIFIED="1243608906564" TEXT="Each mapviewer creates an instance of nbcolor."/>
<node CREATED="1243608910186" ID="Freemind_Link_1740995719" MODIFIED="1243608930964" TEXT="The instance of nbcolor can be configured by the user."/>
<node CREATED="1243609823064" ID="Freemind_Link_1861755438" MODIFIED="1243609846562" TEXT="GUI Components">
<node CREATED="1243609846904" ID="Freemind_Link_1900012607" MODIFIED="1243609853460" TEXT="Toolbar object">
<node CREATED="1243609853735" ID="Freemind_Link_152770448" MODIFIED="1243609861106" TEXT="Shows current setting"/>
<node CREATED="1243609861608" ID="Freemind_Link_25457227" MODIFIED="1243609889698" TEXT="When clicked, pops up a picker dialog"/>
<node CREATED="1243609920456" ID="Freemind_Link_807141874" MODIFIED="1243609929425" TEXT="Might allow immediate choice of common colorings"/>
</node>
<node CREATED="1243609891496" ID="Freemind_Link_1377420000" MODIFIED="1243609894674" TEXT="Picker Dialog">
<node CREATED="1243609895304" ID="Freemind_Link_1183318129" MODIFIED="1243609917313" TEXT="Allows user to configure the coloring"/>
</node>
</node>
</node>
<node CREATED="1243609945127" ID="Freemind_Link_707836616" MODIFIED="1243609947634" TEXT="Colorings">
<node CREATED="1243609965735" ID="Freemind_Link_1072413760" MODIFIED="1243609967938" TEXT="none()">
<node CREATED="1243609968376" ID="Freemind_Link_945600277" MODIFIED="1243609975457" TEXT="Neighborhoods are not colored."/>
</node>
<node CREATED="1243609948103" ID="Freemind_Link_610648636" MODIFIED="1243609954626" TEXT="white()">
<node CREATED="1243609955351" ID="Freemind_Link_1609274989" MODIFIED="1243609961441" TEXT="All neighborhoods are white."/>
</node>
<node CREATED="1243610019448" ID="Freemind_Link_1227002190" MODIFIED="1243610024482" TEXT="nbmood(n)">
<node CREATED="1243610024823" ID="Freemind_Link_758379556" MODIFIED="1243610049153" TEXT="Visualize neighborhood mood"/>
</node>
<node CREATED="1243610050792" ID="Freemind_Link_1868546239" MODIFIED="1243610056018" TEXT="mood(n,g)">
<node CREATED="1243610056599" ID="Freemind_Link_829876562" MODIFIED="1243610062961" TEXT="Visual mood of group g in n"/>
</node>
<node CREATED="1243610067320" ID="Freemind_Link_159737659" MODIFIED="1243610084946" TEXT="sat(n,g,c)">
<node CREATED="1243610085400" ID="Freemind_Link_371656735" MODIFIED="1243610105425" TEXT="Visualize satisfaction n,g,c"/>
</node>
<node CREATED="1243610107271" ID="Freemind_Link_26249288" MODIFIED="1243610143349" TEXT="nbcoop(n,g)">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1243610122775" ID="Freemind_Link_1870149657" MODIFIED="1243610136769" TEXT="Visualize cooperation of n with frcgroup g">
<node CREATED="1243610138552" ID="Freemind_Link_1427140277" MODIFIED="1243610182159" TEXT="GRAM does not compute this yet"/>
</node>
</node>
<node CREATED="1243610149352" ID="Freemind_Link_982613867" MODIFIED="1243610153634" TEXT="coop(n,f,g)">
<node CREATED="1243610154055" ID="Freemind_Link_1874258289" MODIFIED="1243610162033" TEXT="Visualize cooperation of f with g in n"/>
</node>
<node CREATED="1243610199047" ID="Freemind_Link_181447196" MODIFIED="1243610233167" TEXT="coverage(n,g,stype)">
<node CREATED="1243610205783" ID="Freemind_Link_1499403948" MODIFIED="1243610254625" TEXT="Visualize coverage of activity situations of type stype by g"/>
</node>
<node CREATED="1243610289128" ID="Freemind_Link_1828624426" MODIFIED="1243610318525" TEXT="contrib(n,drivers)">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1243610313479" ID="Freemind_Link_725701927" MODIFIED="1243610365967" TEXT="Contribution to some curve by some set of drivers over some period of time">
<node CREATED="1243610350663" ID="Freemind_Link_154187182" MODIFIED="1243610358647" TEXT="Really tricky!"/>
</node>
</node>
</node>
<node CREATED="1243608943818" FOLDED="true" ID="Freemind_Link_1714145086" MODIFIED="1243609785970" TEXT="Design Choices">
<node CREATED="1243609788120" ID="Freemind_Link_1454711819" MODIFIED="1243609791154" TEXT="Architecture">
<node CREATED="1243608954762" ID="Freemind_Link_1926901190" MODIFIED="1243609994557" TEXT="Option A">
<icon BUILTIN="button_cancel"/>
<node CREATED="1243608957450" ID="Freemind_Link_352692912" MODIFIED="1243608979332" TEXT="nbcolor is a non-GUI type."/>
<node CREATED="1243608979930" ID="Freemind_Link_76178840" MODIFIED="1243609001668" TEXT="nbcolorpicker is a GUI control for configuring nbcolor."/>
<node CREATED="1243609010122" ID="Freemind_Link_804374048" MODIFIED="1243609021363" TEXT="nbcolorpicker might have an nbcolor as a component"/>
</node>
<node CREATED="1243609023482" ID="Freemind_Link_1608126917" MODIFIED="1243609998045" TEXT="Option B">
<icon BUILTIN="button_ok"/>
<node CREATED="1243609026121" ID="Freemind_Link_1577893005" MODIFIED="1243609721682" TEXT="nbcolor is a single GUI object combining the functions of Option A"/>
</node>
<node CREATED="1243609723367" ID="Freemind_Link_286287497" MODIFIED="1243609730771" TEXT="Conclusion">
<node CREATED="1243609731433" ID="Freemind_Link_413340921" MODIFIED="1243609753858" TEXT="If this were library code, Option A would win."/>
<node CREATED="1243609754760" ID="Freemind_Link_888507510" MODIFIED="1243609770738" TEXT="As application code, it&apos;s better not to pay the modularization cost."/>
</node>
</node>
</node>
</node>
<node CREATED="1237482195459" ID="Freemind_Link_1291634544" MODIFIED="1245882972517" TEXT="Display nbhood names near refpoint">
<icon BUILTIN="full-4"/>
</node>
<node CREATED="1237480762290" ID="Freemind_Link_1647420652" MODIFIED="1242252017271" TEXT="Ability to drag reference points interactively">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237481081578" ID="Freemind_Link_1201367450" MODIFIED="1242252017273" TEXT="Ability to edit nbhood boundary points interactively">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237480148482" ID="Freemind_Link_1288481032" MODIFIED="1237480151141" POSITION="right" TEXT="Order GUI">
<node CREATED="1237480151546" ID="Freemind_Link_1910353174" MODIFIED="1245882715582" TEXT="Validate order on parameter entry change">
<icon BUILTIN="full-3"/>
</node>
<node CREATED="1237480163506" FOLDED="true" ID="Freemind_Link_1602203708" MODIFIED="1245882718678" TEXT="User selects order execution time">
<icon BUILTIN="full-3"/>
<node CREATED="1237480179450" ID="Freemind_Link_1441599316" MODIFIED="1237480186965" TEXT="Invalid orders can be scheduled"/>
</node>
<node CREATED="1237480419203" FOLDED="true" ID="Freemind_Link_1658294835" MODIFIED="1245882727062" TEXT="Z-Curve editor/order field">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237480439570" ID="Freemind_Link_1579708717" MODIFIED="1237480447765" TEXT="Mostly complete"/>
<node CREATED="1237480448378" ID="Freemind_Link_1976364131" MODIFIED="1237480454069" TEXT="Use -type, bounds, for layout"/>
<node CREATED="1237480455082" ID="Freemind_Link_1029610545" MODIFIED="1237480463597" TEXT="Add &quot;Clear&quot; button to clear fields to match curve"/>
<node CREATED="1237480464266" ID="Freemind_Link_1002868925" MODIFIED="1237480490037" TEXT="Buttons active only when unsaved data"/>
<node CREATED="1237480480554" ID="Freemind_Link_208340476" MODIFIED="1237480498638" TEXT="Buttons use tinyfont"/>
</node>
<node CREATED="1237482036218" FOLDED="true" ID="Freemind_Link_594210180" MODIFIED="1245882733502" TEXT="textfield(n) allows -autocmd">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237482048762" ID="Freemind_Link_1233297342" MODIFIED="1237482067198" TEXT="If present, field has &quot;Auto&quot; button"/>
<node CREATED="1237482068018" ID="Freemind_Link_1873031307" MODIFIED="1237482082038" TEXT="Pressing Auto fills in field automatically"/>
</node>
<node CREATED="1237482088442" ID="Freemind_Link_1487556535" MODIFIED="1245882735533" TEXT="colorfield(n) should allow editing">
<icon BUILTIN="messagebox_warning"/>
</node>
<node CREATED="1237480589114" ID="Freemind_Link_1560701323" MODIFIED="1245882753262" TEXT="Implement order dialog&apos;s Help button">
<arrowlink DESTINATION="Freemind_Link_1752009235" ENDARROW="Default" ENDINCLINATION="187;0;" ID="Freemind_Arrow_Link_1754252667" STARTARROW="None" STARTINCLINATION="187;0;"/>
<icon BUILTIN="messagebox_warning"/>
</node>
<node CREATED="1237481160994" FOLDED="true" ID="Freemind_Link_1793874343" MODIFIED="1245882756438" TEXT="Parameter help strings">
<icon BUILTIN="full-4"/>
<node CREATED="1237481181034" ID="Freemind_Link_382977978" MODIFIED="1237481200616" TEXT="Display in order dialog&apos;s message area"/>
<node CREATED="1238170607413" ID="Freemind_Link_1227050066" MODIFIED="1238170619791" TEXT="Build order docs at build time?"/>
</node>
<node CREATED="1237481709395" FOLDED="true" ID="Freemind_Link_242433049" MODIFIED="1238771729630" TEXT="Enumfield should display short and long name">
<icon BUILTIN="help"/>
<node CREATED="1237481720578" ID="Freemind_Link_568955124" MODIFIED="1237481725070" TEXT="For enum(n)"/>
<node CREATED="1237481731218" ID="Freemind_Link_288295662" MODIFIED="1237481735974" TEXT="For entities with long names"/>
<node CREATED="1237481736658" ID="Freemind_Link_1062430820" MODIFIED="1237481739782" TEXT="For quality(n)"/>
<node CREATED="1237481740282" ID="Freemind_Link_1648375048" MODIFIED="1237481749862" TEXT="Send short name to order(sim)"/>
</node>
<node CREATED="1237480808675" ID="Freemind_Link_490467788" MODIFIED="1237480882437" TEXT="Scrolling order tree, in dialog or palette">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237479872766" ID="Freemind_Link_307055918" MODIFIED="1237479878826" POSITION="right" TEXT="Infrastructure">
<node CREATED="1241215963136" ID="Freemind_Link_651437895" MODIFIED="1245882765790" TEXT="editcode command">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1241215972800" ID="Freemind_Link_1463898670" MODIFIED="1241215982895" TEXT="Use built-in editor; accumulate changes."/>
<node CREATED="1241215991169" ID="Freemind_Link_365239223" MODIFIED="1241215998114" TEXT="Can save changes to disk"/>
</node>
<node CREATED="1237479880174" FOLDED="true" ID="Freemind_Link_640139219" MODIFIED="1245882768934" TEXT="notifier(n) introspection">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237479886358" ID="Freemind_Link_1497195308" MODIFIED="1237479891074" TEXT="Dump subscription info"/>
<node CREATED="1237479891694" ID="Freemind_Link_67855834" MODIFIED="1237479901642" TEXT="Predict effect of sending an event"/>
</node>
<node CREATED="1241216138976" ID="Freemind_Link_246477941" MODIFIED="1245882771621" TEXT="option parsing control structure">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1241216145551" ID="Freemind_Link_1558908137" MODIFIED="1241216155226" TEXT="Wraps while/switch structure"/>
</node>
<node CREATED="1238773722771" ID="Freemind_Link_866234982" MODIFIED="1238773731816" TEXT="Store logs in RDB?">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237481352818" FOLDED="true" ID="Freemind_Link_1224970170" MODIFIED="1237481417790" TEXT="notifer(n) priorities">
<icon BUILTIN="help"/>
<node CREATED="1237481421898" ID="Freemind_Link_1848530205" MODIFIED="1237481436422" TEXT="App defines priorities: gui, sim1, sim2, sim3"/>
<node CREATED="1237481437274" ID="Freemind_Link_1336072700" MODIFIED="1237481450502" TEXT="Subscriptions can specify priority"/>
<node CREATED="1237481451282" ID="Freemind_Link_748922583" MODIFIED="1237481459206" TEXT="Subscriptions are called in priority order"/>
<node CREATED="1237481473794" ID="Freemind_Link_1619454873" MODIFIED="1237481528522" TEXT="One event could serve both sim and GUI,&#xa;but sim can be guaranteed to finish first."/>
</node>
<node CREATED="1237481543859" FOLDED="true" ID="Freemind_Link_1957412449" MODIFIED="1237481605342" TEXT="notifer(n): send -idle">
<icon BUILTIN="help"/>
<node CREATED="1237481552226" ID="Freemind_Link_539355180" MODIFIED="1237481590830" TEXT="Event executes as idle handler or zero timeout"/>
<node CREATED="1237481591466" ID="Freemind_Link_1737535748" MODIFIED="1237481597262" TEXT="Such events must be queued"/>
</node>
<node CREATED="1237481629010" FOLDED="true" ID="Freemind_Link_541729179" MODIFIED="1237481666014" TEXT="Spreadsheet-style model framework">
<icon BUILTIN="help"/>
<node CREATED="1237481638490" ID="Freemind_Link_1455778469" MODIFIED="1237481646893" TEXT="Named cells containing formulas"/>
<node CREATED="1237481647402" ID="Freemind_Link_1584051598" MODIFIED="1237481655934" TEXT="Formulas can depend on other cells"/>
<node CREATED="1237481656514" ID="Freemind_Link_853037145" MODIFIED="1237481662310" TEXT="Ability to iterate to a solution"/>
</node>
</node>
<node CREATED="1238697459940" ID="Freemind_Link_946664107" MODIFIED="1238697464078" POSITION="right" TEXT="GUI Infrastructure">
<node CREATED="1237488295816" FOLDED="true" ID="Freemind_Link_1208739900" MODIFIED="1245882774638" TEXT="zulufield(n) widget">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237560838308" ID="Freemind_Link_7202440" MODIFIED="1237560850862" TEXT="-increment set by simclock&apos;s tick size"/>
<node CREATED="1237918381064" ID="Freemind_Link_274696888" MODIFIED="1237918408034" TEXT="Make -changecmd work properly"/>
</node>
<node CREATED="1237479433118" FOLDED="true" ID="Freemind_Link_491578520" MODIFIED="1245882780238" TEXT="Cell-based editing in browsers">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237479441630" ID="Freemind_Link_1508483203" MODIFIED="1237479447402" TEXT="Interaction Logic"/>
<node CREATED="1237479448534" ID="Freemind_Link_1379686715" MODIFIED="1237479457434" TEXT="How to use custom editors in Tablelist"/>
</node>
<node CREATED="1237480548048" FOLDED="true" ID="Freemind_Link_1752009235" MODIFIED="1245882783486" TEXT="Help Browser">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237480554706" ID="Freemind_Link_418716993" MODIFIED="1237480564829" TEXT="Firefox, Tkhtml2, or Text"/>
<node CREATED="1237480565722" ID="Freemind_Link_452312016" MODIFIED="1237480582229" TEXT="If Firefox, prefs setting for location"/>
</node>
<node CREATED="1237480727986" FOLDED="true" ID="Freemind_Link_1856628726" MODIFIED="1245882786357" TEXT="filter(n): -filterset option">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237480742858" ID="Freemind_Link_1542097651" MODIFIED="1237480750709" TEXT="Allows multiple filters to show same filter string"/>
</node>
<node CREATED="1237481060666" ID="Freemind_Link_236045392" MODIFIED="1237481071958" TEXT="Wizard infrastructure">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237479138614" ID="Freemind_Link_1692010973" MODIFIED="1237479140586" POSITION="right" TEXT="App">
<node CREATED="1237479175966" FOLDED="true" ID="Freemind_Link_1542399623" MODIFIED="1245882790414" TEXT="Session Operations">
<icon BUILTIN="full-4"/>
<node CREATED="1238777425532" FOLDED="true" ID="Freemind_Link_41549205" MODIFIED="1238777430760" TEXT="Rename current session">
<node CREATED="1238777431084" ID="Freemind_Link_1718377270" MODIFIED="1238777436118" TEXT="Named sessions aren&apos;t purged"/>
</node>
<node CREATED="1237479256574" ID="Freemind_Link_703383499" MODIFIED="1238777457142" TEXT="Re-enter, given name"/>
<node CREATED="1237479265638" FOLDED="true" ID="Freemind_Link_657545711" MODIFIED="1237479311398" TEXT="Package session as zipfile">
<node CREATED="1238777465837" ID="Freemind_Link_1526382836" MODIFIED="1238777477326" TEXT="tarball?"/>
</node>
<node CREATED="1237479285670" ID="Freemind_Link_209800069" MODIFIED="1238777522390" TEXT="Install zipped session"/>
<node CREATED="1237479312598" FOLDED="true" ID="Freemind_Link_1937283519" MODIFIED="1237479326154" TEXT="List existing sessions">
<node CREATED="1237479326670" ID="Freemind_Link_57127863" MODIFIED="1237479341778" TEXT="Include whether active or not."/>
<node CREATED="1238777494956" ID="Freemind_Link_498624327" MODIFIED="1238777512934" TEXT="Active if timestamp is in the last ten minutes"/>
</node>
<node CREATED="1238777523740" ID="Freemind_Link_552228775" MODIFIED="1238777532358" TEXT="Delete session by name"/>
<node CREATED="1238777536093" FOLDED="true" ID="Freemind_Link_869267576" MODIFIED="1238777546568" TEXT="Purge sessions">
<node CREATED="1238777546893" ID="Freemind_Link_371497128" MODIFIED="1238777552406" TEXT="All inactive sessions"/>
<node CREATED="1238777552924" ID="Freemind_Link_313955929" MODIFIED="1238777567542" TEXT="Inactive sessions older than X"/>
</node>
</node>
<node CREATED="1241216122192" ID="Freemind_Link_97633427" MODIFIED="1245882794806" TEXT="session.usermode preference">
<icon BUILTIN="messagebox_warning"/>
</node>
</node>
</node>
</map>
