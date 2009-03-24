<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237580820610" ID="Freemind_Link_571023392" MODIFIED="1237580874803" TEXT="Effect of simulation&#xa;state on order handling">
<node CREATED="1237581050220" ID="Freemind_Link_1947927414" MODIFIED="1237581056502" POSITION="right" TEXT="Simulation states">
<node CREATED="1237581057020" ID="Freemind_Link_1522096514" MODIFIED="1237581058725" TEXT="PREP"/>
<node CREATED="1237581059516" ID="Freemind_Link_409826464" MODIFIED="1237581061989" TEXT="RUNNING"/>
<node CREATED="1237581062588" ID="Freemind_Link_759050256" MODIFIED="1237581064069" TEXT="PAUSED"/>
<node CREATED="1237581073579" ID="Freemind_Link_1933691622" MODIFIED="1237906504326" TEXT="Might there be other states of interest?">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237580882012" ID="_" MODIFIED="1237580941270" POSITION="right" TEXT="Each order has a set of states in which it is enabled."/>
<node CREATED="1237580892892" ID="Freemind_Link_1149669543" MODIFIED="1237906467240" POSITION="right" TEXT="Orders valid in RUNNING can be scheduled for later."/>
<node CREATED="1237580967116" ID="Freemind_Link_578127553" MODIFIED="1237906492648" POSITION="right" TEXT="Orders can be scheduled while RUNNING."/>
<node CREATED="1237581083547" ID="Freemind_Link_1538825787" MODIFIED="1237906538009" POSITION="right" TEXT="Some non-order actions are affected by simulation state">
<node CREATED="1237581110347" ID="Freemind_Link_548617828" MODIFIED="1237581115429" TEXT="scenario new"/>
<node CREATED="1237581116092" ID="Freemind_Link_105832582" MODIFIED="1237581121461" TEXT="scenario open"/>
<node CREATED="1237581122140" ID="Freemind_Link_391541287" MODIFIED="1237581140005" TEXT="scenario save?"/>
<node CREATED="1237830270826" ID="Freemind_Link_62250874" MODIFIED="1237830290086" TEXT="sim restart"/>
</node>
<node CREATED="1237905827255" ID="Freemind_Link_1415932243" MODIFIED="1237905852050" POSITION="right" TEXT="Orders and the&#xa;RUNNING state">
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
</node>
</map>
