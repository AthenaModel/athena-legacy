<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237475113960" ID="Freemind_Link_868839690" MODIFIED="1237475134049" TEXT="Athena">
<node CREATED="1237477449934" ID="Freemind_Link_919437009" MODIFIED="1237477452594" POSITION="right" TEXT="Simulation">
<node CREATED="1237480898155" FOLDED="true" ID="Freemind_Link_919848605" MODIFIED="1237480916486" TEXT="GRAM slope limits based on duration">
<node CREATED="1237480917418" ID="Freemind_Link_701469202" MODIFIED="1237480958721" TEXT="Limits based on total nominal change&#xa;don&apos;t really make sense."/>
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
<node CREATED="1237480217386" ID="Freemind_Link_96571795" MODIFIED="1238433033389" TEXT="Dump order history as script">
<arrowlink DESTINATION="Freemind_Link_860046120" ENDARROW="Default" ENDINCLINATION="75;0;" ID="Freemind_Arrow_Link_966523914" STARTARROW="None" STARTINCLINATION="75;0;"/>
<node CREATED="1238185877929" ID="Freemind_Link_1596050694" MODIFIED="1238185885379" TEXT="Need to know scripting format first"/>
</node>
<node CREATED="1237480209602" FOLDED="true" ID="Freemind_Link_860046120" MODIFIED="1238433033390" TEXT="Order scripting">
<node CREATED="1238185910426" ID="Freemind_Link_1940884826" MODIFIED="1238185912932" TEXT="Uses">
<node CREATED="1238185655578" ID="Freemind_Link_136202823" MODIFIED="1238185664708" TEXT="Run script within existing scenario">
<node CREATED="1238185776810" ID="Freemind_Link_1966079268" MODIFIED="1238185799476" TEXT="Not intended to recreate previous run"/>
<node CREATED="1238185668699" ID="Freemind_Link_549143569" MODIFIED="1238185675908" TEXT="Ignore timestamps">
<node CREATED="1238185219419" ID="Freemind_Link_558616974" MODIFIED="1238185240359" TEXT="Run all orders now">
<node CREATED="1238185241979" ID="Freemind_Link_640319681" MODIFIED="1238185244309" TEXT="Log Failures"/>
<node CREATED="1238185244699" ID="Freemind_Link_118761070" MODIFIED="1238185248085" TEXT="Stop after first failure"/>
</node>
</node>
<node CREATED="1238185676299" ID="Freemind_Link_134673193" MODIFIED="1238185679892" TEXT="Honor timestamps">
<node CREATED="1238185710346" ID="Freemind_Link_1027973767" MODIFIED="1238185722580" TEXT="Options">
<node CREATED="1238185680442" ID="Freemind_Link_788668770" MODIFIED="1238185684564" TEXT="Without offset"/>
<node CREATED="1238185684922" ID="Freemind_Link_87005297" MODIFIED="1238185687028" TEXT="With offset"/>
</node>
<node CREATED="1238185730010" ID="Freemind_Link_984278862" MODIFIED="1238185747732" TEXT="Run orders timestamped now, now"/>
<node CREATED="1238185748137" ID="Freemind_Link_1818266246" MODIFIED="1238185755284" TEXT="Schedule other orders in eventq"/>
</node>
</node>
<node CREATED="1238185298203" ID="Freemind_Link_1182934650" MODIFIED="1238185380791" TEXT="Run up a CIF">
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
<node CREATED="1237935555280" FOLDED="true" ID="Freemind_Link_695028490" MODIFIED="1238185997091" TEXT="Snapshot Navigation">
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
<node CREATED="1238431453361" ID="Freemind_Link_595977621" MODIFIED="1238445457383" TEXT="Bug 1969">
<icon BUILTIN="button_ok"/>
<node CREATED="1238185942456" FOLDED="true" ID="Freemind_Link_405704848" MODIFIED="1238431480265" TEXT="Snapshot Navigation and the SNAPSHOT State">
<icon BUILTIN="button_ok"/>
<node CREATED="1238190921792" ID="Freemind_Link_1311836518" MODIFIED="1238190995647" TEXT="The &quot;latest time&quot; is the latest sim time &#xa;achieved for this scenario.  There might or might&#xa;not be a snapshot at the latest time.">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238190851871" ID="Freemind_Link_746914711" MODIFIED="1238431338513" TEXT="Navigation">
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
<node CREATED="1238191030192" ID="Freemind_Link_322032318" MODIFIED="1238431348609" TEXT="SNAPSHOT State">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191408045" ID="Freemind_Link_1598909806" MODIFIED="1238431334330" TEXT="Enter the SNAPSHOT state:">
<icon BUILTIN="button_ok"/>
<node CREATED="1237994284725" ID="Freemind_Link_1731247325" MODIFIED="1238194043206" TEXT="On loading a snapshot prior to the &quot;latest time&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238191433694" ID="Freemind_Link_930869996" MODIFIED="1238194369869" TEXT="On loading a scenario that was saved in the SNAPSHOT state">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238015602360" ID="Freemind_Link_541498746" MODIFIED="1238431334329" TEXT="In SNAPSHOT, most orders are disabled">
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
<node CREATED="1238191530429" ID="Freemind_Link_1217471197" MODIFIED="1238194088230" TEXT="Leave the SNAPSHOT state:">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191067727" ID="Freemind_Link_1871259741" MODIFIED="1238194064630" TEXT="Implicitly, by returning to the snapshot for the &quot;latest time&quot;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191719725" ID="Freemind_Link_1721476881" MODIFIED="1238191722487" TEXT="Enter PAUSED."/>
</node>
<node CREATED="1238191576830" ID="Freemind_Link_1270538436" MODIFIED="1238194084525" TEXT="Explicitly, by pressing Run/Pause button">
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
<node CREATED="1238015681529" ID="Freemind_Link_1517558552" MODIFIED="1238428648951" TEXT="Need special handling for GUI interactions">
<icon BUILTIN="button_ok"/>
<node CREATED="1238015700680" ID="Freemind_Link_1107307253" MODIFIED="1238015705266" TEXT="E.g., dragging units"/>
</node>
</node>
<node CREATED="1238425808630" ID="Freemind_Link_1294854083" MODIFIED="1238427813545" TEXT="Reflections over the weekend">
<icon BUILTIN="button_ok"/>
<node CREATED="1238425817574" ID="Freemind_Link_1746054516" MODIFIED="1238427813545" TEXT="Change WAYBACK to SNAPSHOT">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238425826309" ID="Freemind_Link_1869494239" MODIFIED="1238427813547" TEXT="Add &quot;scenario snapshot latest&quot;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238425850886" ID="Freemind_Link_1304559035" MODIFIED="1238425855888" TEXT="Returns tick of last snapshot"/>
</node>
<node CREATED="1238425857494" ID="Freemind_Link_902008359" MODIFIED="1238427813547" TEXT="Add &quot;scenario snapshot current&quot;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238425865095" ID="Freemind_Link_951007981" MODIFIED="1238425984039" TEXT="Returns index of current snapshot"/>
<node CREATED="1238425903286" ID="Freemind_Link_1552120527" MODIFIED="1238425996496" TEXT="Time 0 snapshot is snapshot 0"/>
</node>
<node CREATED="1238425917221" ID="Freemind_Link_462603546" MODIFIED="1238427813546" TEXT="In appwin, for state: &quot;Snapshot 2&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238426025702" ID="Freemind_Link_274922866" MODIFIED="1238427813546" TEXT="In Mr. Peabody&apos;s message: ">
<icon BUILTIN="button_ok"/>
<node CREATED="1238426042773" ID="Freemind_Link_958522936" MODIFIED="1238426053728" TEXT="You can use wayback machine to re-enter timestream here in snapshot 2"/>
<node CREATED="1238426054437" ID="Freemind_Link_836263563" MODIFIED="1238426070224" TEXT="However, snapshots 3 through 7 will be erased."/>
</node>
</node>
<node CREATED="1238426269478" ID="Freemind_Link_674135358" MODIFIED="1238431325025" TEXT="Before we&apos;re done:">
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
<node CREATED="1238445403725" ID="Freemind_Link_1772844702" MODIFIED="1238445426051" TEXT="Bug 1972">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436555694" FOLDED="true" ID="Freemind_Link_342947994" MODIFIED="1238445426053" TEXT="Integrate gram(n)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436679903" ID="Freemind_Link_135625100" MODIFIED="1238445298523" TEXT="General Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436683200" ID="Freemind_Link_569591853" MODIFIED="1238436903958" TEXT="Require simlib(n) from Mars">
<icon BUILTIN="button_ok"/>
<node CREATED="1238436878576" ID="Freemind_Link_369762958" MODIFIED="1238436903957" TEXT="Remove duplicate types from projectlib(n)">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1238170378694" ID="Freemind_Link_177076752" MODIFIED="1238445298524" TEXT="gram(n) Changes">
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
<node CREATED="1238170451558" ID="Freemind_Link_1408336574" MODIFIED="1238441470260" TEXT="sim(sim) Changes">
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
</node>
</node>
</map>
