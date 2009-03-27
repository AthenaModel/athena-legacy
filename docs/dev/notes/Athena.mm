<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237475113960" ID="Freemind_Link_868839690" MODIFIED="1237475134049" TEXT="Athena">
<node CREATED="1237477449934" ID="Freemind_Link_919437009" MODIFIED="1237477452594" POSITION="right" TEXT="Simulation">
<node CREATED="1237478987023" FOLDED="true" ID="Freemind_Link_324117817" MODIFIED="1238170518037" TEXT="Integrate gram(n)">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1238170451558" ID="Freemind_Link_1373349157" MODIFIED="1238170461615" TEXT="sim(sim) Changes">
<node CREATED="1237842153584" ID="Freemind_Link_340570150" MODIFIED="1238170440973" TEXT="Initialize GRAM on PREP to RUNNING"/>
<node CREATED="1238170474294" ID="Freemind_Link_271034006" MODIFIED="1238170493983" TEXT="Sync GRAM when loading PAUSED scenario"/>
<node CREATED="1237822576953" ID="Freemind_Link_1552650374" MODIFIED="1237822586866" TEXT="Advance GRAM during each tick"/>
</node>
<node CREATED="1238170378694" ID="Freemind_Link_1318678904" MODIFIED="1238170382224" TEXT="gram(n) Changes">
<node CREATED="1237820225709" ID="Freemind_Link_209344982" MODIFIED="1237822673138" TEXT="On Open of scenario with t &gt; 0, must be able to sync with loaded gram_* data"/>
<node CREATED="1237820290381" ID="Freemind_Link_1416194108" MODIFIED="1237820313047" TEXT="For simplicity, should not be a saveable--should save all scalars in RDB"/>
</node>
</node>
<node CREATED="1237480898155" FOLDED="true" ID="Freemind_Link_919848605" MODIFIED="1237480916486" TEXT="GRAM slope limits based on duration">
<node CREATED="1237480917418" ID="Freemind_Link_701469202" MODIFIED="1237480958721" TEXT="Limits based on total nominal change&#xa;don&apos;t really make sense."/>
</node>
<node CREATED="1238015584936" FOLDED="true" ID="Freemind_Link_1054409835" MODIFIED="1238168626771" TEXT="WAYBACK state">
<node CREATED="1238015589208" ID="Freemind_Link_1081765451" MODIFIED="1238015601106" TEXT="Enter WAYBACK state when loading prior snapshot"/>
<node CREATED="1238015602360" ID="Freemind_Link_1868904837" MODIFIED="1238015609218" TEXT="In WAYBACK, most orders are disabled"/>
<node CREATED="1238015621352" ID="Freemind_Link_1434476628" MODIFIED="1238015631410" TEXT="Leave WAYBACK automatically on return to final snapshot"/>
<node CREATED="1238015609784" ID="Freemind_Link_1583241154" MODIFIED="1238015619602" TEXT="Must leave WAYBACK explicitly to change things"/>
<node CREATED="1238015639048" ID="Freemind_Link_1905612992" MODIFIED="1238015653522" TEXT="On leaving WAYBACK explicitly, future snapshots are purged">
<node CREATED="1238015654120" ID="Freemind_Link_779539554" MODIFIED="1238015661314" TEXT="Rather than on SIM:RUN."/>
<node CREATED="1238015661865" ID="Freemind_Link_1702214277" MODIFIED="1238015667250" TEXT="Can&apos;t SIM:RUN while in WAYBACK"/>
</node>
<node CREATED="1238015681529" ID="Freemind_Link_1703074413" MODIFIED="1238015700325" TEXT="Need special handling for GUI interactions">
<node CREATED="1238015700680" ID="Freemind_Link_1732762311" MODIFIED="1238015705266" TEXT="E.g., dragging units"/>
</node>
<node CREATED="1238015717159" ID="Freemind_Link_1853367133" MODIFIED="1238015722825" TEXT="Possible icon: "/>
</node>
<node CREATED="1237822733720" FOLDED="true" ID="Freemind_Link_1356652575" MODIFIED="1237822740277" TEXT="Reactive Decision Conditions">
<node CREATED="1237822742521" ID="Freemind_Link_656806568" MODIFIED="1237822753602" TEXT="Check RDCs at end of each tick"/>
<node CREATED="1237822754248" ID="Freemind_Link_1244752831" MODIFIED="1237822768786" TEXT="Simplest: pause simulation if RDC is met"/>
</node>
<node CREATED="1237568034086" FOLDED="true" ID="Freemind_Link_1406761834" MODIFIED="1237568069787" TEXT="Game truth variables">
<icon BUILTIN="help"/>
<node CREATED="1237568050726" ID="Freemind_Link_454367740" MODIFIED="1237568062559" TEXT="Like gtclient/gtserver, but within one app"/>
</node>
</node>
<node CREATED="1237475139158" ID="_" MODIFIED="1237477117490" POSITION="right" TEXT="Order">
<node CREATED="1237480217386" ID="Freemind_Link_96571795" MODIFIED="1238170655243" TEXT="Dump order history as script">
<arrowlink DESTINATION="Freemind_Link_860046120" ENDARROW="Default" ENDINCLINATION="75;0;" ID="Freemind_Arrow_Link_966523914" STARTARROW="None" STARTINCLINATION="75;0;"/>
<icon BUILTIN="messagebox_warning"/>
</node>
<node CREATED="1237480209602" ID="Freemind_Link_860046120" MODIFIED="1238170658003" TEXT="Order scripting">
<icon BUILTIN="messagebox_warning"/>
</node>
<node CREATED="1237480052010" ID="Freemind_Link_1129765376" MODIFIED="1237480125936" TEXT="Ability to validate orders without executing them"/>
<node CREATED="1237480092962" FOLDED="true" ID="Freemind_Link_1722894145" MODIFIED="1237480125937" TEXT="Schedule orders ahead of time">
<arrowlink DESTINATION="Freemind_Link_1129765376" ENDARROW="Default" ENDINCLINATION="93;0;" ID="Freemind_Arrow_Link_906925163" STARTARROW="None" STARTINCLINATION="93;0;"/>
<node CREATED="1237571826655" ID="Freemind_Link_358553126" MODIFIED="1237994632175" TEXT="&quot;order schedule&quot; command">
<node CREATED="1237571831262" ID="Freemind_Link_691473547" MODIFIED="1237571836200" TEXT="Schedules another order"/>
<node CREATED="1237994657557" ID="Freemind_Link_1225659272" MODIFIED="1237994673855" TEXT="CIF&apos;d as ORDER:SCHEDULE pseudo-order">
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
<node CREATED="1237571660719" ID="Freemind_Link_1311718344" MODIFIED="1237571813596" TEXT="Orders run by scheduled events" VSHIFT="-6">
<node CREATED="1237571721677" ID="Freemind_Link_402714946" MODIFIED="1237571728024" TEXT="Run by &quot;sim&quot;, not &quot;gui&quot;"/>
<node CREATED="1237571728750" ID="Freemind_Link_203596528" MODIFIED="1237571732296" TEXT="Not put in CIF"/>
<node CREATED="1237571732717" ID="Freemind_Link_739438388" MODIFIED="1237571735784" TEXT="Not undoable"/>
</node>
<node CREATED="1237994749045" ID="Freemind_Link_137028882" MODIFIED="1237994796554" TEXT="No SIM:SCHEDULE order">
<icon BUILTIN="flag"/>
<node CREATED="1237994759220" ID="Freemind_Link_884689448" MODIFIED="1237994787918" TEXT="&quot;order schedule&quot; must validate order states"/>
<node CREATED="1237994788501" ID="Freemind_Link_481627364" MODIFIED="1237994793104" TEXT="That&apos;s a framework issue."/>
</node>
</node>
<node CREATED="1237477120338" ID="Freemind_Link_191938982" MODIFIED="1237477220978" TEXT="Merge cif(sim) into order(sim) as &quot;order history&quot;"/>
<node CREATED="1237480262914" FOLDED="true" ID="Freemind_Link_325462962" MODIFIED="1237480278885" TEXT="Add *:MULTI orders as appropriate">
<node CREATED="1237480280162" ID="Freemind_Link_526459050" MODIFIED="1237480285749" TEXT="E.g., *:DELETE:MULTI"/>
</node>
<node CREATED="1237481133242" ID="Freemind_Link_1851551577" MODIFIED="1237481149014" TEXT="Abstract order(sim) into order(n)"/>
<node CREATED="1237481099914" ID="Freemind_Link_1283162022" MODIFIED="1237481131391" TEXT="Abstract prepare/reject/returnOnError model for use in other code">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237477511538" ID="Freemind_Link_894463638" MODIFIED="1237477524514" POSITION="right" TEXT="Scenario">
<node CREATED="1237477586106" FOLDED="true" ID="Freemind_Link_516563511" MODIFIED="1237477603190" TEXT="Must rel=1.0 when f=g">
<icon BUILTIN="help"/>
<node CREATED="1237477606906" ID="Freemind_Link_1462718131" MODIFIED="1237477628037" TEXT="If so, I need to update the RELATIONSHIP:* orders"/>
</node>
<node CREATED="1237480308963" FOLDED="true" ID="Freemind_Link_1212698036" MODIFIED="1237480331061" TEXT="Reciprocal flag in *:UPDATE">
<node CREATED="1237480368626" ID="Freemind_Link_285045741" MODIFIED="1237480382381" TEXT="Sets same value for mn and nm, nfg and ngf"/>
<node CREATED="1237480331738" ID="Freemind_Link_1725501118" MODIFIED="1237480344757" TEXT="NBHOOD:RELATIONSHIP:UPDATE"/>
<node CREATED="1237480346154" ID="Freemind_Link_377220162" MODIFIED="1237480349469" TEXT="RELATIONSHIP:UPDATE"/>
</node>
<node CREATED="1237480977571" FOLDED="true" ID="Freemind_Link_590980119" MODIFIED="1237480983314" TEXT="MAP:EXPORT">
<node CREATED="1237480984002" ID="Freemind_Link_151089338" MODIFIED="1237480998630" TEXT="Exports the current map background as an image file"/>
</node>
<node CREATED="1237477546722" ID="Freemind_Link_815759729" MODIFIED="1237477568182" TEXT="CIV group units">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237482120338" FOLDED="true" ID="Freemind_Link_1183885189" MODIFIED="1238104926493" TEXT="Orders to rename entities">
<icon BUILTIN="help"/>
<node CREATED="1237482138802" ID="Freemind_Link_1495570394" MODIFIED="1237482143838" TEXT="Useful; can of worms."/>
</node>
</node>
<node CREATED="1237479428630" ID="Freemind_Link_1070564721" MODIFIED="1237479469634" POSITION="right" TEXT="GUI">
<node CREATED="1237935555280" FOLDED="true" ID="Freemind_Link_695028490" MODIFIED="1238106346211" TEXT="Snapshot browser/loader">
<arrowlink DESTINATION="Freemind_Link_1054409835" ENDARROW="Default" ENDINCLINATION="215;0;" ID="Freemind_Arrow_Link_254679226" STARTARROW="None" STARTINCLINATION="529;0;"/>
<node CREATED="1237994176614" ID="Freemind_Link_343371493" MODIFIED="1237994196064" TEXT="Controls: first, previous, next, last"/>
<node CREATED="1237994196662" ID="Freemind_Link_122266377" MODIFIED="1237994205824" TEXT="&quot;First&quot; control replaces &quot;restart&quot;"/>
<node CREATED="1237994206534" ID="Freemind_Link_1540265172" MODIFIED="1237994232880" TEXT="Use iPod icons: double triangles, with a vertical line for first and last"/>
<node CREATED="1237994233798" ID="Freemind_Link_1620821104" MODIFIED="1237994261888" TEXT="Tool tip should indicate the sim time of the checkpoint to load"/>
<node CREATED="1237994262438" ID="Freemind_Link_1024035268" MODIFIED="1237994283776" TEXT="Moving backwards should save a checkpoint if there isn&apos;t one."/>
<node CREATED="1237994284725" ID="Freemind_Link_128499237" MODIFIED="1237994321663" TEXT="Pressing run should be confirmed if future checkpoints would be purged."/>
</node>
<node CREATED="1237488295816" FOLDED="true" ID="Freemind_Link_1208739900" MODIFIED="1237495169282" TEXT="zulufield(n) widget">
<node CREATED="1237560838308" ID="Freemind_Link_7202440" MODIFIED="1237560850862" TEXT="-increment set by simclock&apos;s tick size"/>
<node CREATED="1237918381064" ID="Freemind_Link_274696888" MODIFIED="1237918408034" TEXT="Make -changecmd work properly"/>
</node>
<node CREATED="1237479490254" ID="Freemind_Link_1164487778" MODIFIED="1237479498698" TEXT="Order History Browser"/>
<node CREATED="1237479513679" ID="Freemind_Link_123674584" MODIFIED="1237479523691" TEXT="appwin(sim): Windows Menu"/>
<node CREATED="1237479525078" FOLDED="true" ID="Freemind_Link_122163295" MODIFIED="1237479534962" TEXT="appwin(sim): Optional Tabs">
<node CREATED="1237479542494" ID="Freemind_Link_1417851375" MODIFIED="1237479555026" TEXT="Most/all tabs should be optional."/>
<node CREATED="1237479555774" ID="Freemind_Link_1026314275" MODIFIED="1237479568490" TEXT="Each tab has a checkbox on View menu"/>
<node CREATED="1237479569238" ID="Freemind_Link_1577478674" MODIFIED="1237479591914" TEXT="Disabled tabs don&apos;t exist, no CPU used"/>
</node>
<node CREATED="1237481210122" FOLDED="true" ID="Freemind_Link_1615196501" MODIFIED="1237481223466" TEXT="appwin(sim): Hierarchical tabs">
<node CREATED="1237481224027" ID="Freemind_Link_1716821238" MODIFIED="1237481233326" TEXT="We need a better way to present the info."/>
<node CREATED="1237481238530" FOLDED="true" ID="Freemind_Link_1492297848" MODIFIED="1237481243686" TEXT="Some data might be on multiple tabs">
<node CREATED="1237481244362" ID="Freemind_Link_1880842776" MODIFIED="1237481256094" TEXT="Units vs. Frc Units"/>
</node>
</node>
<node CREATED="1237479823575" FOLDED="true" ID="Freemind_Link_1856908617" MODIFIED="1237479838611" TEXT="Preserve GUI layout">
<node CREATED="1237479839174" ID="Freemind_Link_254956277" MODIFIED="1237479844658" TEXT="Save on shutdown or request"/>
<node CREATED="1237479845294" ID="Freemind_Link_1346360849" MODIFIED="1237479851922" TEXT="Restore at startup"/>
</node>
<node CREATED="1237479433118" FOLDED="true" ID="Freemind_Link_491578520" MODIFIED="1237479488218" TEXT="Cell-based editing in browsers">
<node CREATED="1237479441630" ID="Freemind_Link_1508483203" MODIFIED="1237479447402" TEXT="Interaction Logic"/>
<node CREATED="1237479448534" ID="Freemind_Link_1379686715" MODIFIED="1237479457434" TEXT="How to use custom editors in Tablelist"/>
</node>
<node CREATED="1237480548048" FOLDED="true" ID="Freemind_Link_1752009235" MODIFIED="1237480701864" TEXT="Help Browser">
<node CREATED="1237480554706" ID="Freemind_Link_418716993" MODIFIED="1237480564829" TEXT="Firefox, Tkhtml2, or Text"/>
<node CREATED="1237480565722" ID="Freemind_Link_452312016" MODIFIED="1237480582229" TEXT="If Firefox, prefs setting for location"/>
</node>
<node CREATED="1237481279626" FOLDED="true" ID="Freemind_Link_19715277" MODIFIED="1237481292487" TEXT="Browsers: -view option">
<node CREATED="1237481293089" ID="Freemind_Link_348314360" MODIFIED="1237481307013" TEXT="One browser could browse several subsets, given different views"/>
<node CREATED="1237481308697" ID="Freemind_Link_38947399" MODIFIED="1237481318813" TEXT="Perhaps, browser gets list of views"/>
<node CREATED="1237481319513" ID="Freemind_Link_1805553183" MODIFIED="1237481325621" TEXT="User can switch between views"/>
</node>
<node CREATED="1237935592833" FOLDED="true" ID="Freemind_Link_115718094" MODIFIED="1237935621398" TEXT="Order/ability to save explicit checkpoint">
<icon BUILTIN="help"/>
<node CREATED="1237935623632" ID="Freemind_Link_1015974023" MODIFIED="1237935628332" TEXT="Why would this be useful?"/>
<node CREATED="1237935632528" ID="Freemind_Link_1714148047" MODIFIED="1237935637098" TEXT="Possibly as a scheduled order."/>
</node>
<node CREATED="1237481060666" ID="Freemind_Link_236045392" MODIFIED="1237481071958" TEXT="Wizard infrastructure">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237479990726" ID="Freemind_Link_1486904062" MODIFIED="1237479995186" POSITION="right" TEXT="Map GUI">
<node CREATED="1237481843234" FOLDED="true" ID="Freemind_Link_1306844691" MODIFIED="1237481853838" TEXT="Set unit shapes based on relationships">
<node CREATED="1237481854578" ID="Freemind_Link_720065925" MODIFIED="1237481862230" TEXT="WRT user-selected group"/>
<node CREATED="1237481862754" ID="Freemind_Link_1299949235" MODIFIED="1237481887774" TEXT="qgrouprel defines FRIEND, NEUTRAL, ENEMY"/>
</node>
<node CREATED="1237479995726" ID="Freemind_Link_1174080421" MODIFIED="1237480014930" TEXT="Data-driven nbhood fill colors"/>
<node CREATED="1237482154410" ID="Freemind_Link_1362932509" MODIFIED="1237482165447" TEXT="Enable/disable map background"/>
<node CREATED="1237482166114" ID="Freemind_Link_639175641" MODIFIED="1237482173382" TEXT="Enable/disable nbhood display"/>
<node CREATED="1237482173858" FOLDED="true" ID="Freemind_Link_270558674" MODIFIED="1237482179936" TEXT="Enable/disable icons">
<node CREATED="1237482180474" ID="Freemind_Link_1659229339" MODIFIED="1237482185838" TEXT="By icon type"/>
</node>
<node CREATED="1237482195459" ID="Freemind_Link_1291634544" MODIFIED="1237482204646" TEXT="Display nbhood names by refpoint"/>
<node CREATED="1237480762290" ID="Freemind_Link_1647420652" MODIFIED="1237480770710" TEXT="Ability to drag reference points interactively"/>
<node CREATED="1237481081578" ID="Freemind_Link_1201367450" MODIFIED="1237481091054" TEXT="Ability to edit nbhood boundary points interactively"/>
</node>
<node CREATED="1237480148482" ID="Freemind_Link_1288481032" MODIFIED="1237480151141" POSITION="right" TEXT="Order GUI">
<node CREATED="1237480151546" ID="Freemind_Link_1910353174" MODIFIED="1237480162312" TEXT="Validate order on parameter entry change"/>
<node CREATED="1237480163506" FOLDED="true" ID="Freemind_Link_1602203708" MODIFIED="1237480178654" TEXT="User selects order execution time">
<node CREATED="1237480179450" ID="Freemind_Link_1441599316" MODIFIED="1237480186965" TEXT="Invalid orders can be scheduled"/>
</node>
<node CREATED="1237480419203" FOLDED="true" ID="Freemind_Link_1658294835" MODIFIED="1237480439055" TEXT="Z-Curve editor/order field">
<node CREATED="1237480439570" ID="Freemind_Link_1579708717" MODIFIED="1237480447765" TEXT="Mostly complete"/>
<node CREATED="1237480448378" ID="Freemind_Link_1976364131" MODIFIED="1237480454069" TEXT="Use -type, bounds, for layout"/>
<node CREATED="1237480455082" ID="Freemind_Link_1029610545" MODIFIED="1237480463597" TEXT="Add &quot;Clear&quot; button to clear fields to match curve"/>
<node CREATED="1237480464266" ID="Freemind_Link_1002868925" MODIFIED="1237480490037" TEXT="Buttons active only when unsaved data"/>
<node CREATED="1237480480554" ID="Freemind_Link_208340476" MODIFIED="1237480498638" TEXT="Buttons use tinyfont"/>
</node>
<node CREATED="1237482036218" FOLDED="true" ID="Freemind_Link_594210180" MODIFIED="1237482044439" TEXT="textfield(n) allows -autocmd">
<node CREATED="1237482048762" ID="Freemind_Link_1233297342" MODIFIED="1237482067198" TEXT="If present, field has &quot;Auto&quot; button"/>
<node CREATED="1237482068018" ID="Freemind_Link_1873031307" MODIFIED="1237482082038" TEXT="Pressing Auto fills in field automatically"/>
</node>
<node CREATED="1237482088442" ID="Freemind_Link_1487556535" MODIFIED="1237482098407" TEXT="colorfield(n) should allow editing"/>
<node CREATED="1237480589114" ID="Freemind_Link_1560701323" MODIFIED="1237480832899" TEXT="Implement order dialog&apos;s Help button">
<arrowlink DESTINATION="Freemind_Link_1752009235" ENDARROW="Default" ENDINCLINATION="187;0;" ID="Freemind_Arrow_Link_1754252667" STARTARROW="None" STARTINCLINATION="187;0;"/>
</node>
<node CREATED="1237480808675" ID="Freemind_Link_490467788" MODIFIED="1237480882437" TEXT="Scrolling order tree, in dialog or palette">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237481160994" ID="Freemind_Link_1793874343" MODIFIED="1237481180162" TEXT="Parameter help strings">
<node CREATED="1237481181034" ID="Freemind_Link_382977978" MODIFIED="1237481200616" TEXT="Display in order dialog&apos;s message area"/>
<node CREATED="1238170607413" ID="Freemind_Link_1227050066" MODIFIED="1238170619791" TEXT="Build order docs at build time?"/>
</node>
<node CREATED="1237481709395" FOLDED="true" ID="Freemind_Link_242433049" MODIFIED="1237481719533" TEXT="Enumfield should display short and long name">
<node CREATED="1237481720578" ID="Freemind_Link_568955124" MODIFIED="1237481725070" TEXT="For enum(n)"/>
<node CREATED="1237481731218" ID="Freemind_Link_288295662" MODIFIED="1237481735974" TEXT="For entities with long names"/>
<node CREATED="1237481736658" ID="Freemind_Link_1062430820" MODIFIED="1237481739782" TEXT="For quality(n)"/>
<node CREATED="1237481740282" ID="Freemind_Link_1648375048" MODIFIED="1237481749862" TEXT="Send short name to order(sim)"/>
</node>
</node>
<node CREATED="1237479872766" ID="Freemind_Link_307055918" MODIFIED="1237479878826" POSITION="right" TEXT="Infrastructure">
<node CREATED="1237479880174" FOLDED="true" ID="Freemind_Link_640139219" MODIFIED="1237479885643" TEXT="notifier(n) introspection">
<node CREATED="1237479886358" ID="Freemind_Link_1497195308" MODIFIED="1237479891074" TEXT="Dump subscription info"/>
<node CREATED="1237479891694" ID="Freemind_Link_67855834" MODIFIED="1237479901642" TEXT="Predict effect of sending an event"/>
</node>
<node CREATED="1237479930358" ID="Freemind_Link_1301494248" MODIFIED="1237479939826" TEXT="range(n) should emulate snit::double&apos;s error messages"/>
<node CREATED="1237479941254" ID="Freemind_Link_285676340" MODIFIED="1237479950842" TEXT="enum(n) should emulate snit::enum&apos;s error messages"/>
<node CREATED="1237479952062" ID="Freemind_Link_1986519778" MODIFIED="1237479968762" TEXT="quality(n) should emulate snit::double and snit::enum&apos;s error messages"/>
<node CREATED="1237480727986" FOLDED="true" ID="Freemind_Link_1856628726" MODIFIED="1237480741999" TEXT="filter(n): -filterset option">
<node CREATED="1237480742858" ID="Freemind_Link_1542097651" MODIFIED="1237480750709" TEXT="Allows multiple filters to show same filter string"/>
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
<node CREATED="1237479138614" ID="Freemind_Link_1692010973" MODIFIED="1237479140586" POSITION="right" TEXT="App">
<node CREATED="1237479141070" FOLDED="true" ID="Freemind_Link_1157275495" MODIFIED="1238170644307" TEXT="Purging old sessions">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1237479159342" ID="Freemind_Link_978533443" MODIFIED="1237479167154" TEXT="At present, session data is deleted on exit"/>
<node CREATED="1237479168366" ID="Freemind_Link_28557513" MODIFIED="1237479175178" TEXT="Should retain multiple sessions"/>
<node CREATED="1237479186254" FOLDED="true" ID="Freemind_Link_1095851202" MODIFIED="1237479202138" TEXT="Should purge older sessions">
<node CREATED="1237479203454" ID="Freemind_Link_369530055" MODIFIED="1237479217394" TEXT="Athena writes a timestamp file periodically"/>
<node CREATED="1237479354070" ID="Freemind_Link_901309961" MODIFIED="1237479361778" TEXT="Deletes timestamp file on exit"/>
<node CREATED="1237479218718" ID="Freemind_Link_65984085" MODIFIED="1237479240154" TEXT="At startup, Athena checks files, deletes old sessions"/>
<node CREATED="1237589140509" ID="Freemind_Link_1794162858" MODIFIED="1237589150806" TEXT="All of this can be done by the workdir(n) module"/>
</node>
</node>
<node CREATED="1237479175966" FOLDED="true" ID="Freemind_Link_1542399623" MODIFIED="1237479252978" TEXT="Session Operations">
<node CREATED="1237479256574" ID="Freemind_Link_703383499" MODIFIED="1237479264754" TEXT="Re-enter, given PID"/>
<node CREATED="1237479265638" ID="Freemind_Link_657545711" MODIFIED="1237479311398" TEXT="Package session as zipfile"/>
<node CREATED="1237479285670" ID="Freemind_Link_209800069" MODIFIED="1237479295186" TEXT="Unpack zipped session"/>
<node CREATED="1237479312598" FOLDED="true" ID="Freemind_Link_1937283519" MODIFIED="1237479326154" TEXT="List existing sessions">
<node CREATED="1237479326670" ID="Freemind_Link_57127863" MODIFIED="1237479341778" TEXT="Include whether active or not."/>
</node>
</node>
<node CREATED="1237482232117" ID="Freemind_Link_686336989" MODIFIED="1237482248329" TEXT="parmdb mechanism + orders"/>
</node>
<node CREATED="1237481029826" ID="Freemind_Link_660348068" MODIFIED="1237481031278" POSITION="right" TEXT="CM">
<node CREATED="1237481032018" ID="Freemind_Link_920792744" MODIFIED="1237481052413" TEXT="make clean: clean up auto-generated GIFs in man* directories"/>
</node>
<node CREATED="1237477422983" ID="Freemind_Link_1059023875" MODIFIED="1237477425010" POSITION="right" TEXT="Docs">
<node CREATED="1237477426471" ID="Freemind_Link_887072406" MODIFIED="1237477434298" TEXT="Athena Analyst&apos;s Guide"/>
<node CREATED="1237477435158" ID="Freemind_Link_144909588" MODIFIED="1237477440938" TEXT="Athena Architecture Document"/>
<node CREATED="1237480507154" FOLDED="true" ID="Freemind_Link_1237244067" MODIFIED="1237480511727" TEXT="Tcl/Tk Coding Standard">
<node CREATED="1237480512322" ID="Freemind_Link_1356756808" MODIFIED="1237480517069" TEXT="Move from JNEM to Mars."/>
<node CREATED="1237480517906" ID="Freemind_Link_1655161326" MODIFIED="1237480519237" TEXT="Update"/>
<node CREATED="1237480520129" ID="Freemind_Link_656371050" MODIFIED="1237480523168" TEXT="Reference in Athena"/>
</node>
</node>
<node CREATED="1237934628643" FOLDED="true" ID="Freemind_Link_276542603" MODIFIED="1237934645816" POSITION="left" TEXT="Done">
<icon BUILTIN="button_ok"/>
<node CREATED="1238105059255" ID="Freemind_Link_1270491565" MODIFIED="1238105072101" TEXT="Bug 1958">
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
<node CREATED="1238105040439" ID="Freemind_Link_397054523" MODIFIED="1238105050189" TEXT="Bug 1961">
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
<node CREATED="1238105021367" ID="Freemind_Link_135593121" MODIFIED="1238105031997" TEXT="Bug 1962">
<icon BUILTIN="button_ok"/>
<node CREATED="1237477378229" ID="Freemind_Link_527719459" MODIFIED="1238003858401" TEXT="Enable/disable orders based on simulation state">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1237479698478" ID="Freemind_Link_1365670694" MODIFIED="1238104974257" TEXT="Bug 1963">
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
<node CREATED="1238170053719" ID="Freemind_Link_953600025" MODIFIED="1238170094533" TEXT="Bug 1966">
<icon BUILTIN="button_ok"/>
<node CREATED="1238107725235" FOLDED="true" ID="Freemind_Link_260363276" MODIFIED="1238170094532" TEXT="Replace ::sim &lt;Status&gt;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238107798339" ID="Freemind_Link_1365021836" MODIFIED="1238107800300" TEXT="New Events">
<node CREATED="1238107739698" ID="Freemind_Link_437840786" MODIFIED="1238107745596" TEXT="&lt;Tick&gt;"/>
<node CREATED="1238168630505" ID="Freemind_Link_539391698" MODIFIED="1238168634836" TEXT="&lt;Time&gt;"/>
<node CREATED="1238107746179" ID="Freemind_Link_1624909068" MODIFIED="1238168640723" TEXT="&lt;State&gt;"/>
<node CREATED="1238107788002" ID="Freemind_Link_409425418" MODIFIED="1238107790380" TEXT="&lt;Speed&gt;"/>
</node>
<node CREATED="1238107804754" ID="Freemind_Link_1786540087" MODIFIED="1238107814748" TEXT="appwin can subscribe one handler to all three"/>
</node>
</node>
<node CREATED="1238170234726" ID="Freemind_Link_329451020" MODIFIED="1238170252020" TEXT="Bug 1965">
<icon BUILTIN="button_ok"/>
<node CREATED="1237571987086" ID="Freemind_Link_33041850" MODIFIED="1238170252021" TEXT="Undo info should be cleared at each tick.">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238174760622" ID="Freemind_Link_1452183384" MODIFIED="1238174774524" TEXT="Bug 1967">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171285579" FOLDED="true" ID="Freemind_Link_164640460" MODIFIED="1238174774526" TEXT="Scenario Sanity Check">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171311427" ID="Freemind_Link_1401500484" MODIFIED="1238171324314" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1237479063275" ID="Freemind_Link_1056971138" MODIFIED="1238174587800" TEXT="The scenario must be sane before time can advance."/>
<node CREATED="1238171344773" ID="Freemind_Link_426910570" MODIFIED="1238171427950" TEXT="Do a sanity check on SIM:RUN">
<node CREATED="1238171428405" ID="Freemind_Link_759586256" MODIFIED="1238171433550" TEXT="Order is rejected."/>
<node CREATED="1238171434340" ID="Freemind_Link_875208047" MODIFIED="1238171449006" TEXT="Present warnings to user"/>
</node>
<node CREATED="1238170280470" ID="Freemind_Link_922997392" MODIFIED="1238173690494" TEXT="Conditions">
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
<node CREATED="1237478995798" ID="Freemind_Link_1302227452" MODIFIED="1238174388141" TEXT="sim(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171490835" ID="Freemind_Link_752525374" MODIFIED="1238174386229" TEXT="sim check ?-log?">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171508052" ID="Freemind_Link_1274803095" MODIFIED="1238171514157" TEXT="Performs sanity check"/>
<node CREATED="1238171514692" ID="Freemind_Link_1441734208" MODIFIED="1238171523054" TEXT="Logs results to debugging log"/>
<node CREATED="1238171524308" ID="Freemind_Link_1253796134" MODIFIED="1238171536364" TEXT="Returns a boolean flag."/>
</node>
<node CREATED="1238171567604" ID="Freemind_Link_43310679" MODIFIED="1238174386229" TEXT="SIM:RUN">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171571172" ID="Freemind_Link_1028498519" MODIFIED="1238171579101" TEXT="Calls &quot;sim check -log&quot;"/>
<node CREATED="1238171579732" ID="Freemind_Link_460230865" MODIFIED="1238171599661" TEXT="On failure, rejects order with explanatory message"/>
</node>
</node>
<node CREATED="1238171602644" ID="Freemind_Link_1245358500" MODIFIED="1238174395357" TEXT="appwin(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171612611" ID="Freemind_Link_556644434" MODIFIED="1238171635705" TEXT="Sends SIM:RUN when play button is pressed">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238171887427" ID="Freemind_Link_1319861674" MODIFIED="1238174395357" TEXT="Displays rejections to user">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238171939475" ID="Freemind_Link_1489528397" MODIFIED="1238174395358" TEXT="Catches errors">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171945810" ID="Freemind_Link_156063273" MODIFIED="1238171972962" TEXT="Should be only rejections; other errors &#xa;are handled by order(sim)"/>
</node>
</node>
</node>
</node>
</node>
</node>
</map>
