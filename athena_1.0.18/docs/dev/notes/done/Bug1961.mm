<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1237925251574" ID="Freemind_Link_990918549" MODIFIED="1237930498518" TEXT="Auto-snapshots">
<node CREATED="1237925370856" ID="_" MODIFIED="1237930196699" POSITION="right" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1237564822348" ID="Freemind_Link_1094167895" MODIFIED="1237930312422" TEXT="SIM:RUN saves snapshot before transition to RUNNING"/>
<node CREATED="1237925391335" ID="Freemind_Link_35673962" MODIFIED="1237930317238" TEXT="Snapthos are indexed by time tick"/>
<node CREATED="1237829994090" ID="Freemind_Link_1764789611" MODIFIED="1237930324134" TEXT="User can return to old snapshots"/>
<node CREATED="1237925413176" ID="Freemind_Link_1237604361" MODIFIED="1237930331292" TEXT="On transition to RUNNING, snapshots with a&#xa;timestamp in the future are deleted."/>
<node CREATED="1237925460087" ID="Freemind_Link_1999447952" MODIFIED="1237930337766" TEXT="&quot;sim restart&quot; uses a tick 0 snapshot"/>
<node CREATED="1237830058698" ID="Freemind_Link_1660914597" MODIFIED="1237930344230" TEXT="Save snapshots in RDB, ADB"/>
</node>
<node CREATED="1237823273480" ID="Freemind_Link_1214250639" MODIFIED="1237927052626" POSITION="right" TEXT="saveables(i) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1237830033193" ID="Freemind_Link_355979907" MODIFIED="1237930399676" TEXT="At present, saveables assume that &quot;checkpoint&quot; means &#xa;they have been saved.  But to take a snapshot, we need to&#xa;checkpoint the object without saving the scenario from the&#xa;user&apos;s point of view.">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1237823316552" ID="Freemind_Link_1633805485" MODIFIED="1237927052627" TEXT="Must be able to call saveable&apos;s &quot;checkpoint&quot; method&#xa;without setting the object&apos;s &quot;saved&quot; flag, e.g.,&#xa;&quot;$object checkpoint -saved&quot; vs. &quot;$object checkpoint&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237926973125" ID="Freemind_Link_1625876850" MODIFIED="1237927052631" TEXT="Also need &quot;$object restore -saved&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237927034980" ID="Freemind_Link_788063086" MODIFIED="1237927052631" TEXT="Also need to update cli(n)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237927057828" ID="Freemind_Link_1556030027" MODIFIED="1237927318929" TEXT="Need to update Athena to set -saved flag.">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1237925680583" ID="Freemind_Link_1937953768" MODIFIED="1237930180115" POSITION="right" TEXT="scenariodb(n) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1237830107610" ID="Freemind_Link_1797755349" MODIFIED="1237927656664" TEXT="Rename &quot;checkpoints&quot; table to &quot;saveables&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237925988247" ID="Freemind_Link_1861534257" MODIFIED="1237930144612" TEXT="&quot;export&quot; should let you specify tables to include or tables to exclude.">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237925714264" ID="Freemind_Link_11706642" MODIFIED="1237930144611" TEXT="&quot;import&quot; should only clear the entire DB when asked to do so">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237830119434" ID="Freemind_Link_1657153926" MODIFIED="1237930412662" TEXT="Add &quot;snapshots&quot; table, with key &quot;tick&quot;">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1237925751527" ID="Freemind_Link_1619052283" MODIFIED="1237932779173" POSITION="right" TEXT="scenario(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1237927674658" ID="Freemind_Link_260610058" MODIFIED="1237927692728" TEXT="Save saveables in saveables table, instead of &quot;checkpoint&quot; table">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237925756871" ID="Freemind_Link_1752575671" MODIFIED="1237932772077" TEXT="Can save snapshot as of current tick">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237830129242" ID="Freemind_Link_1826040449" MODIFIED="1237932772079" TEXT="To save a snapshot">
<icon BUILTIN="button_ok"/>
<node CREATED="1237830146106" ID="Freemind_Link_880660979" MODIFIED="1237830151395" TEXT="Save working data as XML"/>
<node CREATED="1237830152058" ID="Freemind_Link_243868175" MODIFIED="1237930431270" TEXT="Exclude the maps and snapshots tables"/>
</node>
<node CREATED="1237925803000" ID="Freemind_Link_1578002613" MODIFIED="1237932772078" TEXT="Can restore specified snapshot">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237830186136" ID="Freemind_Link_258901333" MODIFIED="1237932772078" TEXT="To restore a snapshot">
<icon BUILTIN="button_ok"/>
<node CREATED="1237830190744" ID="Freemind_Link_1078181867" MODIFIED="1237930448998" TEXT="Reload the XML for the snapshot"/>
<node CREATED="1237830202729" ID="Freemind_Link_1109472895" MODIFIED="1237830213155" TEXT="Will replace contents of all tables included in the XML."/>
</node>
<node CREATED="1237925825639" ID="Freemind_Link_566018132" MODIFIED="1237932772078" TEXT="Can purge snapshots">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1237925850598" ID="Freemind_Link_367778501" MODIFIED="1237934457705" POSITION="right" TEXT="simulation(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1237925914999" ID="Freemind_Link_900937125" MODIFIED="1237934457706" TEXT="On transition to RUNNING">
<icon BUILTIN="button_ok"/>
<node CREATED="1237925923495" ID="Freemind_Link_246661448" MODIFIED="1237930467477" TEXT="Auto-snapshots as of &quot;now&quot;"/>
<node CREATED="1237925930231" ID="Freemind_Link_811822446" MODIFIED="1237930473605" TEXT="Deletes snapshots with t &gt; &quot;now&quot;"/>
</node>
<node CREATED="1237925868327" ID="Freemind_Link_1269800887" MODIFIED="1237934457706" TEXT="On &quot;sim restart&quot;">
<icon BUILTIN="button_ok"/>
<node CREATED="1237925505320" ID="Freemind_Link_1770376537" MODIFIED="1237930476790" TEXT="Saves a snapshot at the current time"/>
<node CREATED="1237925495896" ID="Freemind_Link_244022255" MODIFIED="1237930481270" TEXT="Loads the tick 0 snapshot"/>
</node>
</node>
<node CREATED="1237934483011" ID="Freemind_Link_1445015481" MODIFIED="1237934487549" POSITION="right" TEXT="Subsequent Packages">
<node CREATED="1237934508163" ID="Freemind_Link_989057923" MODIFIED="1237934522797" TEXT="GUI to load particular snapshots"/>
<node CREATED="1237829977146" ID="Freemind_Link_911436126" MODIFIED="1237934531177" TEXT="explicit snapshots, if needed"/>
</node>
</node>
</map>
