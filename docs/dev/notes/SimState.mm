<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237580820610" ID="Freemind_Link_571023392" MODIFIED="1237580874803" TEXT="Effect of simulation&#xa;state on order handling">
<node CREATED="1237994464438" ID="Freemind_Link_442349793" MODIFIED="1237994469375" POSITION="right" TEXT="Non-GUI">
<node CREATED="1237581050220" ID="Freemind_Link_1947927414" MODIFIED="1237994515555" TEXT="Simulation states">
<icon BUILTIN="flag"/>
<node CREATED="1237581057020" ID="Freemind_Link_1522096514" MODIFIED="1237581058725" TEXT="PREP"/>
<node CREATED="1237581059516" ID="Freemind_Link_409826464" MODIFIED="1237581061989" TEXT="RUNNING"/>
<node CREATED="1237581062588" ID="Freemind_Link_759050256" MODIFIED="1237581064069" TEXT="PAUSED"/>
</node>
<node CREATED="1237995725828" ID="Freemind_Link_269184654" MODIFIED="1237995794377" TEXT="Should order states match simulation states?&#xa;Important distinction is &quot;Prep&quot; vs. &quot;Non-Prep&quot;,&#xa;or &quot;Scenario&quot; vs. &quot;Simulation&quot;.">
<icon BUILTIN="help"/>
<node CREATED="1237995795779" ID="Freemind_Link_1366655686" MODIFIED="1237995804572" TEXT="App could translated from sim state to order state"/>
<node CREATED="1237995847795" ID="Freemind_Link_774669824" MODIFIED="1237995909164" TEXT="In JNEM, when saving/restoring/etc., could have &quot;unsafe&quot; state."/>
<node CREATED="1237995910978" ID="Freemind_Link_1076783451" MODIFIED="1237995975049" TEXT="But that would be a simulation state which would be &#xa;reflected in order(sim) (no orders valid in that state)"/>
<node CREATED="1237995944818" ID="Freemind_Link_1866017371" MODIFIED="1237995993920" TEXT="For now, simulation states will work fine">
<icon BUILTIN="ksmiletris"/>
</node>
</node>
<node CREATED="1237905827255" FOLDED="true" ID="Freemind_Link_1415932243" MODIFIED="1237994355539" TEXT="Orders and the&#xa;RUNNING state">
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
<node CREATED="1237580882012" ID="_" MODIFIED="1237994378432" TEXT="Order States">
<node CREATED="1237994379237" ID="Freemind_Link_264832417" MODIFIED="1237994385343" TEXT="States in which it can be sent"/>
<node CREATED="1237994385941" ID="Freemind_Link_1812223115" MODIFIED="1237994392751" TEXT="States in which it can be scheduled"/>
<node CREATED="1237994407574" ID="Freemind_Link_187204294" MODIFIED="1237994413327" TEXT="States can be queried"/>
</node>
<node CREATED="1237994529509" ID="Freemind_Link_560027582" MODIFIED="1237994849135" TEXT="order(sim) must be notified of current state">
<node CREATED="1237994856757" ID="Freemind_Link_727882507" MODIFIED="1237995285673" TEXT="&quot;order setstate&quot;">
<icon BUILTIN="help"/>
<node CREATED="1237994980660" ID="Freemind_Link_1775255881" MODIFIED="1237994986926" TEXT="Must always remember to tell it."/>
</node>
<node CREATED="1237994866324" ID="Freemind_Link_475559052" MODIFIED="1237995282097" TEXT="Register -statecmd">
<icon BUILTIN="help"/>
<node CREATED="1237994950324" ID="Freemind_Link_860049690" MODIFIED="1237994956590" TEXT="Can always pull it when it needs it."/>
</node>
<node CREATED="1237995299539" ID="Freemind_Link_1505211884" MODIFIED="1237995322273" TEXT="order(sim) listens for ::sim &lt;State&gt;">
<icon BUILTIN="help"/>
</node>
<node CREATED="1237995332867" ID="Freemind_Link_1564955496" MODIFIED="1237995385961" TEXT="App binds ::sim &lt;State&gt; to &quot;order setstate&quot;">
<icon BUILTIN="ksmiletris"/>
</node>
</node>
<node CREATED="1237994537909" ID="Freemind_Link_602147061" MODIFIED="1237994549631" TEXT="order(sim) automatically rejects orders if state is wrong"/>
<node CREATED="1237581083547" ID="Freemind_Link_1538825787" MODIFIED="1237906538009" TEXT="Some non-order actions are affected by simulation state">
<node CREATED="1237995050308" ID="Freemind_Link_1576259399" MODIFIED="1237995053812" TEXT="Which?">
<node CREATED="1237581110347" ID="Freemind_Link_548617828" MODIFIED="1237581115429" TEXT="scenario new"/>
<node CREATED="1237581116092" ID="Freemind_Link_105832582" MODIFIED="1237581121461" TEXT="scenario open"/>
<node CREATED="1237581122140" ID="Freemind_Link_391541287" MODIFIED="1237581140005" TEXT="scenario save?"/>
<node CREATED="1237830270826" ID="Freemind_Link_62250874" MODIFIED="1237830290086" TEXT="sim restart"/>
</node>
<node CREATED="1237995061012" ID="Freemind_Link_1718000763" MODIFIED="1237995079555" TEXT="Define preconditions!"/>
</node>
</node>
<node CREATED="1237995014548" ID="Freemind_Link_332214119" MODIFIED="1237995017823" POSITION="right" TEXT="GUI">
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
</map>
