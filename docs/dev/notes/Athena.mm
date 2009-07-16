<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237475113960" ID="Freemind_Link_868839690" MODIFIED="1237475134049" TEXT="Athena">
<node CREATED="1243527457709" ID="Freemind_Link_320906598" MODIFIED="1243527459755" POSITION="right" TEXT="Problems">
<node CREATED="1243527460189" ID="Freemind_Link_1011323624" MODIFIED="1243527474567" TEXT="Moving from snapshot to snapshot can be very slow"/>
</node>
<node CREATED="1237477449934" ID="Freemind_Link_919437009" MODIFIED="1237477452594" POSITION="right" TEXT="Simulation">
<node CREATED="1243869063603" ID="Freemind_Link_963259115" MODIFIED="1245882363502" TEXT="Athena Attrition Model">
<icon BUILTIN="full-1"/>
</node>
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
<node CREATED="1237481029826" ID="Freemind_Link_660348068" MODIFIED="1237481031278" POSITION="right" TEXT="CM">
<node CREATED="1237481032018" ID="Freemind_Link_920792744" MODIFIED="1237481052413" TEXT="make clean: clean up auto-generated GIFs in man* directories"/>
</node>
<node CREATED="1237477422983" ID="Freemind_Link_1059023875" MODIFIED="1237477425010" POSITION="right" TEXT="Docs">
<node CREATED="1237477426471" ID="Freemind_Link_887072406" MODIFIED="1237477434298" TEXT="Athena Analyst&apos;s Guide">
<node CREATED="1243546538141" ID="Freemind_Link_875023326" MODIFIED="1243546545543" TEXT="Units"/>
<node CREATED="1243546545805" ID="Freemind_Link_836988593" MODIFIED="1243546553975" TEXT="Activity Coverage"/>
<node CREATED="1243546554317" ID="Freemind_Link_315437659" MODIFIED="1243546557255" TEXT="Activity Situations"/>
<node CREATED="1243546557629" ID="Freemind_Link_647185308" MODIFIED="1243546563271" TEXT="Environmental Situations"/>
<node CREATED="1243546566030" ID="Freemind_Link_1669318727" MODIFIED="1245882814164" TEXT="DAM Rules"/>
</node>
<node CREATED="1237477435158" ID="Freemind_Link_144909588" MODIFIED="1237477440938" TEXT="Athena Architecture Document"/>
<node CREATED="1237480507154" FOLDED="true" ID="Freemind_Link_1237244067" MODIFIED="1237480511727" TEXT="Tcl/Tk Coding Standard">
<node CREATED="1237480512322" ID="Freemind_Link_1356756808" MODIFIED="1237480517069" TEXT="Move from JNEM to Mars."/>
<node CREATED="1237480517906" ID="Freemind_Link_1655161326" MODIFIED="1237480519237" TEXT="Update"/>
<node CREATED="1237480520129" ID="Freemind_Link_656371050" MODIFIED="1237480523168" TEXT="Reference in Athena"/>
</node>
</node>
<node CREATED="1237934628643" FOLDED="true" ID="Freemind_Link_276542603" MODIFIED="1237934645816" POSITION="left" TEXT="Done">
<icon BUILTIN="button_ok"/>
<node CREATED="1238105059255" FOLDED="true" ID="Freemind_Link_1270491565" MODIFIED="1238105072101" TEXT="Bug 1958">
<icon BUILTIN="button_ok"/>
<node CREATED="1237477459286" FOLDED="true" ID="Freemind_Link_860445490" MODIFIED="1237918566061" TEXT="Allow simtime to advance">
<icon BUILTIN="button_ok"/>
<node CREATED="1237479644159" FOLDED="true" ID="Freemind_Link_1989940868" MODIFIED="1237479651010" TEXT="Simulation State">
<node CREATED="1237479651814" ID="Freemind_Link_1441941516" MODIFIED="1237479657082" TEXT="PREP"/>
<node CREATED="1237479657678" ID="Freemind_Link_1705099136" MODIFIED="1237479660450" TEXT="RUNNING"/>
<node CREATED="1237479661110" ID="Freemind_Link_1694836583" MODIFIED="1237479663634" TEXT="PAUSED"/>
</node>
</node>
<node CREATED="1237480079146" ID="Freemind_Link_1971828045" MODIFIED="1237585969712" TEXT="Support eventq events">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238105040439" FOLDED="true" ID="Freemind_Link_397054523" MODIFIED="1238105050189" TEXT="Bug 1961">
<icon BUILTIN="button_ok"/>
<node CREATED="1237823234872" FOLDED="true" ID="Freemind_Link_1459784431" MODIFIED="1237934610816" TEXT="Auto-snapshots">
<icon BUILTIN="button_ok"/>
<node CREATED="1237564822348" ID="Freemind_Link_1094167895" MODIFIED="1237934572300" TEXT="SIM:RUN saves snapshott before transition"/>
<node CREATED="1237823265751" ID="Freemind_Link_407919202" MODIFIED="1237934579811" TEXT="App manages set of snapshots during session"/>
<node CREATED="1237829994090" ID="Freemind_Link_1764789611" MODIFIED="1237934595948" TEXT="User can return to old snapshot"/>
<node CREATED="1237823273480" FOLDED="true" ID="Freemind_Link_1214250639" MODIFIED="1237823302545" TEXT="saveables(i) Change">
<node CREATED="1237830033193" ID="Freemind_Link_355979907" MODIFIED="1237830047443" TEXT="At present, saveables assume that &quot;checkpoint&quot; means they have been saved."/>
<node CREATED="1237823316552" ID="Freemind_Link_1633805485" MODIFIED="1237823354614" TEXT="Must be able to call saveable&apos;s &quot;checkpoint&quot; method&#xa;without setting the object&apos;s &quot;saved&quot; flag, e.g.,&#xa;&quot;$object checkpoint -notsaved&quot;"/>
</node>
<node CREATED="1237830058698" FOLDED="true" ID="Freemind_Link_1660914597" MODIFIED="1237934605708" TEXT="Include snapshots in RDB, ADB">
<node CREATED="1237830107610" ID="Freemind_Link_1797755349" MODIFIED="1237830118739" TEXT="Rename &quot;checkpoints&quot; table to &quot;saveables&quot;"/>
<node CREATED="1237830119434" ID="Freemind_Link_1657153926" MODIFIED="1237830128723" TEXT="Store checkpoints in &quot;checkpoints&quot; table"/>
<node CREATED="1237830129242" FOLDED="true" ID="Freemind_Link_1826040449" MODIFIED="1237830145652" TEXT="To save a checkpoint">
<node CREATED="1237830146106" ID="Freemind_Link_880660979" MODIFIED="1237830151395" TEXT="Save working data as XML"/>
<node CREATED="1237830152058" ID="Freemind_Link_243868175" MODIFIED="1237830174691" TEXT="Exclude the maps and checkpoints tables"/>
</node>
<node CREATED="1237830186136" FOLDED="true" ID="Freemind_Link_258901333" MODIFIED="1237830190003" TEXT="To restore a checkpoint">
<node CREATED="1237830190744" ID="Freemind_Link_1078181867" MODIFIED="1237830202115" TEXT="Reload the XML for the checkpoint"/>
<node CREATED="1237830202729" ID="Freemind_Link_1109472895" MODIFIED="1237830213155" TEXT="Will replace contents of all tables included in the XML."/>
</node>
</node>
</node>
</node>
<node CREATED="1238105021367" FOLDED="true" ID="Freemind_Link_135593121" MODIFIED="1238105031997" TEXT="Bug 1962">
<icon BUILTIN="button_ok"/>
<node CREATED="1237477378229" ID="Freemind_Link_527719459" MODIFIED="1238003858401" TEXT="Enable/disable orders based on simulation state">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1237479698478" FOLDED="true" ID="Freemind_Link_1365670694" MODIFIED="1238104974257" TEXT="Bug 1963">
<edge WIDTH="thin"/>
<arrowlink DESTINATION="Freemind_Link_527719459" ENDARROW="Default" ENDINCLINATION="166;0;" ID="Freemind_Arrow_Link_358621600" STARTARROW="None" STARTINCLINATION="166;0;"/>
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_ok"/>
<node CREATED="1237479698478" ID="Freemind_Link_92668086" MODIFIED="1238104981809" TEXT="Enable/Disable order controls automatically">
<edge WIDTH="thin"/>
<arrowlink DESTINATION="Freemind_Link_527719459" ENDARROW="Default" ENDINCLINATION="166;0;" ID="Freemind_Arrow_Link_152220553" STARTARROW="None" STARTINCLINATION="166;0;"/>
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237588201262" ID="Freemind_Link_222069803" MODIFIED="1238104951277" TEXT="File/Open, etc., should be disabled when RUNNING">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238170053719" FOLDED="true" ID="Freemind_Link_953600025" MODIFIED="1238170094533" TEXT="Bug 1966">
<icon BUILTIN="button_ok"/>
<node CREATED="1238107725235" FOLDED="true" ID="Freemind_Link_260363276" MODIFIED="1238170094532" TEXT="Replace ::sim &lt;Status&gt;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238107798339" FOLDED="true" ID="Freemind_Link_1365021836" MODIFIED="1238107800300" TEXT="New Events">
<node CREATED="1238107739698" ID="Freemind_Link_437840786" MODIFIED="1238107745596" TEXT="&lt;Tick&gt;"/>
<node CREATED="1238168630505" ID="Freemind_Link_539391698" MODIFIED="1238168634836" TEXT="&lt;Time&gt;"/>
<node CREATED="1238107746179" ID="Freemind_Link_1624909068" MODIFIED="1238168640723" TEXT="&lt;State&gt;"/>
<node CREATED="1238107788002" ID="Freemind_Link_409425418" MODIFIED="1238107790380" TEXT="&lt;Speed&gt;"/>
</node>
<node CREATED="1238107804754" ID="Freemind_Link_1786540087" MODIFIED="1238107814748" TEXT="appwin can subscribe one handler to all three"/>
</node>
</node>
<node CREATED="1238170234726" FOLDED="true" ID="Freemind_Link_329451020" MODIFIED="1238170252020" TEXT="Bug 1965">
<icon BUILTIN="button_ok"/>
<node CREATED="1237571987086" ID="Freemind_Link_33041850" MODIFIED="1238170252021" TEXT="Undo info should be cleared at each tick.">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238174760622" FOLDED="true" ID="Freemind_Link_1452183384" MODIFIED="1238174774524" TEXT="Bug 1967">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171285579" FOLDED="true" ID="Freemind_Link_164640460" MODIFIED="1238174774526" TEXT="Scenario Sanity Check">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171311427" FOLDED="true" ID="Freemind_Link_1401500484" MODIFIED="1238171324314" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1237479063275" ID="Freemind_Link_1056971138" MODIFIED="1238174587800" TEXT="The scenario must be sane before time can advance."/>
<node CREATED="1238171344773" FOLDED="true" ID="Freemind_Link_426910570" MODIFIED="1238171427950" TEXT="Do a sanity check on SIM:RUN">
<node CREATED="1238171428405" ID="Freemind_Link_759586256" MODIFIED="1238171433550" TEXT="Order is rejected."/>
<node CREATED="1238171434340" ID="Freemind_Link_875208047" MODIFIED="1238171449006" TEXT="Present warnings to user"/>
</node>
<node CREATED="1238170280470" FOLDED="true" ID="Freemind_Link_922997392" MODIFIED="1238173690494" TEXT="Conditions">
<icon BUILTIN="button_ok"/>
<node CREATED="1238170282869" ID="Freemind_Link_1314220736" MODIFIED="1238170286656" TEXT="At least one nbhood"/>
<node CREATED="1238170287253" ID="Freemind_Link_1784577310" MODIFIED="1238170293808" TEXT="At least one FRC group"/>
<node CREATED="1238173505296" ID="Freemind_Link_1273631840" MODIFIED="1238173515113" TEXT="At least one CIV group"/>
<node CREATED="1238170294358" ID="Freemind_Link_265827600" MODIFIED="1238170299952" TEXT="At least one nbgroup per neighborhood"/>
<node CREATED="1238173516192" ID="Freemind_Link_650706235" MODIFIED="1238173521850" TEXT="At least one nbgroup per CIV group"/>
</node>
<node CREATED="1238173533168" ID="Freemind_Link_476733601" MODIFIED="1238173657909" TEXT="These conditions assume that all neighborhoods must&#xa;have resident civilians.  We might instead want to track&#xa;satisfaction only for neighborhoods that do have &#xa;resident civilians.">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237478995798" FOLDED="true" ID="Freemind_Link_1302227452" MODIFIED="1238174388141" TEXT="sim(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171490835" FOLDED="true" ID="Freemind_Link_752525374" MODIFIED="1238174386229" TEXT="sim check ?-log?">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171508052" ID="Freemind_Link_1274803095" MODIFIED="1238171514157" TEXT="Performs sanity check"/>
<node CREATED="1238171514692" ID="Freemind_Link_1441734208" MODIFIED="1238171523054" TEXT="Logs results to debugging log"/>
<node CREATED="1238171524308" ID="Freemind_Link_1253796134" MODIFIED="1238171536364" TEXT="Returns a boolean flag."/>
</node>
<node CREATED="1238171567604" FOLDED="true" ID="Freemind_Link_43310679" MODIFIED="1238174386229" TEXT="SIM:RUN">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171571172" ID="Freemind_Link_1028498519" MODIFIED="1238171579101" TEXT="Calls &quot;sim check -log&quot;"/>
<node CREATED="1238171579732" ID="Freemind_Link_460230865" MODIFIED="1238171599661" TEXT="On failure, rejects order with explanatory message"/>
</node>
</node>
<node CREATED="1238171602644" FOLDED="true" ID="Freemind_Link_1245358500" MODIFIED="1238174395357" TEXT="appwin(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171612611" ID="Freemind_Link_556644434" MODIFIED="1238171635705" TEXT="Sends SIM:RUN when play button is pressed">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238171887427" ID="Freemind_Link_1319861674" MODIFIED="1238174395357" TEXT="Displays rejections to user">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238171939475" FOLDED="true" ID="Freemind_Link_1489528397" MODIFIED="1238174395358" TEXT="Catches errors">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171945810" ID="Freemind_Link_156063273" MODIFIED="1238171972962" TEXT="Should be only rejections; other errors &#xa;are handled by order(sim)"/>
</node>
</node>
</node>
</node>
<node CREATED="1238431453361" FOLDED="true" ID="Freemind_Link_595977621" MODIFIED="1238445457383" TEXT="Bug 1969">
<icon BUILTIN="button_ok"/>
<node CREATED="1238185942456" FOLDED="true" ID="Freemind_Link_405704848" MODIFIED="1238431480265" TEXT="Snapshot Navigation and the SNAPSHOT State">
<icon BUILTIN="button_ok"/>
<node CREATED="1238190921792" ID="Freemind_Link_1311836518" MODIFIED="1238190995647" TEXT="The &quot;latest time&quot; is the latest sim time &#xa;achieved for this scenario.  There might or might&#xa;not be a snapshot at the latest time.">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238190851871" FOLDED="true" ID="Freemind_Link_746914711" MODIFIED="1238431338513" TEXT="Navigation">
<icon BUILTIN="button_ok"/>
<node CREATED="1237994176614" ID="Freemind_Link_336164682" MODIFIED="1238189988024" TEXT="Controls: first, previous, next, last">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994196662" ID="Freemind_Link_1852573157" MODIFIED="1238187633108" TEXT="&quot;First&quot; control replaces &quot;restart&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994206534" ID="Freemind_Link_1226705527" MODIFIED="1238187627189" TEXT="Use iPod icons: double triangles, with a vertical line for first and last">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994262438" ID="Freemind_Link_541192332" MODIFIED="1238190906394" TEXT="If there&apos;s no checkpoint at the current time, create one">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238191030192" FOLDED="true" ID="Freemind_Link_322032318" MODIFIED="1238431348609" TEXT="SNAPSHOT State">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191408045" FOLDED="true" ID="Freemind_Link_1598909806" MODIFIED="1238431334330" TEXT="Enter the SNAPSHOT state:">
<icon BUILTIN="button_ok"/>
<node CREATED="1237994284725" ID="Freemind_Link_1731247325" MODIFIED="1238194043206" TEXT="On loading a snapshot prior to the &quot;latest time&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238191433694" ID="Freemind_Link_930869996" MODIFIED="1238194369869" TEXT="On loading a scenario that was saved in the SNAPSHOT state">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238015602360" FOLDED="true" ID="Freemind_Link_541498746" MODIFIED="1238431334329" TEXT="In SNAPSHOT, most orders are disabled">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191465582" ID="Freemind_Link_1154318956" MODIFIED="1238191495508" TEXT="Prevents history from being changed">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238015609784" ID="Freemind_Link_701333418" MODIFIED="1238194054864" TEXT="Must leave SNAPSHOT explicitly to change things">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238192076044" ID="Freemind_Link_789581497" MODIFIED="1238194054862" TEXT="Leaving SNAPSHOT at time T&lt; latest makes T the latest time&#xa;and purges all snapshots with time &gt; T.">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238191530429" FOLDED="true" ID="Freemind_Link_1217471197" MODIFIED="1238194088230" TEXT="Leave the SNAPSHOT state:">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191067727" FOLDED="true" ID="Freemind_Link_1871259741" MODIFIED="1238194064630" TEXT="Implicitly, by returning to the snapshot for the &quot;latest time&quot;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191719725" ID="Freemind_Link_1721476881" MODIFIED="1238191722487" TEXT="Enter PAUSED."/>
</node>
<node CREATED="1238191576830" FOLDED="true" ID="Freemind_Link_1270538436" MODIFIED="1238194084525" TEXT="Explicitly, by pressing Run/Pause button">
<icon BUILTIN="button_ok"/>
<node CREATED="1238194072375" ID="Freemind_Link_1499229190" MODIFIED="1238194077761" TEXT="Asks user to confirm"/>
<node CREATED="1238191626750" ID="Freemind_Link_177796372" MODIFIED="1238191639415" TEXT="Re-enters time stream at current snapshot&apos;s time"/>
<node CREATED="1238191603150" ID="Freemind_Link_1262506582" MODIFIED="1238191615710" TEXT="Enter PREP if at time 0"/>
<node CREATED="1238191648189" ID="Freemind_Link_926597207" MODIFIED="1238191655095" TEXT="Enter PAUSED if at time &gt; 0"/>
<node CREATED="1238191655774" ID="Freemind_Link_986079587" MODIFIED="1238191681255" TEXT="Purge snapshots with time &gt; now"/>
</node>
</node>
<node CREATED="1238194101784" ID="Freemind_Link_1461508952" MODIFIED="1238428123360" TEXT="Check orders, to see if any should be valid in SNAPSHOT">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238015681529" FOLDED="true" ID="Freemind_Link_1517558552" MODIFIED="1238428648951" TEXT="Need special handling for GUI interactions">
<icon BUILTIN="button_ok"/>
<node CREATED="1238015700680" ID="Freemind_Link_1107307253" MODIFIED="1238015705266" TEXT="E.g., dragging units"/>
</node>
</node>
<node CREATED="1238425808630" FOLDED="true" ID="Freemind_Link_1294854083" MODIFIED="1238427813545" TEXT="Reflections over the weekend">
<icon BUILTIN="button_ok"/>
<node CREATED="1238425817574" ID="Freemind_Link_1746054516" MODIFIED="1238427813545" TEXT="Change WAYBACK to SNAPSHOT">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238425826309" FOLDED="true" ID="Freemind_Link_1869494239" MODIFIED="1238427813547" TEXT="Add &quot;scenario snapshot latest&quot;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238425850886" ID="Freemind_Link_1304559035" MODIFIED="1238425855888" TEXT="Returns tick of last snapshot"/>
</node>
<node CREATED="1238425857494" FOLDED="true" ID="Freemind_Link_902008359" MODIFIED="1238427813547" TEXT="Add &quot;scenario snapshot current&quot;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238425865095" ID="Freemind_Link_951007981" MODIFIED="1238425984039" TEXT="Returns index of current snapshot"/>
<node CREATED="1238425903286" ID="Freemind_Link_1552120527" MODIFIED="1238425996496" TEXT="Time 0 snapshot is snapshot 0"/>
</node>
<node CREATED="1238425917221" ID="Freemind_Link_462603546" MODIFIED="1238427813546" TEXT="In appwin, for state: &quot;Snapshot 2&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238426025702" FOLDED="true" ID="Freemind_Link_274922866" MODIFIED="1238427813546" TEXT="In Mr. Peabody&apos;s message: ">
<icon BUILTIN="button_ok"/>
<node CREATED="1238426042773" ID="Freemind_Link_958522936" MODIFIED="1238426053728" TEXT="You can use wayback machine to re-enter timestream here in snapshot 2"/>
<node CREATED="1238426054437" ID="Freemind_Link_836263563" MODIFIED="1238426070224" TEXT="However, snapshots 3 through 7 will be erased."/>
</node>
</node>
<node CREATED="1238426269478" FOLDED="true" ID="Freemind_Link_674135358" MODIFIED="1238431325025" TEXT="Before we&apos;re done:">
<icon BUILTIN="button_ok"/>
<node CREATED="1238426273798" ID="Freemind_Link_918478796" MODIFIED="1238431325026" TEXT="scenario(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238426283366" ID="Freemind_Link_990041422" MODIFIED="1238431325026" TEXT="sim(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
<node CREATED="1238445403725" FOLDED="true" ID="Freemind_Link_1772844702" MODIFIED="1238445426051" TEXT="Bug 1972">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436555694" FOLDED="true" ID="Freemind_Link_342947994" MODIFIED="1238445426053" TEXT="Integrate gram(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436679903" FOLDED="true" ID="Freemind_Link_135625100" MODIFIED="1238445298523" TEXT="General Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436683200" FOLDED="true" ID="Freemind_Link_569591853" MODIFIED="1238436903958" TEXT="Require simlib(n) from Mars">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436878576" ID="Freemind_Link_369762958" MODIFIED="1238436903957" TEXT="Remove duplicate types from projectlib(n)">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1238170378694" FOLDED="true" ID="Freemind_Link_177076752" MODIFIED="1238445298524" TEXT="gram(n) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238432919607" ID="Freemind_Link_1700995736" MODIFIED="1238436625958" TEXT="Should not &quot;init&quot; on creation; explict &quot;init&quot; should be required.">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238432938983" ID="Freemind_Link_637646933" MODIFIED="1238441450435" TEXT="Then, when going from PREP to RUNNING, &quot;init&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238441475413" ID="Freemind_Link_136658914" MODIFIED="1238441487275" TEXT="Support full saveable(i) API">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238432951096" ID="Freemind_Link_1705604552" MODIFIED="1238441454910" TEXT="When loading a snapshot, just &quot;restore&quot;.">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238441497333" ID="Freemind_Link_1184606364" MODIFIED="1238444360733" TEXT="Update gram(n) man page.">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238170451558" FOLDED="true" ID="Freemind_Link_1408336574" MODIFIED="1238441470260" TEXT="sim(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1237842153584" ID="Freemind_Link_783424914" MODIFIED="1238441470259" TEXT="Initialize ARAM on PREP to RUNNING">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237822576953" ID="Freemind_Link_790187971" MODIFIED="1238441470260" TEXT="Advance ARAM during each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
<node CREATED="1238523242420" FOLDED="true" ID="Freemind_Link_1691404229" MODIFIED="1238523254783" TEXT="Bug 1977">
<icon BUILTIN="button_ok"/>
<node CREATED="1238517505067" FOLDED="true" ID="Freemind_Link_1707657656" MODIFIED="1238523257263" TEXT="executive(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238515842552" FOLDED="true" ID="Freemind_Link_1915241015" MODIFIED="1238519145359" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238515427129" FOLDED="true" ID="Freemind_Link_844971991" MODIFIED="1238519114540" TEXT="executive evaluates commands">
<node CREATED="1238519114897" ID="Freemind_Link_1914540238" MODIFIED="1238519121835" TEXT="In smartinterp(n): normal mode"/>
<node CREATED="1238519122193" ID="Freemind_Link_1286965969" MODIFIED="1238519127691" TEXT="In main interpreter: super mode"/>
<node CREATED="1238519128113" ID="Freemind_Link_1352086508" MODIFIED="1238519133211" TEXT="Mode is normal by default"/>
</node>
<node CREATED="1238519151393" ID="Freemind_Link_641585370" MODIFIED="1238519160891" TEXT="Standard commands provides"/>
</node>
<node CREATED="1238515911560" FOLDED="true" ID="Freemind_Link_1160302416" MODIFIED="1238522808441" TEXT="Initial commands">
<icon BUILTIN="button_ok"/>
<node CREATED="1238517766996" FOLDED="true" ID="Freemind_Link_77689403" MODIFIED="1238522798519" TEXT="As for JNEM">
<icon BUILTIN="button_ok"/>
<node CREATED="1238516022089" ID="Freemind_Link_761364225" MODIFIED="1238519075143" TEXT="=">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238517546949" ID="Freemind_Link_1561380635" MODIFIED="1238519075145" TEXT="call">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238517574485" ID="Freemind_Link_808267642" MODIFIED="1238519075144" TEXT="errtrace">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238517594565" ID="Freemind_Link_872156192" MODIFIED="1238519075144" TEXT="help">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238517633525" FOLDED="true" ID="Freemind_Link_1863745923" MODIFIED="1238517634638" TEXT="rdb">
<node CREATED="1238517635893" FOLDED="true" ID="Freemind_Link_194321371" MODIFIED="1238520425900" TEXT="eval">
<icon BUILTIN="button_ok"/>
<node CREATED="1238517646116" ID="Freemind_Link_915113069" MODIFIED="1238517664762" TEXT="Should be non-mutating eval">
<icon BUILTIN="messagebox_warning"/>
</node>
</node>
<node CREATED="1238517637797" FOLDED="true" ID="Freemind_Link_1704104328" MODIFIED="1238519080023" TEXT="query">
<icon BUILTIN="button_ok"/>
<node CREATED="1238520431086" ID="Freemind_Link_334799686" MODIFIED="1238520438676" TEXT="Should be non-mutating query">
<icon BUILTIN="messagebox_warning"/>
</node>
</node>
<node CREATED="1238517640964" ID="Freemind_Link_1691260560" MODIFIED="1238519080024" TEXT="schema">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238517642932" ID="Freemind_Link_1577140831" MODIFIED="1238519080024" TEXT="tables">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238517850836" ID="Freemind_Link_890276526" MODIFIED="1238519975949" TEXT="super">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238517788404" FOLDED="true" ID="Freemind_Link_1327644782" MODIFIED="1238522798521" TEXT="Standard Tcl">
<icon BUILTIN="button_ok"/>
<node CREATED="1238517555028" ID="Freemind_Link_336239801" MODIFIED="1238518996200" TEXT="file">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238521677883" ID="Freemind_Link_322452147" MODIFIED="1238521681354" TEXT="pwd">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238517557093" ID="Freemind_Link_1549074195" MODIFIED="1238518996199" TEXT="source">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238517838340" FOLDED="true" ID="Freemind_Link_1280478175" MODIFIED="1238522798520" TEXT="New commands">
<icon BUILTIN="button_ok"/>
<node CREATED="1238515945799" FOLDED="true" ID="Freemind_Link_1381950726" MODIFIED="1238518990599" TEXT="usermode normal|super">
<icon BUILTIN="button_ok"/>
<node CREATED="1238515960729" ID="Freemind_Link_72827201" MODIFIED="1238515972274" TEXT="Switchs CLI from executive to main interpreter"/>
<node CREATED="1238515876152" ID="Freemind_Link_79153490" MODIFIED="1238515899927" TEXT="Where possible, executive commands should &#xa;be available unchanged in both modes"/>
</node>
<node CREATED="1238517565684" FOLDED="true" ID="Freemind_Link_737549229" MODIFIED="1238518990600" TEXT="debug">
<icon BUILTIN="button_ok"/>
<node CREATED="1238517860836" ID="Freemind_Link_1866583885" MODIFIED="1238517865182" TEXT="Invokes debugger window"/>
</node>
</node>
</node>
<node CREATED="1238520446431" FOLDED="true" ID="Freemind_Link_763470462" MODIFIED="1238523154559" TEXT="scenariodb(n) changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238520453007" ID="Freemind_Link_212708590" MODIFIED="1238520468756" TEXT="safeeval">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238520457374" ID="Freemind_Link_749639267" MODIFIED="1238520468757" TEXT="safequery">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238520477438" FOLDED="true" ID="Freemind_Link_1637082210" MODIFIED="1238522808439" TEXT="Docs">
<icon BUILTIN="button_ok"/>
<node CREATED="1238520480526" FOLDED="true" ID="Freemind_Link_840517934" MODIFIED="1238522658032" TEXT="executive(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238520514430" ID="Freemind_Link_400194349" MODIFIED="1238520516552" TEXT="New manpage"/>
</node>
<node CREATED="1238520490493" FOLDED="true" ID="Freemind_Link_239577766" MODIFIED="1238522660848" TEXT="athena_sim(1)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238520497614" ID="Freemind_Link_425104245" MODIFIED="1238520501224" TEXT="Add executive commands"/>
</node>
<node CREATED="1238520505918" FOLDED="true" ID="Freemind_Link_1244815078" MODIFIED="1238522791423" TEXT="scenariodb(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238520509038" ID="Freemind_Link_1699477044" MODIFIED="1238520512120" TEXT="New methods"/>
</node>
</node>
</node>
</node>
<node CREATED="1238623410607" FOLDED="true" ID="Freemind_Link_1041304361" MODIFIED="1238623423217" TEXT="Bug 1979">
<icon BUILTIN="button_ok"/>
<node CREATED="1238529943953" FOLDED="true" ID="Freemind_Link_1349877538" MODIFIED="1238623423214" TEXT="Parameter DB">
<icon BUILTIN="button_ok"/>
<node CREATED="1238601195213" FOLDED="true" ID="Freemind_Link_1161201353" MODIFIED="1238601243571" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238515595960" FOLDED="true" ID="Freemind_Link_141208017" MODIFIED="1238515603731" TEXT="parm(sim) module">
<node CREATED="1238515375033" FOLDED="true" ID="Freemind_Link_1406882786" MODIFIED="1238601212059" TEXT="Saved with scenario">
<node CREATED="1238515671336" ID="Freemind_Link_806121005" MODIFIED="1238515679170" TEXT="saveable(i)"/>
</node>
<node CREATED="1238515651864" ID="Freemind_Link_690240476" MODIFIED="1238601212060" TEXT="Delegates to parmset(n)"/>
<node CREATED="1238515467816" ID="Freemind_Link_1533485914" MODIFIED="1238515474547" TEXT="Edited/viewed via executive commands"/>
<node CREATED="1238515479466" ID="Freemind_Link_1911340208" MODIFIED="1238515738067" TEXT="Mutating executive commands implemented using orders"/>
</node>
<node CREATED="1238601222845" FOLDED="true" ID="Freemind_Link_1662627383" MODIFIED="1238601226632" TEXT="appwin(sim)">
<node CREATED="1238601227102" ID="Freemind_Link_74321911" MODIFIED="1238601235863" TEXT="File menu items for some operations"/>
</node>
</node>
<node CREATED="1238529980955" FOLDED="true" ID="Freemind_Link_702308582" MODIFIED="1238601246387" TEXT="parmset(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238529984027" ID="Freemind_Link_1724568535" MODIFIED="1238535450622" TEXT="Must be a saveable(i)">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238620711301" FOLDED="true" ID="Freemind_Link_300045853" MODIFIED="1238620761603" TEXT="parmdb(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238620715669" ID="Freemind_Link_1580686067" MODIFIED="1238620732195" TEXT="Defined in projectlib(n)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238601356669" FOLDED="true" ID="Freemind_Link_1860483455" MODIFIED="1238601465387" TEXT="Features over parmset(n):">
<icon BUILTIN="button_ok"/>
<node CREATED="1238601364605" ID="Freemind_Link_889391443" MODIFIED="1238601433531" TEXT="Defines app-specific parameters">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238601373133" FOLDED="true" ID="Freemind_Link_1952228425" MODIFIED="1238601430243" TEXT="Manages defaults file">
<icon BUILTIN="button_ok"/>
<node CREATED="1238515533641" ID="Freemind_Link_842742089" MODIFIED="1238539318030" TEXT="Saves to ~/.athena/defaults.parmdb">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238601399885" ID="Freemind_Link_1075210070" MODIFIED="1238601430244" TEXT="parm defaults clear">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238601405005" ID="Freemind_Link_1433234837" MODIFIED="1238601430244" TEXT="parm defaults load">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238601408637" ID="Freemind_Link_267129739" MODIFIED="1238601430245" TEXT="parm defaults save">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1238620739685" ID="Freemind_Link_1447108018" MODIFIED="1238620759499" TEXT="parmdb(n) man page">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238620745141" FOLDED="true" ID="Freemind_Link_838750040" MODIFIED="1238620759500" TEXT="parmdb(5) man page">
<icon BUILTIN="button_ok"/>
<node CREATED="1238620750277" ID="Freemind_Link_1201964797" MODIFIED="1238620759501" TEXT="Lists all of the parameter definitions">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1238601307806" FOLDED="true" ID="Freemind_Link_1112092757" MODIFIED="1238620784131" TEXT="parm(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600291984" FOLDED="true" ID="Freemind_Link_893607280" MODIFIED="1238600295962" TEXT="Orders">
<node CREATED="1238600455423" ID="Freemind_Link_959112501" MODIFIED="1238600501181" TEXT="PARM:* orders are valid only in PREP">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238600307119" ID="Freemind_Link_715391555" MODIFIED="1238600425781" TEXT="PARM:IMPORT">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238600303039" ID="Freemind_Link_969505393" MODIFIED="1238600425782" TEXT="PARM:RESET">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238600296367" ID="Freemind_Link_152421907" MODIFIED="1238600425782" TEXT="PARM:SET">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238600129776" FOLDED="true" ID="Freemind_Link_1148659909" MODIFIED="1238601128195" TEXT="Executive commands">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600584174" FOLDED="true" ID="Freemind_Link_275461164" MODIFIED="1238601128196" TEXT="parm defaults">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600632302" ID="Freemind_Link_1129667184" MODIFIED="1238601128198" TEXT="parm defaults clear">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238600626223" ID="Freemind_Link_1341646343" MODIFIED="1238601128199" TEXT="parm defaults save">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238600536047" FOLDED="true" ID="Freemind_Link_316680127" MODIFIED="1238601128198" TEXT="parm export">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600541535" ID="Freemind_Link_255379407" MODIFIED="1238600579512" TEXT="via parmset(n) save."/>
</node>
<node CREATED="1238600143440" FOLDED="true" ID="Freemind_Link_414695118" MODIFIED="1238601134259" TEXT="parm get">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600157664" ID="Freemind_Link_1241954760" MODIFIED="1238600160809" TEXT="As for parmset(n)"/>
</node>
<node CREATED="1238600522799" FOLDED="true" ID="Freemind_Link_465712757" MODIFIED="1238601128197" TEXT="parm import">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600527359" ID="Freemind_Link_1211738009" MODIFIED="1238600532713" TEXT="via PARM:IMPORT"/>
</node>
<node CREATED="1238600187839" FOLDED="true" ID="Freemind_Link_4114571" MODIFIED="1238600360751" TEXT="parm list">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600194799" ID="Freemind_Link_283345935" MODIFIED="1238600208585" TEXT="Throws error if no parameters match pattern"/>
</node>
<node CREATED="1238600176639" FOLDED="true" ID="Freemind_Link_1401098276" MODIFIED="1238600360751" TEXT="parm names">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600182463" ID="Freemind_Link_323506328" MODIFIED="1238600186137" TEXT="As for parmset(n)"/>
</node>
<node CREATED="1238600268303" FOLDED="true" ID="Freemind_Link_1163653918" MODIFIED="1238600360750" TEXT="parm reset">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600271119" ID="Freemind_Link_151650595" MODIFIED="1238600275609" TEXT="via PARM:RESET"/>
</node>
<node CREATED="1238600163903" FOLDED="true" ID="Freemind_Link_86917500" MODIFIED="1238600360750" TEXT="parm set">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600171056" ID="Freemind_Link_577278033" MODIFIED="1238600174953" TEXT="via PARM:SET"/>
</node>
</node>
<node CREATED="1238601333261" ID="Freemind_Link_847606572" MODIFIED="1238612904571" TEXT="Test suite">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238601329405" ID="Freemind_Link_572383553" MODIFIED="1238618723351" TEXT="parm(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238538679737" FOLDED="true" ID="Freemind_Link_171608646" MODIFIED="1238539831797" TEXT="scenario(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238538682441" ID="Freemind_Link_1934207075" MODIFIED="1238539827709" TEXT="Reset parms/load defaults on new">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238538699450" ID="Freemind_Link_831454820" MODIFIED="1238539829773" TEXT="Parms are loaded automatically on open">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238600364831" FOLDED="true" ID="Freemind_Link_1685248817" MODIFIED="1238600420541" TEXT="order(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600371823" FOLDED="true" ID="Freemind_Link_766850284" MODIFIED="1238600420542" TEXT="Add &quot;cli&quot; interface type">
<icon BUILTIN="button_ok"/>
<node CREATED="1238600382751" ID="Freemind_Link_348615868" MODIFIED="1238600406800" TEXT="Mostly like &quot;gui&quot;"/>
<node CREATED="1238600398863" ID="Freemind_Link_387634540" MODIFIED="1238600415881" TEXT="Formats REJECT errors for display at CLI"/>
</node>
</node>
<node CREATED="1238515491161" FOLDED="true" ID="Freemind_Link_378976541" MODIFIED="1238515756547" TEXT="File Menu">
<node CREATED="1238515756921" ID="Freemind_Link_823183849" MODIFIED="1238538245904" TEXT="Export Parameters">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238515769287" FOLDED="true" ID="Freemind_Link_1680113721" MODIFIED="1238538248312" TEXT="Import Parameters">
<icon BUILTIN="button_ok"/>
<node CREATED="1238536745870" ID="Freemind_Link_398521916" MODIFIED="1238536749175" TEXT="PARM:IMPORT"/>
</node>
<node CREATED="1238515779512" FOLDED="true" ID="Freemind_Link_310233598" MODIFIED="1238539823325" TEXT="Save Parameters as Default">
<icon BUILTIN="button_ok"/>
<node CREATED="1238515547016" ID="Freemind_Link_334273028" MODIFIED="1238539820813" TEXT="File loaded when new scenario created">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238515792473" FOLDED="true" ID="Freemind_Link_1422487824" MODIFIED="1238539320734" TEXT="Clear Defaults">
<icon BUILTIN="button_ok"/>
<node CREATED="1238515799385" ID="Freemind_Link_1444315065" MODIFIED="1238515813058" TEXT="Deletes ~/.athena/defaults.parmdb"/>
</node>
</node>
<node CREATED="1238529962427" FOLDED="true" ID="Freemind_Link_437307686" MODIFIED="1238601295943" TEXT="sim(sim) Changes">
<node CREATED="1238529965467" ID="Freemind_Link_322166406" MODIFIED="1238601169239" TEXT="Use sim.tickSize"/>
</node>
<node CREATED="1238536838365" FOLDED="true" ID="Freemind_Link_1411471581" MODIFIED="1238536840312" TEXT="Other docs">
<node CREATED="1238604292070" FOLDED="true" ID="Freemind_Link_1366153104" MODIFIED="1238621962377" TEXT="scenario(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238604295910" ID="Freemind_Link_1806862995" MODIFIED="1238604298880" TEXT="-ignoredefaultparms"/>
</node>
<node CREATED="1238604486614" FOLDED="true" ID="Freemind_Link_126609008" MODIFIED="1238621962378" TEXT="app(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238604490470" ID="Freemind_Link_1264405500" MODIFIED="1238604493792" TEXT="-ignoredefaultparms"/>
</node>
<node CREATED="1238536840781" ID="Freemind_Link_1159218997" MODIFIED="1238622714743" TEXT="orders(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238603090409" ID="Freemind_Link_449583637" MODIFIED="1238623222998" TEXT="athena_sim(1)">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
<node CREATED="1238685198893" FOLDED="true" ID="Freemind_Link_8568626" MODIFIED="1238685219899" TEXT="Bug 1985">
<icon BUILTIN="button_ok"/>
<node CREATED="1238519780623" FOLDED="true" ID="Freemind_Link_1494103863" MODIFIED="1238685219900" TEXT="gram(n): clear">
<icon BUILTIN="button_ok"/>
<node CREATED="1238519786767" ID="Freemind_Link_1483383607" MODIFIED="1238519794346" TEXT="Uninitializes the simulation"/>
<node CREATED="1238519798736" ID="Freemind_Link_1833850300" MODIFIED="1238519825629" TEXT="Use when returning to PREP from RUNNING if paused at time 0"/>
</node>
</node>
<node CREATED="1238698182610" FOLDED="true" ID="Freemind_Link_137290562" MODIFIED="1238698192736" TEXT="Bug 1988">
<icon BUILTIN="button_ok"/>
<node CREATED="1238513450107" FOLDED="true" ID="Freemind_Link_7414174" MODIFIED="1238698192737" TEXT="Display ARAM Outputs">
<icon BUILTIN="button_ok"/>
<node CREATED="1238686916746" FOLDED="true" ID="Freemind_Link_727602711" MODIFIED="1238686927023" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238513902140" FOLDED="true" ID="Freemind_Link_1424491231" MODIFIED="1238686924799" TEXT="Easy Outputs">
<node CREATED="1238513462364" FOLDED="true" ID="Freemind_Link_624747327" MODIFIED="1238513471062" TEXT="Satisfaction level">
<node CREATED="1238513537516" ID="Freemind_Link_1445697922" MODIFIED="1238513541878" TEXT="In Sat tab"/>
</node>
<node CREATED="1238513471468" FOLDED="true" ID="Freemind_Link_1882141234" MODIFIED="1238513498038" TEXT="Satisfaction mood">
<node CREATED="1238513545372" ID="Freemind_Link_1744898646" MODIFIED="1238513567142" TEXT="CIVs: In nbgroups tab"/>
<node CREATED="1238513567964" ID="Freemind_Link_1244954265" MODIFIED="1238513580918" TEXT="ORGs: Mood is just CAS; no need to display it."/>
</node>
<node CREATED="1238513475964" FOLDED="true" ID="Freemind_Link_1264468866" MODIFIED="1238513480118" TEXT="Cooperation level">
<node CREATED="1238513589405" ID="Freemind_Link_585181092" MODIFIED="1238513592214" TEXT="In Coop tab"/>
</node>
</node>
<node CREATED="1238513521053" FOLDED="true" ID="Freemind_Link_1376958068" MODIFIED="1238513621094" TEXT="Join GRAM tables with GUI views">
<node CREATED="1238513624477" ID="Freemind_Link_632643494" MODIFIED="1238687154563" TEXT="Ensure that GRAM tables are invalid in PREP state"/>
<node CREATED="1238687003417" ID="Freemind_Link_424287950" MODIFIED="1238687020051" TEXT="Use left outer join so that NULLs are OK"/>
<node CREATED="1238687021209" FOLDED="true" ID="Freemind_Link_783894674" MODIFIED="1238687032979" TEXT="In view, convert NULL to initial value, or 0.0">
<node CREATED="1238687039385" ID="Freemind_Link_760283125" MODIFIED="1238687126441" TEXT="Tablelist can&apos;t cope with non-numeric values&#xa;in columns sorted as floating point."/>
</node>
</node>
</node>
<node CREATED="1238686906474" FOLDED="true" ID="Freemind_Link_1024916433" MODIFIED="1238686911906" TEXT="sim(sim) changes">
<node CREATED="1238687188600" FOLDED="true" ID="Freemind_Link_1421268975" MODIFIED="1238688061317" TEXT="&quot;clear&quot; GRAM on return to PREP">
<icon BUILTIN="button_ok"/>
<node CREATED="1238687205369" ID="Freemind_Link_1551832867" MODIFIED="1238687213139" TEXT="Ensures GRAM tables are invalid in PREP state"/>
</node>
</node>
<node CREATED="1238687231961" FOLDED="true" ID="Freemind_Link_218414122" MODIFIED="1238693023622" TEXT="Outputs">
<node CREATED="1238687238921" FOLDED="true" ID="Freemind_Link_1573153266" MODIFIED="1238688071189" TEXT="Satisfaction level">
<icon BUILTIN="button_ok"/>
<node CREATED="1238687249913" ID="Freemind_Link_1923784955" MODIFIED="1238688071190" TEXT="Add to gui_sat_ngc view">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238692991085" ID="Freemind_Link_341350653" MODIFIED="1238693001610" TEXT="satbrowser(sim) uses browser_base(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687283705" ID="Freemind_Link_1746018501" MODIFIED="1238688071190" TEXT="Display in satbrowser(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687290745" ID="Freemind_Link_467958280" MODIFIED="1238688071190" TEXT="Update satbrowser(sim) on each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238694049754" FOLDED="true" ID="Freemind_Link_1183215814" MODIFIED="1238695436776" TEXT="nbgroup mood">
<icon BUILTIN="button_ok"/>
<node CREATED="1238694058762" ID="Freemind_Link_953932921" MODIFIED="1238695436774" TEXT="Add to gui_nbgroups">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238692991085" ID="Freemind_Link_1210867595" MODIFIED="1238695436775" TEXT="nbgroupbrowser(sim) uses browser_base(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238694076171" ID="Freemind_Link_511189845" MODIFIED="1238695436775" TEXT="Display in nbgroupbrowser(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238694084410" ID="Freemind_Link_1820930935" MODIFIED="1238695436775" TEXT="Update nbgroupbrowser(sim) on each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238687238921" FOLDED="true" ID="Freemind_Link_1557291643" MODIFIED="1238697284794" TEXT="Cooperation Level">
<icon BUILTIN="button_ok"/>
<node CREATED="1238687249913" ID="Freemind_Link_228174065" MODIFIED="1238696764835" TEXT="Add to gui_coop_nfg view">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238692991085" ID="Freemind_Link_806824872" MODIFIED="1238697284795" TEXT="coopbrowser(sim) uses browser_base(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687283705" ID="Freemind_Link_1418401896" MODIFIED="1238697284796" TEXT="Display in coopbrowser(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687290745" ID="Freemind_Link_579471615" MODIFIED="1238697284795" TEXT="Update coopbrowser(sim) on each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1238692222334" FOLDED="true" ID="Freemind_Link_1205103087" MODIFIED="1238693014892" TEXT="Browser changes:">
<icon BUILTIN="button_ok"/>
<node CREATED="1238692232062" FOLDED="true" ID="Freemind_Link_444483456" MODIFIED="1238693654817" TEXT="tablebrowser(n):">
<node CREATED="1238692299374" ID="Freemind_Link_559358856" MODIFIED="1238693652025" TEXT="&quot;toolbar&quot; queries the toolbar">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238693643339" ID="Freemind_Link_135985490" MODIFIED="1238697697417" TEXT="Update manpage">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238692311022" FOLDED="true" ID="Freemind_Link_1565959369" MODIFIED="1238693014891" TEXT="browser_base(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238692323469" ID="Freemind_Link_428964578" MODIFIED="1238692325848" TEXT="New module"/>
<node CREATED="1238692326269" ID="Freemind_Link_474762533" MODIFIED="1238692331032" TEXT="Common behavior among browsers"/>
<node CREATED="1238692335887" ID="Freemind_Link_985382742" MODIFIED="1238692345624" TEXT="reloads only when mapped"/>
</node>
</node>
<node CREATED="1238513511116" FOLDED="true" ID="Freemind_Link_774003595" MODIFIED="1238697716513" TEXT="Subsequent work, as needed">
<icon BUILTIN="flag"/>
<node CREATED="1238514000940" ID="Freemind_Link_682310181" MODIFIED="1238514005925" TEXT="Time Series Plots"/>
<node CREATED="1238513993932" ID="Freemind_Link_333427434" MODIFIED="1238514038997" TEXT="History and Causality Visualization"/>
<node CREATED="1238513921852" ID="Freemind_Link_228918684" MODIFIED="1238513945126" TEXT="Roll-ups other than mood"/>
</node>
</node>
</node>
<node CREATED="1238711795272" FOLDED="true" ID="Freemind_Link_716187279" MODIFIED="1238711809269" TEXT="Bug 1991">
<icon BUILTIN="button_ok"/>
<node CREATED="1238693698012" FOLDED="true" ID="Freemind_Link_1599806815" MODIFIED="1238711809271" TEXT="Update browsers to use browser_base(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238449514469" FOLDED="true" ID="Freemind_Link_165845852" MODIFIED="1238449524783" TEXT="Browsers should update themselves only when:">
<node CREATED="1238449525588" ID="Freemind_Link_1160705008" MODIFIED="1238449528014" TEXT="They are visible"/>
<node CREATED="1238449528723" ID="Freemind_Link_403784776" MODIFIED="1238449531726" TEXT="They become visible"/>
</node>
</node>
</node>
<node CREATED="1238780924375" FOLDED="true" ID="Freemind_Link_116125640" MODIFIED="1238780957101" TEXT="Bug 1993">
<icon BUILTIN="button_ok"/>
<node CREATED="1238773465938" FOLDED="true" ID="Freemind_Link_1081743270" MODIFIED="1238780957099" TEXT="Purging Session Data">
<icon BUILTIN="button_ok"/>
<node CREATED="1238773796340" FOLDED="true" ID="Freemind_Link_1195416061" MODIFIED="1238774710311" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238773503428" FOLDED="true" ID="Freemind_Link_1671044529" MODIFIED="1238773530798" TEXT="Session defined">
<node CREATED="1238773516723" ID="Freemind_Link_634905701" MODIFIED="1238773548382" TEXT="Created when Athena is invoked"/>
<node CREATED="1238773591347" ID="Freemind_Link_1626646897" MODIFIED="1238773670349" TEXT="~/.athena/&lt;pid&gt;/..."/>
<node CREATED="1238773548836" FOLDED="true" ID="Freemind_Link_814150636" MODIFIED="1238773553710" TEXT="Contains working data">
<node CREATED="1238773553988" ID="Freemind_Link_267213790" MODIFIED="1238773556302" TEXT="RDB"/>
<node CREATED="1238773557124" ID="Freemind_Link_1110751735" MODIFIED="1238773558382" TEXT="Logs"/>
</node>
</node>
<node CREATED="1237479159342" FOLDED="true" ID="Freemind_Link_871279502" MODIFIED="1238773834334" TEXT="At present, the session is deleted on exit">
<node CREATED="1238773840722" ID="Freemind_Link_1891692293" MODIFIED="1238773858302" TEXT="Except for Control-C"/>
<node CREATED="1238773872931" ID="Freemind_Link_1484702799" MODIFIED="1238773891757" TEXT="Makes post-mortems difficult"/>
<node CREATED="1238773937795" ID="Freemind_Link_758110641" MODIFIED="1238773943501" TEXT="Undeleted sessions accumulate"/>
</node>
<node CREATED="1237479168366" ID="Freemind_Link_1109931458" MODIFIED="1238773972061" TEXT="Should not delete sessions on exit"/>
<node CREATED="1237479186254" FOLDED="true" ID="Freemind_Link_645278139" MODIFIED="1237479202138" TEXT="Should purge older sessions">
<node CREATED="1237479203454" ID="Freemind_Link_803925631" MODIFIED="1238773992285" TEXT="workdir(n) writes a timestamp file to session periodically"/>
<node CREATED="1237479218718" ID="Freemind_Link_788398980" MODIFIED="1238774132156" TEXT="At startup, app(sim) asks workdir(n) to delete old sessions"/>
<node CREATED="1238774084691" ID="Freemind_Link_141001743" MODIFIED="1238774106812" TEXT="Probably want an app parmset for preferences like this"/>
</node>
</node>
<node CREATED="1238774147906" FOLDED="true" ID="Freemind_Link_77019026" MODIFIED="1238774152893" TEXT="workdir(n) changes">
<node CREATED="1238774166563" ID="Freemind_Link_920312791" MODIFIED="1238779905589" TEXT="Touches work directory once every 10 seconds using [file mtime]">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238779831048" ID="Freemind_Link_1067526789" MODIFIED="1238779905590" TEXT="Sessions are considered &quot;inactive&quot; when their&#xa;[file mtime] is more than ten minutes.">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238774182963" FOLDED="true" ID="Freemind_Link_301498328" MODIFIED="1238779905590" TEXT="On request, purges inactive sessions older than X hours">
<icon BUILTIN="button_ok"/>
<node CREATED="1238779884423" ID="Freemind_Link_1673946815" MODIFIED="1238779891633" TEXT="X may be zero; deletes all inactive sessions"/>
</node>
<node CREATED="1238776270094" ID="Freemind_Link_254328164" MODIFIED="1238776275704" TEXT="workdir(n) man page"/>
</node>
<node CREATED="1238774598113" FOLDED="true" ID="Freemind_Link_1960782731" MODIFIED="1238779911597" TEXT="app(sim) changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238774609073" ID="Freemind_Link_865984231" MODIFIED="1238779909381" TEXT="At start-up, purges old sessions">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238774632210" ID="Freemind_Link_1420207289" MODIFIED="1238779909382" TEXT="Time limit is a module variable for now">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
<node CREATED="1238795410314" FOLDED="true" ID="Freemind_Link_725402553" MODIFIED="1238795425855" TEXT="Bug 1994">
<icon BUILTIN="button_ok"/>
<node CREATED="1238790568009" FOLDED="true" ID="Freemind_Link_283785606" MODIFIED="1238795425857" TEXT="Athena Preferences">
<icon BUILTIN="button_ok"/>
<node CREATED="1238790576611" FOLDED="true" ID="Freemind_Link_1869037937" MODIFIED="1238790715185" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238790589858" ID="Freemind_Link_876404051" MODIFIED="1238790599069" TEXT="User Preferences"/>
<node CREATED="1238790870899" ID="Freemind_Link_1922805704" MODIFIED="1238790874700" TEXT="Save in parmset(n)"/>
<node CREATED="1238790599522" FOLDED="true" ID="Freemind_Link_1284540224" MODIFIED="1238790606270" TEXT="Distinct from parmdb(5)">
<node CREATED="1238790606770" ID="Freemind_Link_500866297" MODIFIED="1238790618253" TEXT="Not saved with scenario"/>
<node CREATED="1238790618756" ID="Freemind_Link_1708916386" MODIFIED="1238790635645" TEXT="Does not affect simulated outcomes"/>
</node>
</node>
<node CREATED="1238792912399" FOLDED="true" ID="Freemind_Link_1750242408" MODIFIED="1238794999581" TEXT="projectlib(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238792918543" FOLDED="true" ID="Freemind_Link_1660212916" MODIFIED="1238793836562" TEXT="New module: prefs(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238790718611" FOLDED="true" ID="Freemind_Link_1756523700" MODIFIED="1238792104942" TEXT="Define prefs parmset(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238790652002" FOLDED="true" ID="Freemind_Link_400462421" MODIFIED="1238791390091" TEXT="session.purgeHours">
<node CREATED="1238790671554" ID="Freemind_Link_530725966" MODIFIED="1238790688498" TEXT="Age in hours at which old working directories&#xa;are purged."/>
</node>
</node>
<node CREATED="1238776508109" ID="Freemind_Link_1915926347" MODIFIED="1238792240854" TEXT="Save on &quot;prefs set&quot; and &quot;prefs reset&quot; to ~/.athena/prefs.parmdb">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238776478973" FOLDED="true" ID="Freemind_Link_503364" MODIFIED="1238792934424" TEXT="Subcommands">
<icon BUILTIN="button_ok"/>
<node CREATED="1238790746994" ID="Freemind_Link_1898931305" MODIFIED="1238792883671" TEXT="prefs get">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792333712" ID="Freemind_Link_1767537118" MODIFIED="1238792887128" TEXT="prefs help">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792029024" ID="Freemind_Link_1576981153" MODIFIED="1238792892360" TEXT="prefs list">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792952638" FOLDED="true" ID="Freemind_Link_462462831" MODIFIED="1238793834818" TEXT="prefs load">
<icon BUILTIN="button_ok"/>
<node CREATED="1238792966302" ID="Freemind_Link_1777682800" MODIFIED="1238792979512" TEXT="Loads prefs safely from ~/.athena/user.prefs"/>
</node>
<node CREATED="1238792038128" ID="Freemind_Link_582802530" MODIFIED="1238792898040" TEXT="prefs names">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792076608" ID="Freemind_Link_209039473" MODIFIED="1238792902952" TEXT="prefs reset">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792079343" ID="Freemind_Link_1396830684" MODIFIED="1238792909576" TEXT="prefs set">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
<node CREATED="1238793018350" FOLDED="true" ID="Freemind_Link_1861245492" MODIFIED="1238794999582" TEXT="executive(sim) changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238776574109" FOLDED="true" ID="Freemind_Link_564239719" MODIFIED="1238793034340" TEXT="Executive commands">
<icon BUILTIN="button_ok"/>
<node CREATED="1238790759027" ID="Freemind_Link_707589501" MODIFIED="1238793034341" TEXT="prefs get">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792339679" ID="Freemind_Link_40849393" MODIFIED="1238793034342" TEXT="prefs help">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792148752" ID="Freemind_Link_1947213094" MODIFIED="1238793034342" TEXT="prefs list">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792151072" ID="Freemind_Link_1078188004" MODIFIED="1238793034342" TEXT="prefs names">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792153344" ID="Freemind_Link_1383768154" MODIFIED="1238793034342" TEXT="prefs reset">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238792156144" ID="Freemind_Link_102345072" MODIFIED="1238793034341" TEXT="prefs set">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1238776458990" FOLDED="true" ID="Freemind_Link_470267986" MODIFIED="1238794999582" TEXT="app(sim) changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238776522926" FOLDED="true" ID="Freemind_Link_608684938" MODIFIED="1238793842106" TEXT="Loaded at startup if it exists">
<icon BUILTIN="button_ok"/>
<node CREATED="1238790911218" ID="Freemind_Link_650986051" MODIFIED="1238790957276" TEXT="Unless: app init -ignoreuser"/>
</node>
<node CREATED="1238793810524" ID="Freemind_Link_1733661689" MODIFIED="1238793842107" TEXT="Uses session.purgeHours">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238793061999" FOLDED="true" ID="Freemind_Link_893114428" MODIFIED="1238793064953" TEXT="Docs">
<node CREATED="1238793065262" ID="Freemind_Link_1669670684" MODIFIED="1238794711264" TEXT="prefs(n)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238793069006" ID="Freemind_Link_1211773133" MODIFIED="1238794711265" TEXT="prefs(5)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238793072335" ID="Freemind_Link_1020414574" MODIFIED="1238794989824" TEXT="athena_sim(1)">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
<node CREATED="1239210014055" FOLDED="true" ID="Freemind_Link_132577491" MODIFIED="1239210037070" TEXT="Bug 2037">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201483295" FOLDED="true" ID="Freemind_Link_689851774" MODIFIED="1239210037071" TEXT="nbstat(sim) inputs">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201535546" FOLDED="true" ID="Freemind_Link_1149165559" MODIFIED="1239203506963" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1239201540393" ID="Freemind_Link_443033548" MODIFIED="1239201568867" TEXT="Athena scenario lacks inputs required for nbstat"/>
<node CREATED="1239201573481" FOLDED="true" ID="Freemind_Link_677661726" MODIFIED="1239201579187" TEXT="Missing inputs:">
<node CREATED="1239201508889" ID="Freemind_Link_778445827" MODIFIED="1239201513507" TEXT="frcgroup demeanor"/>
<node CREATED="1239201514089" ID="Freemind_Link_1200100485" MODIFIED="1239201518227" TEXT="orggroup demeanor"/>
<node CREATED="1239201497305" ID="Freemind_Link_1016081835" MODIFIED="1239201508243" TEXT="nbgroup population"/>
</node>
<node CREATED="1239201587400" ID="Freemind_Link_1857323162" MODIFIED="1239201603667" TEXT="Add the inputs, and update the test suites and docs"/>
</node>
<node CREATED="1239201633672" FOLDED="true" ID="Freemind_Link_1989389568" MODIFIED="1239203746251" TEXT="scenariodb(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201639672" ID="Freemind_Link_1138615288" MODIFIED="1239203743851" TEXT="Add frcgroups.demeanor with default AVERAGE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201659337" ID="Freemind_Link_1245302417" MODIFIED="1239203743853" TEXT="Add orggroups.demeanor with default AVERAGE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201668265" ID="Freemind_Link_58497775" MODIFIED="1239203743852" TEXT="Add nbgroups.population with default 1">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239203533093" ID="Freemind_Link_1151333993" MODIFIED="1239203743852" TEXT="Convert test.adb">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239203775205" FOLDED="true" ID="Freemind_Link_1855706093" MODIFIED="1239203879132" TEXT="gui_views(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239203847429" ID="Freemind_Link_1782911728" MODIFIED="1239203879130" TEXT="Add demeanor to gui_frcgroups">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239203857412" ID="Freemind_Link_451215073" MODIFIED="1239203879132" TEXT="Add demeanor to gui_orggroups">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239203864885" ID="Freemind_Link_1251111335" MODIFIED="1239203879131" TEXT="Add population to gui_nbgroups">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239204170356" FOLDED="true" ID="Freemind_Link_55085766" MODIFIED="1239204246891" TEXT="sim(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239204173508" ID="Freemind_Link_550118914" MODIFIED="1239204246890" TEXT="Provide population to gram(n)">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239204823026" FOLDED="true" ID="Freemind_Link_1980129022" MODIFIED="1239206998204" TEXT="athena_test(1)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239204827874" ID="Freemind_Link_1578225378" MODIFIED="1239206998205" TEXT="Update ted entities with new parameters">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239201690393" FOLDED="true" ID="Freemind_Link_1154375970" MODIFIED="1239207692419" TEXT="frcgroup(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201706041" FOLDED="true" ID="Freemind_Link_514614881" MODIFIED="1239206988756" TEXT="Add demeanor to orders">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201724857" ID="Freemind_Link_611072098" MODIFIED="1239207200024" TEXT="GROUP:FORCE:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201730217" ID="Freemind_Link_1545237383" MODIFIED="1239207200023" TEXT="GROUP:FORCE:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201735945" ID="Freemind_Link_20345149" MODIFIED="1239207200023" TEXT="GROUP:FORCE:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239201815752" FOLDED="true" ID="Freemind_Link_1383174235" MODIFIED="1239207692420" TEXT="Update tests">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201839128" ID="Freemind_Link_60664309" MODIFIED="1239207172236" TEXT="010-frcgroup.test">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201844759" ID="Freemind_Link_87985674" MODIFIED="1239207692420" TEXT="020-GROUP-FORCE.test">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1239202244648" FOLDED="true" ID="Freemind_Link_1535812733" MODIFIED="1239204260419" TEXT="frcgroupbrowser(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239202249784" ID="Freemind_Link_1434924615" MODIFIED="1239204260420" TEXT="Display demeanor">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239201747544" FOLDED="true" ID="Freemind_Link_514763984" MODIFIED="1239209355481" TEXT="orggroup(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201750953" FOLDED="true" ID="Freemind_Link_70999843" MODIFIED="1239206991196" TEXT="Add demeanor to orders">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201757992" ID="Freemind_Link_489050888" MODIFIED="1239207200022" TEXT="GROUP:ORGANIZATION:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201763688" ID="Freemind_Link_601525599" MODIFIED="1239207200022" TEXT="GROUP:ORGANIZATION:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201768937" ID="Freemind_Link_7245376" MODIFIED="1239207200021" TEXT="GROUP:ORGANIZATION:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239201891304" FOLDED="true" ID="Freemind_Link_1547139017" MODIFIED="1239209355481" TEXT="Update tests">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201895560" ID="Freemind_Link_810095979" MODIFIED="1239209355479" TEXT="010-orggroup.test">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201899816" ID="Freemind_Link_1389408841" MODIFIED="1239209355480" TEXT="020-GROUP-ORGANIZATION.test">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1239202257303" FOLDED="true" ID="Freemind_Link_409246384" MODIFIED="1239204260420" TEXT="orggroupbrowser(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239202262888" ID="Freemind_Link_140842720" MODIFIED="1239204260419" TEXT="Display demeanor">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239201776089" FOLDED="true" ID="Freemind_Link_862374364" MODIFIED="1239209077632" TEXT="nbgroup(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201784441" FOLDED="true" ID="Freemind_Link_777577273" MODIFIED="1239206994140" TEXT="Add population to orders">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201789097" ID="Freemind_Link_1878401214" MODIFIED="1239207200021" TEXT="GROUP:NBHOOD:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201798265" ID="Freemind_Link_1770738085" MODIFIED="1239207200020" TEXT="GROUP:NBHOOD:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201802521" ID="Freemind_Link_220348278" MODIFIED="1239207200019" TEXT="GROUP:NBHOOD:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239201907640" FOLDED="true" ID="Freemind_Link_1523740663" MODIFIED="1239209077633" TEXT="Update tests">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201910632" ID="Freemind_Link_391272266" MODIFIED="1239209077633" TEXT="010-nbgroup.test">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201919720" ID="Freemind_Link_1248205781" MODIFIED="1239209077634" TEXT="020-GROUP-NBHOOD.test">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1239202268087" FOLDED="true" ID="Freemind_Link_314841661" MODIFIED="1239204260419" TEXT="nbgroupbrowser(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239202271863" ID="Freemind_Link_630310815" MODIFIED="1239204260418" TEXT="Display population">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239201933369" FOLDED="true" ID="Freemind_Link_1672220262" MODIFIED="1239209872758" TEXT="orders(sim) manpage">
<icon BUILTIN="button_ok"/>
<node CREATED="1239201724857" ID="Freemind_Link_1770089602" MODIFIED="1239209872760" TEXT="GROUP:FORCE:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201730217" ID="Freemind_Link_1852745667" MODIFIED="1239209872763" TEXT="GROUP:FORCE:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201735945" ID="Freemind_Link_394288563" MODIFIED="1239209872763" TEXT="GROUP:FORCE:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201757992" ID="Freemind_Link_685393812" MODIFIED="1239209872762" TEXT="GROUP:ORGANIZATION:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201763688" ID="Freemind_Link_1491972669" MODIFIED="1239209872762" TEXT="GROUP:ORGANIZATION:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201768937" ID="Freemind_Link_884592812" MODIFIED="1239209872761" TEXT="GROUP:ORGANIZATION:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201789097" ID="Freemind_Link_1495342173" MODIFIED="1239209872761" TEXT="GROUP:NBHOOD:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201798265" ID="Freemind_Link_1332510055" MODIFIED="1239209872760" TEXT="GROUP:NBHOOD:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239201802521" ID="Freemind_Link_1191930025" MODIFIED="1239209872760" TEXT="GROUP:NBHOOD:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
<node CREATED="1240003892077" FOLDED="true" ID="Freemind_Link_1611440031" MODIFIED="1240003909637" TEXT="Bug 2040">
<icon BUILTIN="button_ok"/>
<node CREATED="1239032463568" FOLDED="true" ID="Freemind_Link_1095706563" MODIFIED="1240003909635" TEXT="Neighborhood Statistics">
<icon BUILTIN="button_ok"/>
<node CREATED="1239983997783" FOLDED="true" ID="Freemind_Link_657907875" MODIFIED="1239984029429" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1239984000759" ID="Freemind_Link_256236922" MODIFIED="1239984013121" TEXT="Compute nbstat more or less as in JNEM"/>
</node>
<node CREATED="1239984039175" FOLDED="true" ID="Freemind_Link_1928359253" MODIFIED="1240000058540" TEXT="nbstat(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984044791" FOLDED="true" ID="Freemind_Link_935940158" MODIFIED="1239985843033" TEXT="security(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238449563668" ID="Freemind_Link_201754109" MODIFIED="1239985836617" TEXT="Force and Security Analysis">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1239724089348" ID="Freemind_Link_708708761" MODIFIED="1239985836618" TEXT="As in JNEM">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1239724093236" ID="Freemind_Link_1634748245" MODIFIED="1239985843034" TEXT="Volatility gain should be stored in nbhoods table">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239724114949" ID="Freemind_Link_766185434" MODIFIED="1239985843035" TEXT="Don&apos;t look for civilian units, as there aren&apos;t any">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239984074647" ID="Freemind_Link_1358195959" MODIFIED="1239985843035" TEXT="force.* parmdb parameters">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239984123255" FOLDED="true" ID="Freemind_Link_403401646" MODIFIED="1240000058542" TEXT="activity(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984126646" ID="Freemind_Link_1510542232" MODIFIED="1239984419148" TEXT="Activity coverage">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1239984135111" ID="Freemind_Link_8434766" MODIFIED="1239984419149" TEXT="More or less as in JNEM">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1239724193845" FOLDED="true" ID="Freemind_Link_281782117" MODIFIED="1239902281796" TEXT="Remove activities">
<icon BUILTIN="button_ok"/>
<node CREATED="1239724219684" FOLDED="true" ID="Freemind_Link_1622626700" MODIFIED="1239724238670" TEXT="CORDON_AND_SEARCH">
<node CREATED="1239724300724" ID="Freemind_Link_1537193155" MODIFIED="1239724302557" TEXT="Short-term"/>
</node>
<node CREATED="1239724239139" FOLDED="true" ID="Freemind_Link_748110521" MODIFIED="1239724243278" TEXT="INTERVIEW_SCREEN">
<node CREATED="1239724303780" ID="Freemind_Link_439138834" MODIFIED="1239724307389" TEXT="Short-term"/>
</node>
<node CREATED="1239724290531" FOLDED="true" ID="Freemind_Link_1343824265" MODIFIED="1239724294206" TEXT="MILITARY_TRAINING">
<node CREATED="1239724294516" ID="Freemind_Link_772257623" MODIFIED="1239724298974" TEXT="Requires parameterization"/>
</node>
</node>
<node CREATED="1239984178822" FOLDED="true" ID="Freemind_Link_595159173" MODIFIED="1239984409324" TEXT="Personnel">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984181878" FOLDED="true" ID="Freemind_Link_1383519266" MODIFIED="1239984409327" TEXT="Nominal">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984184710" ID="Freemind_Link_533681109" MODIFIED="1239984189568" TEXT="Assigned to do the activity"/>
</node>
<node CREATED="1239984191958" FOLDED="true" ID="Freemind_Link_1370938436" MODIFIED="1239984409326" TEXT="Active">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984200454" FOLDED="true" ID="Freemind_Link_663845661" MODIFIED="1239984232581" TEXT="Given implicit schedule, not all assigned &#xa;troops can be active at the same time.">
<node CREATED="1239984233958" ID="Freemind_Link_1388449787" MODIFIED="1239984243552" TEXT="24x7 schedule requires shifts"/>
</node>
<node CREATED="1239724454307" FOLDED="true" ID="Freemind_Link_107706676" MODIFIED="1239724462206" TEXT="Assigned-to-Active Ratio">
<node CREATED="1239724462755" ID="Freemind_Link_1680915963" MODIFIED="1239724467837" TEXT="New parmdb(5) parm"/>
<node CREATED="1239724468371" ID="Freemind_Link_1801332434" MODIFIED="1239724496189" TEXT="Number of assigned troops to get 1 active troop"/>
<node CREATED="1239724496579" ID="Freemind_Link_660890548" MODIFIED="1239724504141" TEXT="Presumes implicit schedule"/>
</node>
</node>
<node CREATED="1239984264182" FOLDED="true" ID="Freemind_Link_462638593" MODIFIED="1239984409326" TEXT="Effective">
<icon BUILTIN="button_ok"/>
<node CREATED="1239724338148" FOLDED="true" ID="Freemind_Link_292730787" MODIFIED="1239902263684" TEXT="Security">
<icon BUILTIN="button_ok"/>
<node CREATED="1239724341587" ID="Freemind_Link_305980584" MODIFIED="1239724343277" TEXT="As in JNEM"/>
</node>
<node CREATED="1239724344324" FOLDED="true" ID="Freemind_Link_987767269" MODIFIED="1239902270259" TEXT="Unit movement">
<icon BUILTIN="button_cancel"/>
<node CREATED="1239724348452" ID="Freemind_Link_1905383465" MODIFIED="1239724354125" TEXT="Delete; no such thing in Athena"/>
</node>
<node CREATED="1239724355188" FOLDED="true" ID="Freemind_Link_421106640" MODIFIED="1239902270260" TEXT="Unit combat">
<icon BUILTIN="button_cancel"/>
<node CREATED="1239724358932" ID="Freemind_Link_1823823267" MODIFIED="1239724365565" TEXT="Delete; entirely different in Athena"/>
</node>
<node CREATED="1239984295303" FOLDED="true" ID="Freemind_Link_1189123671" MODIFIED="1239984309300" TEXT="ORG group status">
<icon BUILTIN="button_cancel"/>
<node CREATED="1239984311846" FOLDED="true" ID="Freemind_Link_1099402984" MODIFIED="1239984321809" TEXT="Defer">
<node CREATED="1239984322118" ID="Freemind_Link_59105714" MODIFIED="1239984333696" TEXT="ORG casualties are strictly magic in spiral 1"/>
<node CREATED="1239984334614" ID="Freemind_Link_1935664113" MODIFIED="1239984359152" TEXT="Analyst can remove orgs from neighborhood if they should be inactive"/>
</node>
</node>
</node>
</node>
<node CREATED="1239724331380" FOLDED="true" ID="Freemind_Link_359864329" MODIFIED="1239984409325" TEXT="Activity queries">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984379702" ID="Freemind_Link_944450711" MODIFIED="1239984398982" TEXT="Validate assignable FRC activities"/>
<node CREATED="1239984388086" ID="Freemind_Link_652060454" MODIFIED="1239984394288" TEXT="Validate assignable ORG activities"/>
</node>
</node>
<node CREATED="1239984493750" FOLDED="true" ID="Freemind_Link_1417600440" MODIFIED="1240000058541" TEXT="nbstat analyze">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984538198" ID="Freemind_Link_1243802053" MODIFIED="1239984557020" TEXT="Analyzes security and coverage">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1239984509269" ID="Freemind_Link_791749449" MODIFIED="1239984534924" TEXT="On leaving PREP state">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239984523831" ID="Freemind_Link_1023822123" MODIFIED="1239985769993" TEXT="On each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1239984477126" FOLDED="true" ID="Freemind_Link_666536858" MODIFIED="1240000051380" TEXT="nbhoodbrowser(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984575333" FOLDED="true" ID="Freemind_Link_796486726" MODIFIED="1240000051381" TEXT="Display">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984580117" ID="Freemind_Link_1443440863" MODIFIED="1239984586399" TEXT="Nbhood volatility"/>
<node CREATED="1239984586742" ID="Freemind_Link_1199198250" MODIFIED="1239984599071" TEXT="Total population"/>
</node>
<node CREATED="1239984621334" ID="Freemind_Link_450790543" MODIFIED="1240000051381" TEXT="If possible make Nbhood column into row headers">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239984646565" FOLDED="true" ID="Freemind_Link_148454984" MODIFIED="1240003849051" TEXT="securitybrowser(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984664037" ID="Freemind_Link_439965783" MODIFIED="1239984669567" TEXT="Display force_ng data"/>
</node>
<node CREATED="1239984671414" FOLDED="true" ID="Freemind_Link_1672238956" MODIFIED="1240003849053" TEXT="activitybrowser(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984678597" ID="Freemind_Link_1272972284" MODIFIED="1239984686335" TEXT="Display activity_nga data"/>
</node>
<node CREATED="1239984687734" FOLDED="true" ID="Freemind_Link_458872846" MODIFIED="1240003849052" TEXT="unitbrowser(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1239984692341" ID="Freemind_Link_503655393" MODIFIED="1240003849053" TEXT="Display a_effective flag">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239032541930" FOLDED="true" ID="Freemind_Link_252805844" MODIFIED="1240003849052" TEXT="Prerequisites">
<icon BUILTIN="button_ok"/>
<node CREATED="1239032575097" ID="Freemind_Link_1666380791" MODIFIED="1239209959550" TEXT="Force group demeanor">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239032580810" ID="Freemind_Link_908362995" MODIFIED="1239209959551" TEXT="ORG group demeanor">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239209948441" ID="Freemind_Link_105574179" MODIFIED="1239209959551" TEXT="Nbgroup population">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239723838740" ID="Freemind_Link_1271840031" MODIFIED="1239723843914" TEXT="Nbhood vtygain">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1239032601002" ID="Freemind_Link_1476936963" MODIFIED="1239723780867" TEXT="parmdb(5) parameters">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1239032627610" FOLDED="true" ID="Freemind_Link_1414363915" MODIFIED="1239032636659" TEXT="Athena Analyst&apos;s Guide">
<node CREATED="1239033028345" ID="Freemind_Link_146620445" MODIFIED="1239984460448" TEXT="nbstat(sim) and submodules"/>
</node>
</node>
</node>
<node CREATED="1240249491850" FOLDED="true" ID="Freemind_Link_1703074791" MODIFIED="1240249527167" TEXT="Bug 2055">
<icon BUILTIN="button_ok"/>
<node CREATED="1240239479170" FOLDED="true" ID="Freemind_Link_626826622" MODIFIED="1240249527169" TEXT="appwin(sim) Hierarchical Tabs">
<icon BUILTIN="button_ok"/>
<node CREATED="1240244645218" FOLDED="true" ID="Freemind_Link_1123845153" MODIFIED="1240244755720" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1240244661826" ID="Freemind_Link_905576433" MODIFIED="1240244675916" TEXT="At present there is a flat list of tabs across the main window"/>
<node CREATED="1240244676835" ID="Freemind_Link_1503911354" MODIFIED="1240244689036" TEXT="There will soon be too many to fit."/>
<node CREATED="1240244689586" ID="Freemind_Link_1130152071" MODIFIED="1240244699212" TEXT="It&apos;s already hard to find the tab you want"/>
<node CREATED="1240244649971" ID="Freemind_Link_1263527046" MODIFIED="1240244728748" TEXT="Arrange tabs in a logical hierarchy"/>
<node CREATED="1240244731954" ID="Freemind_Link_975002893" MODIFIED="1240244751036" TEXT="Provide a View menu as an alternate way to find what you want"/>
</node>
<node CREATED="1240242634231" FOLDED="true" ID="Freemind_Link_1917785579" MODIFIED="1240244642448" TEXT="Tab Layout">
<icon BUILTIN="button_ok"/>
<node CREATED="1239983529160" ID="Freemind_Link_1005825195" MODIFIED="1239983531842" TEXT="Map"/>
<node CREATED="1239983532504" FOLDED="true" ID="Freemind_Link_964872758" MODIFIED="1240240445182" TEXT="Nbhoods">
<node CREATED="1239983541992" ID="Freemind_Link_1583630347" MODIFIED="1239983580081" TEXT="nbhoods"/>
<node CREATED="1239983545352" ID="Freemind_Link_1280665169" MODIFIED="1239983573377" TEXT="nbrel"/>
<node CREATED="1239983657352" ID="Freemind_Link_177494477" MODIFIED="1239983666625" TEXT="force_ng (Security)"/>
<node CREATED="1239983667272" ID="Freemind_Link_546369489" MODIFIED="1239983687041" TEXT="activity_nga (Activity)"/>
</node>
<node CREATED="1239983582136" FOLDED="true" ID="Freemind_Link_1311278363" MODIFIED="1239983583873" TEXT="Groups">
<node CREATED="1239983584664" ID="Freemind_Link_1576741303" MODIFIED="1239983593233" TEXT="civgroups"/>
<node CREATED="1239983593511" ID="Freemind_Link_529391531" MODIFIED="1239983596913" TEXT="nbgroups"/>
<node CREATED="1239983597400" ID="Freemind_Link_1530427310" MODIFIED="1239983600977" TEXT="frcgroups"/>
<node CREATED="1239983601447" ID="Freemind_Link_1779438032" MODIFIED="1239983603169" TEXT="orggroups"/>
<node CREATED="1239983604504" ID="Freemind_Link_174026712" MODIFIED="1239983607473" TEXT="rel_nfg"/>
</node>
<node CREATED="1239983609784" FOLDED="true" ID="Freemind_Link_930474552" MODIFIED="1239983612514" TEXT="GRAM">
<node CREATED="1239983613048" ID="Freemind_Link_432031382" MODIFIED="1239983619681" TEXT="sat_ngc"/>
<node CREATED="1239983620104" ID="Freemind_Link_1360163717" MODIFIED="1239983621873" TEXT="coop_nfg"/>
<node CREATED="1239983624984" ID="Freemind_Link_165213820" MODIFIED="1239983629329" TEXT="TBD"/>
</node>
<node CREATED="1239983643463" ID="Freemind_Link_1273053175" MODIFIED="1239983649279" TEXT="Log"/>
</node>
<node CREATED="1240242661783" FOLDED="true" ID="Freemind_Link_1413603382" MODIFIED="1240242793669" TEXT="appwin(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1240242666950" ID="Freemind_Link_1231307529" MODIFIED="1240242793668" TEXT="Add declarative tab spec">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240244618884" ID="Freemind_Link_944820080" MODIFIED="1240244634953" TEXT="Create tabs using tab spec">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240244624450" ID="Freemind_Link_422598191" MODIFIED="1240244634952" TEXT="Create View menu using tab spec">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240244607762" FOLDED="true" ID="Freemind_Link_749789152" MODIFIED="1240244610252" TEXT="Methods">
<node CREATED="1240242675159" FOLDED="true" ID="Freemind_Link_1031467140" MODIFIED="1240244970362" TEXT="$win tab win">
<icon BUILTIN="button_ok"/>
<node CREATED="1240242689671" ID="Freemind_Link_407274928" MODIFIED="1240242694128" TEXT="Returns window given tab ID"/>
</node>
<node CREATED="1240242696102" FOLDED="true" ID="Freemind_Link_347759871" MODIFIED="1240244978188" TEXT="$win tab view">
<icon BUILTIN="button_ok"/>
<node CREATED="1240242701942" ID="Freemind_Link_343555036" MODIFIED="1240242711808" TEXT="Makes tab visible"/>
</node>
</node>
</node>
<node CREATED="1240242773254" FOLDED="true" ID="Freemind_Link_379827677" MODIFIED="1240242777425" TEXT="Docs">
<node CREATED="1240242777814" FOLDED="true" ID="Freemind_Link_1113599253" MODIFIED="1240242780497" TEXT="appwin(sim)">
<node CREATED="1240242780807" ID="Freemind_Link_1796997038" MODIFIED="1240242784720" TEXT="Add new methods"/>
</node>
</node>
</node>
</node>
<node CREATED="1240439364925" FOLDED="true" ID="Freemind_Link_1187282465" MODIFIED="1240439380610" TEXT="Bug 2062">
<icon BUILTIN="button_ok"/>
<node CREATED="1240253506816" FOLDED="true" ID="Freemind_Link_253544217" MODIFIED="1240439380612" TEXT="Activity Situations">
<icon BUILTIN="button_ok"/>
<node CREATED="1240253516481" FOLDED="true" ID="Freemind_Link_277045850" MODIFIED="1240253518764" TEXT="Attributes">
<node CREATED="1240253519121" FOLDED="true" ID="Freemind_Link_1660146183" MODIFIED="1240432326649" TEXT="Common">
<icon BUILTIN="button_ok"/>
<node CREATED="1240253690993" FOLDED="true" ID="Freemind_Link_852087663" MODIFIED="1240432324056" TEXT="id">
<icon BUILTIN="button_ok"/>
<node CREATED="1240254374704" ID="Freemind_Link_412715314" MODIFIED="1240254545034" TEXT="JNEM: FED_ID, actsit_id"/>
</node>
<node CREATED="1240253694577" ID="Freemind_Link_602142308" MODIFIED="1240432324055" TEXT="driver">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240253697905" FOLDED="true" ID="Freemind_Link_1724366999" MODIFIED="1240432324055" TEXT="stype">
<icon BUILTIN="button_ok"/>
<node CREATED="1240254381744" ID="Freemind_Link_584541510" MODIFIED="1240254397594" TEXT="JNEM: TYPE"/>
</node>
<node CREATED="1240253713761" FOLDED="true" ID="Freemind_Link_1333968615" MODIFIED="1240432324054" TEXT="n">
<icon BUILTIN="button_ok"/>
<node CREATED="1240254386208" ID="Freemind_Link_449499700" MODIFIED="1240254571993" TEXT="JNEM: NEIGHBORHOOD, nbhood"/>
</node>
<node CREATED="1240254599760" ID="Freemind_Link_87207584" MODIFIED="1240432324054" TEXT="coverage">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240253753665" FOLDED="true" ID="Freemind_Link_714108658" MODIFIED="1240432324053" TEXT="g">
<icon BUILTIN="button_ok"/>
<node CREATED="1240253755473" ID="Freemind_Link_217817824" MODIFIED="1240254585401" TEXT="JNEM: CAUSED_BY, actor"/>
</node>
<node CREATED="1240253789553" FOLDED="true" ID="Freemind_Link_1708169057" MODIFIED="1240432324053" TEXT="flist">
<icon BUILTIN="button_ok"/>
<node CREATED="1240253807313" ID="Freemind_Link_1113773800" MODIFIED="1240254419642" TEXT="JNEM: GROUPS"/>
</node>
<node CREATED="1240253815953" FOLDED="true" ID="Freemind_Link_138566497" MODIFIED="1240432324052" TEXT="ts">
<icon BUILTIN="button_ok"/>
<node CREATED="1240253819665" ID="Freemind_Link_1758987120" MODIFIED="1240254426250" TEXT="JNEM: start_time"/>
</node>
<node CREATED="1240432264698" FOLDED="true" ID="Freemind_Link_888822915" MODIFIED="1240432324052" TEXT="tc">
<icon BUILTIN="button_ok"/>
<node CREATED="1240432266875" ID="Freemind_Link_207158940" MODIFIED="1240432270085" TEXT="JNEM: update_time"/>
</node>
<node CREATED="1240253849074" ID="Freemind_Link_346124288" MODIFIED="1240432324051" TEXT="state">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240254321999" ID="Freemind_Link_794172040" MODIFIED="1240432324051" TEXT="change">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1240253525137" FOLDED="true" ID="Freemind_Link_972839382" MODIFIED="1240432324049" TEXT="actsit only">
<icon BUILTIN="button_ok"/>
<node CREATED="1240254593024" ID="Freemind_Link_1532105100" MODIFIED="1240432324050" TEXT="activity">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1240253536065" FOLDED="true" ID="Freemind_Link_800956664" MODIFIED="1240432324050" TEXT="envsit only">
<icon BUILTIN="button_ok"/>
<node CREATED="1240432289819" ID="Freemind_Link_1398184727" MODIFIED="1240432292475" TEXT="None"/>
</node>
</node>
<node CREATED="1240253539986" FOLDED="true" ID="Freemind_Link_750590555" MODIFIED="1240432332753" TEXT="States">
<icon BUILTIN="button_ok"/>
<node CREATED="1240254253713" ID="Freemind_Link_1658145022" MODIFIED="1240432332754" TEXT="Active">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240337655735" ID="Freemind_Link_1841332862" MODIFIED="1240432332755" TEXT="Inactive">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240254266288" ID="Freemind_Link_473717656" MODIFIED="1240432332755" TEXT="Ended">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1240253599378" FOLDED="true" ID="Freemind_Link_1566533109" MODIFIED="1240253601069" TEXT="Events">
<node CREATED="1240253567554" FOLDED="true" ID="Freemind_Link_89799231" MODIFIED="1240432340105" TEXT="actsit only">
<icon BUILTIN="button_ok"/>
<node CREATED="1240255374190" FOLDED="true" ID="Freemind_Link_828322556" MODIFIED="1240432340106" TEXT="Inception">
<icon BUILTIN="button_ok"/>
<node CREATED="1240255378622" ID="Freemind_Link_964413056" MODIFIED="1240255384712" TEXT="Coverage &gt; 0 for the first time"/>
</node>
<node CREATED="1240255346286" FOLDED="true" ID="Freemind_Link_624917494" MODIFIED="1240432340107" TEXT="Coverage change">
<icon BUILTIN="button_ok"/>
<node CREATED="1240329971044" ID="Freemind_Link_1528263513" MODIFIED="1240329989342" TEXT="Not actually an event; we leave it up to the rules to detect this."/>
</node>
<node CREATED="1240255385966" FOLDED="true" ID="Freemind_Link_825786795" MODIFIED="1240432340107" TEXT="Termination">
<icon BUILTIN="button_ok"/>
<node CREATED="1240255398622" ID="Freemind_Link_1927919297" MODIFIED="1240261067086" TEXT="Nominal Personnel = 0"/>
</node>
</node>
<node CREATED="1240253572706" FOLDED="true" ID="Freemind_Link_1239554300" MODIFIED="1240432358385" TEXT="envsit only">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1240255077903" FOLDED="true" ID="Freemind_Link_48391042" MODIFIED="1240255433816" TEXT="Creation">
<node CREATED="1240255133375" ID="Freemind_Link_350256331" MODIFIED="1240255138936" TEXT="With inception effects or not"/>
</node>
<node CREATED="1240255108944" ID="Freemind_Link_1455846644" MODIFIED="1240261041482" TEXT="Coverage change">
<icon BUILTIN="ksmiletris"/>
</node>
<node CREATED="1240255083375" FOLDED="true" ID="Freemind_Link_1981673349" MODIFIED="1240255085593" TEXT="Resolution">
<node CREATED="1240255143791" ID="Freemind_Link_119585927" MODIFIED="1240255154536" TEXT="With resolution effects or not"/>
<node CREATED="1240255222222" ID="Freemind_Link_1624047388" MODIFIED="1240255294216" TEXT="Resolution effects need a separate driver."/>
</node>
</node>
</node>
<node CREATED="1240261506547" FOLDED="true" ID="Freemind_Link_572038604" MODIFIED="1240432366089" TEXT="Changes from JNEM">
<icon BUILTIN="button_ok"/>
<node CREATED="1240261548611" FOLDED="true" ID="Freemind_Link_250509076" MODIFIED="1240432346849" TEXT="General">
<icon BUILTIN="button_ok"/>
<node CREATED="1240261510179" ID="Freemind_Link_1278843052" MODIFIED="1240261532557" TEXT="Situations cannot be disabled/enabled."/>
<node CREATED="1240261533347" ID="Freemind_Link_232034225" MODIFIED="1240261539341" TEXT="Situations cannot be cancelled."/>
</node>
<node CREATED="1240261579235" FOLDED="true" ID="Freemind_Link_1166147514" MODIFIED="1240432355713" TEXT="envsits">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1240261586195" FOLDED="true" ID="Freemind_Link_149752904" MODIFIED="1240261619933" TEXT="No partial resolution">
<node CREATED="1240261634835" ID="Freemind_Link_1891248963" MODIFIED="1240261638477" TEXT="We never used it."/>
<node CREATED="1240261620434" ID="Freemind_Link_1123966193" MODIFIED="1240261648797" TEXT="fraction_resolved goes away."/>
</node>
<node CREATED="1240261605523" FOLDED="true" ID="Freemind_Link_1064765968" MODIFIED="1240261661293" TEXT="Can create without inception effects">
<node CREATED="1240261662291" ID="Freemind_Link_665581464" MODIFIED="1240261704026" TEXT="Makes explicit the current behavior on &#xa;initial_fraction_resolved &gt; 0."/>
</node>
<node CREATED="1240261716691" FOLDED="true" ID="Freemind_Link_345176798" MODIFIED="1240261722511" TEXT="No severity">
<node CREATED="1240261722947" ID="Freemind_Link_30062335" MODIFIED="1240261725965" TEXT="We never used it."/>
</node>
<node CREATED="1240261727139" FOLDED="true" ID="Freemind_Link_591865642" MODIFIED="1240261731215" TEXT="Add coverage">
<node CREATED="1240261731619" ID="Freemind_Link_1966258314" MODIFIED="1240261736477" TEXT="Nominal coverage is 1.0"/>
<node CREATED="1240261736947" ID="Freemind_Link_887448255" MODIFIED="1240261742477" TEXT="Analyst can scale down effects"/>
<node CREATED="1240261742835" ID="Freemind_Link_1885432721" MODIFIED="1240261762781" TEXT="Ultimately, can allow multiple envsits in one neighborhood"/>
</node>
</node>
<node CREATED="1240261844355" FOLDED="true" ID="Freemind_Link_1271979944" MODIFIED="1240432363377" TEXT="actsits">
<icon BUILTIN="button_ok"/>
<node CREATED="1240261848323" ID="Freemind_Link_1495302529" MODIFIED="1240261867723" TEXT="Are terminated as in JNEM, when nominal&#xa;personnel is reduced to 0."/>
</node>
</node>
<node CREATED="1240432372747" ID="Freemind_Link_663983740" MODIFIED="1240432385297" TEXT="Add ActSits browser to Neighborhood tab">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240432391467" ID="Freemind_Link_1459156349" MODIFIED="1240432401841" TEXT="Update test suite">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240432413306" ID="Freemind_Link_484406497" MODIFIED="1240439281859" TEXT="situation(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1240432417674" ID="Freemind_Link_260354501" MODIFIED="1240439281860" TEXT="actsit(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1242242378523" FOLDED="true" ID="Freemind_Link_844324300" MODIFIED="1242242394337" TEXT="Bug 2073">
<icon BUILTIN="button_ok"/>
<node CREATED="1241213122622" FOLDED="true" ID="Freemind_Link_1686775927" MODIFIED="1241213157958" TEXT="&lt;html&gt;&lt;center&gt;Environmental&lt;br&gt;&#xa;Situations&lt;/center&gt;">
<node CREATED="1241214858627" ID="Freemind_Link_1749967338" MODIFIED="1241805984321" TEXT="&quot;pending&quot; envsits">
<icon BUILTIN="button_ok"/>
<node CREATED="1241214867699" ID="Freemind_Link_1112186275" MODIFIED="1241214875628" TEXT="Should &quot;pending&quot; be a situation state?">
<node CREATED="1241797822719" ID="Freemind_Link_1582444302" MODIFIED="1241797828264" TEXT="Yes, but what to call it?"/>
<node CREATED="1241798545242" ID="Freemind_Link_1624504815" MODIFIED="1241798628146" TEXT="INITIAL"/>
</node>
<node CREATED="1241214877059" ID="Freemind_Link_1043798464" MODIFIED="1242239320597" TEXT="General infrastructure for entities are editable or &#xa;not based on their own state rather than the sim state">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1241806376128" ID="Freemind_Link_1791139188" MODIFIED="1242056393702" TEXT="GUI">
<node CREATED="1241806380560" ID="Freemind_Link_641049560" MODIFIED="1241806858902" TEXT="Interactions">
<icon BUILTIN="button_ok"/>
<node CREATED="1241213233752" ID="Freemind_Link_1295280977" MODIFIED="1241214333338" TEXT="Allow editing a situation by right-clicking on it.">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213247847" ID="Freemind_Link_51362897" MODIFIED="1241214327803" TEXT="Allow creating a situation by right-clicking on neighborhood">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213261687" ID="Freemind_Link_288381587" MODIFIED="1241214327802" TEXT="Allow creating a unit by right-clicking on neighborhood">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241806398655" ID="Freemind_Link_1552550497" MODIFIED="1241806858901" TEXT="Envsit Browser">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806403487" ID="Freemind_Link_103837556" MODIFIED="1241806771645" TEXT="Allow display of All, Live, or Ended envsits">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056427383" ID="Freemind_Link_22891150" MODIFIED="1242056459572" TEXT="Create button">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056435094" ID="Freemind_Link_1712944561" MODIFIED="1242056459573" TEXT="Edit button">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056438822" ID="Freemind_Link_220278718" MODIFIED="1242059151377" TEXT="Resolve button">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056443926" ID="Freemind_Link_1802858313" MODIFIED="1242056459574" TEXT="Delete button">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241213617573" ID="Freemind_Link_1476486652" MODIFIED="1241806764149" TEXT="Mapviewer should display live envsits only.">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806719729" ID="Freemind_Link_1947838192" MODIFIED="1241806764150" TEXT="Colors">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806442111" ID="Freemind_Link_29521002" MODIFIED="1241806473063" TEXT="INITIAL state: red on white"/>
<node CREATED="1242237172626" ID="Freemind_Link_753359251" MODIFIED="1242237182130" TEXT="ENDED state: green on white"/>
<node CREATED="1241806454784" ID="Freemind_Link_357525230" MODIFIED="1241806465383" TEXT="Others: red on yellow"/>
</node>
</node>
</node>
<node CREATED="1241806800271" ID="Freemind_Link_1087315745" MODIFIED="1242163479816" TEXT="Orders">
<icon BUILTIN="button_ok"/>
<node CREATED="1241213192663" ID="Freemind_Link_339564971" MODIFIED="1241816376760" TEXT="Fix S:E:UPDATE dialog constraints">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213169736" ID="Freemind_Link_89786008" MODIFIED="1241816376760" TEXT="Fix g data entry in all orders, dialogs">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213225078" ID="Freemind_Link_289214706" MODIFIED="1242057678171" TEXT="Add S:E:RESOLVE order">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241806779215" ID="Freemind_Link_1026149228" MODIFIED="1242163479817" TEXT="scenario">
<icon BUILTIN="button_ok"/>
<node CREATED="1241214763395" ID="Freemind_Link_139901386" MODIFIED="1242163472384" TEXT="mutate reconcile">
<icon BUILTIN="button_ok"/>
<node CREATED="1241214703075" ID="Freemind_Link_1632242702" MODIFIED="1242163439452" TEXT="Creating or modifying a neighborhood must fix up envsit &quot;n&quot; field"/>
<node CREATED="1241214746547" ID="Freemind_Link_1655030319" MODIFIED="1242057701214" TEXT="Deleting a group must fix up envsit g and resolver fields"/>
</node>
<node CREATED="1242163442722" ID="Freemind_Link_872768653" MODIFIED="1242163472385" TEXT="Sanity Check">
<icon BUILTIN="button_ok"/>
<node CREATED="1242163447586" ID="Freemind_Link_534316694" MODIFIED="1242163459308" TEXT="Every envsit must be in a neighborhood"/>
<node CREATED="1242163459682" ID="Freemind_Link_609590258" MODIFIED="1242163468348" TEXT="No more than one envsit of a type in a neighborhood"/>
</node>
</node>
<node CREATED="1241214774083" ID="Freemind_Link_664817675" MODIFIED="1242237203184" TEXT="Test suite">
<icon BUILTIN="button_ok"/>
<node CREATED="1241798163883" ID="Freemind_Link_200208835" MODIFIED="1242163495402" TEXT="Write 010-envsit.test">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242163506979" ID="Freemind_Link_1748453134" MODIFIED="1242164766509" TEXT="Update 010-sim.test (sanity check)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241798174027" ID="Freemind_Link_1793404936" MODIFIED="1242237200136" TEXT="Write 020-SITUATION-ENVIRONMENTAL.test">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241214801330" ID="Freemind_Link_1737846328" MODIFIED="1242238225550" TEXT="Update orders(sim) man page">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806832142" ID="Freemind_Link_303434512" MODIFIED="1242238225552" TEXT="S:E:* orders">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241806819695" ID="Freemind_Link_1120882551" MODIFIED="1242238225551" TEXT="Update order(sim) man page">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806826000" ID="Freemind_Link_1470105764" MODIFIED="1242238225552" TEXT="prepare -oldnum">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241214808690" ID="Freemind_Link_1271819979" MODIFIED="1242239295629" TEXT="Write envsit(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1243459108889" FOLDED="true" ID="Freemind_Link_106518662" MODIFIED="1243459130566" TEXT="Bug 2128">
<icon BUILTIN="button_ok"/>
<node CREATED="1237479995726" ID="Freemind_Link_1174080421" MODIFIED="1243459087607" TEXT="Data-driven nbhood fill colors">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
</map>
