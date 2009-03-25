<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237580820610" ID="Freemind_Link_571023392" MODIFIED="1237996616792" TEXT="Non-GUI effects of simulation&#xa;state on order handling">
<node CREATED="1237581050220" ID="Freemind_Link_1947927414" MODIFIED="1237994515555" POSITION="right" TEXT="Simulation states">
<icon BUILTIN="flag"/>
<node CREATED="1237581057020" ID="Freemind_Link_1522096514" MODIFIED="1237581058725" TEXT="PREP"/>
<node CREATED="1237581059516" ID="Freemind_Link_409826464" MODIFIED="1237581061989" TEXT="RUNNING"/>
<node CREATED="1237581062588" ID="Freemind_Link_759050256" MODIFIED="1237581064069" TEXT="PAUSED"/>
</node>
<node CREATED="1237995725828" ID="Freemind_Link_269184654" MODIFIED="1237996796183" POSITION="right" TEXT="Should order states match simulation states?&#xa;Important distinction is &quot;Prep&quot; vs. &quot;Non-Prep&quot;,&#xa;or &quot;Scenario&quot; vs. &quot;Simulation&quot;.">
<icon BUILTIN="flag"/>
<node CREATED="1237995795779" ID="Freemind_Link_1366655686" MODIFIED="1237995804572" TEXT="App could translated from sim state to order state"/>
<node CREATED="1237995847795" ID="Freemind_Link_774669824" MODIFIED="1237995909164" TEXT="In JNEM, when saving/restoring/etc., could have &quot;unsafe&quot; state."/>
<node CREATED="1237995910978" ID="Freemind_Link_1076783451" MODIFIED="1237995975049" TEXT="But that would be a simulation state which would be &#xa;reflected in order(sim) (no orders valid in that state)"/>
<node CREATED="1237996444434" ID="Freemind_Link_495357511" MODIFIED="1237996457531" TEXT="In fact, order(sim) shouldn&apos;t care what the states are"/>
<node CREATED="1237995944818" ID="Freemind_Link_1866017371" MODIFIED="1237995993920" TEXT="For now, simulation states will work fine">
<icon BUILTIN="ksmiletris"/>
</node>
</node>
<node CREATED="1237905827255" FOLDED="true" ID="Freemind_Link_1415932243" MODIFIED="1237994355539" POSITION="right" TEXT="Orders and the&#xa;RUNNING state">
<icon BUILTIN="flag"/>
<node CREATED="1237905855985" ID="Freemind_Link_443882547" MODIFIED="1237906580965" TEXT="If RUNNING is exclusive">
<icon BUILTIN="clanbomber"/>
<node CREATED="1237905904657" ID="Freemind_Link_139907757" MODIFIED="1237905913291" TEXT="Current plan"/>
<node CREATED="1237905913953" ID="Freemind_Link_167449304" MODIFIED="1237906023371" TEXT="Only SIM:PAUSE is valid to be sent while RUNNING"/>
<node CREATED="1237905936753" ID="Freemind_Link_1539708227" MODIFIED="1237906033162" TEXT="Many orders are valid to be scheduled while PAUSED, to be executed while RUNNING"/>
<node CREATED="1237905984961" ID="Freemind_Link_348084366" MODIFIED="1237906001002" TEXT="Scheduled orders are added to CIF as ORDER:SCHEDULE when scheduled"/>
<node CREATED="1237905947409" ID="Freemind_Link_766442494" MODIFIED="1237905977178" TEXT="Scheduled orders aren&apos;t added to CIF when executed"/>
<node CREATED="1237906229072" ID="Freemind_Link_553131509" MODIFIED="1237906249146" TEXT="While running up a CIF, only scheduled orders and SIM:PAUSE are executed while RUNNING"/>
</node>
<node CREATED="1237905895665" ID="Freemind_Link_899832199" MODIFIED="1237906574502" TEXT="If RUNNING is inclusive">
<icon BUILTIN="ksmiletris"/>
<node CREATED="1237906043009" ID="Freemind_Link_1071055283" MODIFIED="1237906081306" TEXT="Non-PREP orders can be sent while running, or scheduled"/>
<node CREATED="1237906082944" ID="Freemind_Link_1289112358" MODIFIED="1237906098138" TEXT="Orders sent while running are added to the CIF."/>
<node CREATED="1237906099024" ID="Freemind_Link_327272009" MODIFIED="1237906286150" TEXT="Undo info is cleared at the end of each tick.">
<icon BUILTIN="password"/>
</node>
<node CREATED="1237906180960" ID="Freemind_Link_657292086" MODIFIED="1237906186378" TEXT="Scheduled orders can be handled as above"/>
<node CREATED="1237906188865" ID="Freemind_Link_57874384" MODIFIED="1237906207674" TEXT="Only orders that are valid while RUNNING can be scheduled"/>
<node CREATED="1237906256672" ID="Freemind_Link_697314951" MODIFIED="1237906271050" TEXT="While running up a CIF, both CIF&apos;d orders and scheduled orders get executed."/>
</node>
<node CREATED="1237906413968" ID="Freemind_Link_1654717162" MODIFIED="1237906424874" TEXT="Hence, RUNNING should be inclusive!"/>
</node>
<node CREATED="1237580882012" ID="_" MODIFIED="1237997596493" POSITION="right" TEXT="Order States">
<icon BUILTIN="button_ok"/>
<node CREATED="1237994379237" ID="Freemind_Link_264832417" MODIFIED="1237997588677" TEXT="States in which it can be sent">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994407574" ID="Freemind_Link_187204294" MODIFIED="1237997591525" TEXT="States can be queried">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994385941" ID="Freemind_Link_1812223115" MODIFIED="1237996772839" TEXT="States in which it can be scheduled">
<icon BUILTIN="stop"/>
</node>
</node>
<node CREATED="1237997067841" ID="Freemind_Link_715365893" MODIFIED="1237999066646" POSITION="right" TEXT="Order &quot;options&quot; gets -sendstates option">
<icon BUILTIN="button_ok"/>
<node CREATED="1237997082433" ID="Freemind_Link_1568070707" MODIFIED="1237997092618" TEXT="Value is list of states"/>
<node CREATED="1237997095440" ID="Freemind_Link_1975780327" MODIFIED="1237997101562" TEXT="Omit option if all states are valid"/>
</node>
<node CREATED="1237994529509" ID="Freemind_Link_560027582" MODIFIED="1238000479576" POSITION="right" TEXT="order(sim) must be notified of current state">
<icon BUILTIN="button_ok"/>
<node CREATED="1237994856757" ID="Freemind_Link_727882507" MODIFIED="1237999421030" TEXT="&quot;order state&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237995332867" ID="Freemind_Link_1564955496" MODIFIED="1238000476752" TEXT="App binds ::sim &lt;Status&gt; to &quot;order state&quot;">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1237994537909" ID="Freemind_Link_602147061" MODIFIED="1238000967511" POSITION="right" TEXT="order(sim) automatically rejects orders if state is wrong">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237581083547" ID="Freemind_Link_1538825787" MODIFIED="1238001171353" POSITION="right" TEXT="Some non-order actions are affected by simulation state.">
<icon BUILTIN="button_ok"/>
<node CREATED="1238001145481" ID="Freemind_Link_807333882" MODIFIED="1238001148768" TEXT="Which?">
<node CREATED="1237581110347" ID="Freemind_Link_548617828" MODIFIED="1238001196023" TEXT="scenario new">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237581116092" ID="Freemind_Link_105832582" MODIFIED="1238001196024" TEXT="scenario open">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237581122140" ID="Freemind_Link_391541287" MODIFIED="1238001196023" TEXT="scenario save?">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237830270826" ID="Freemind_Link_62250874" MODIFIED="1237996714207" TEXT="sim restart">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238001173849" ID="Freemind_Link_1924283030" MODIFIED="1238001200351" TEXT="For now, define preconditions in each routine">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238001183433" ID="Freemind_Link_306871108" MODIFIED="1238001192737" TEXT="Later, update the GUI."/>
</node>
<node CREATED="1238001842536" ID="Freemind_Link_1609060583" MODIFIED="1238002220533" POSITION="right" TEXT="order(sim) sends &lt;State&gt; when state changes">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237996651968" ID="Freemind_Link_327626027" MODIFIED="1238002226389" POSITION="right" TEXT="order(sim) man page">
<icon BUILTIN="button_ok"/>
<node CREATED="1237996657328" ID="Freemind_Link_1966037457" MODIFIED="1237996675003" TEXT="&quot;options -sendstates&quot;"/>
<node CREATED="1237996675873" ID="Freemind_Link_1444410822" MODIFIED="1238001839409" TEXT="&quot;order state&quot;"/>
</node>
<node CREATED="1237996557809" FOLDED="true" ID="Freemind_Link_1697553362" MODIFIED="1237996563371" POSITION="right" TEXT="Subsequent work">
<node CREATED="1237995014548" ID="Freemind_Link_332214119" MODIFIED="1237995017823" TEXT="GUI">
<node CREATED="1237995094341" ID="Freemind_Link_1954543268" MODIFIED="1237995112766" TEXT="Action Manager">
<node CREATED="1237995164132" ID="Freemind_Link_237309003" MODIFIED="1237995167454" TEXT="Application defines actions">
<node CREATED="1237995517923" ID="Freemind_Link_1201722912" MODIFIED="1237995520269" TEXT="Order actions"/>
<node CREATED="1237995520931" ID="Freemind_Link_1181558353" MODIFIED="1237995524013" TEXT="Non-order actions"/>
</node>
<node CREATED="1237995113252" ID="Freemind_Link_996976429" MODIFIED="1237995129790" TEXT="Each action is associated with states">
<node CREATED="1237995503987" ID="Freemind_Link_347164691" MODIFIED="1237995509837" TEXT="Order states retrieved on demand"/>
<node CREATED="1237995538867" ID="Freemind_Link_434115069" MODIFIED="1237995543581" TEXT="Non-orders states are fixed"/>
</node>
<node CREATED="1237995130340" ID="Freemind_Link_1908790561" MODIFIED="1237995149230" TEXT="Action manager allows menu items, buttons, etc., to be created for an action"/>
<node CREATED="1237995177700" ID="Freemind_Link_1394156990" MODIFIED="1237995225229" TEXT="As state changes, all controls are automatically enabled/disabled"/>
</node>
<node CREATED="1237995197780" ID="Freemind_Link_812363857" MODIFIED="1237995202142" TEXT="State control">
<node CREATED="1237995202900" ID="Freemind_Link_156792157" MODIFIED="1237995209949" TEXT="GUI controls are associated with states"/>
<node CREATED="1237995464994" ID="Freemind_Link_455918835" MODIFIED="1237995473677" TEXT="Order controls">
<node CREATED="1237995474227" ID="Freemind_Link_644358395" MODIFIED="1237995482781" TEXT="Order states retrieved at creation time"/>
</node>
<node CREATED="1237995177700" ID="Freemind_Link_1275196334" MODIFIED="1237995225229" TEXT="As state changes, all controls are automatically enabled/disabled"/>
</node>
<node CREATED="1237995398099" ID="Freemind_Link_440124666" MODIFIED="1237995567771" TEXT="Control module binds to ::sim &lt;State&gt; to get state changes"/>
</node>
</node>
</node>
</map>
