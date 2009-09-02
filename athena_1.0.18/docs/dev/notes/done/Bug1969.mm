<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1238185942456" ID="Freemind_Link_405704848" MODIFIED="1238431373795" TEXT="Snapshot Navigation&#xa;and the SNAPSHOT State">
<node CREATED="1238190921792" ID="Freemind_Link_1311836518" MODIFIED="1238190995647" POSITION="right" TEXT="The &quot;latest time&quot; is the latest sim time &#xa;achieved for this scenario.  There might or might&#xa;not be a snapshot at the latest time.">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238190851871" ID="_" MODIFIED="1238431338513" POSITION="right" TEXT="Navigation">
<icon BUILTIN="button_ok"/>
<node CREATED="1237994176614" ID="Freemind_Link_343371493" MODIFIED="1238189988024" TEXT="Controls: first, previous, next, last">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994196662" ID="Freemind_Link_122266377" MODIFIED="1238187633108" TEXT="&quot;First&quot; control replaces &quot;restart&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994206534" ID="Freemind_Link_1540265172" MODIFIED="1238187627189" TEXT="Use iPod icons: double triangles, with a vertical line for first and last">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1237994262438" ID="Freemind_Link_1024035268" MODIFIED="1238190906394" TEXT="If there&apos;s no checkpoint at the current time, create one">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238191030192" ID="Freemind_Link_322032318" MODIFIED="1238431348609" POSITION="right" TEXT="SNAPSHOT State">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191408045" ID="Freemind_Link_1598909806" MODIFIED="1238431334330" TEXT="Enter the SNAPSHOT state:">
<icon BUILTIN="button_ok"/>
<node CREATED="1237994284725" ID="Freemind_Link_128499237" MODIFIED="1238194043206" TEXT="On loading a snapshot prior to the &quot;latest time&quot;">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238191433694" ID="Freemind_Link_930869996" MODIFIED="1238194369869" TEXT="On loading a scenario that was saved in the SNAPSHOT state">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238015602360" ID="Freemind_Link_1868904837" MODIFIED="1238431334329" TEXT="In SNAPSHOT, most orders are disabled">
<icon BUILTIN="button_ok"/>
<node CREATED="1238191465582" ID="Freemind_Link_1154318956" MODIFIED="1238191495508" TEXT="Prevents history from being changed">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238015609784" ID="Freemind_Link_1583241154" MODIFIED="1238194054864" TEXT="Must leave SNAPSHOT explicitly to change things">
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
<node CREATED="1238015681529" ID="Freemind_Link_1703074413" MODIFIED="1238428648951" TEXT="Need special handling for GUI interactions">
<icon BUILTIN="button_ok"/>
<node CREATED="1238015700680" ID="Freemind_Link_1732762311" MODIFIED="1238015705266" TEXT="E.g., dragging units"/>
</node>
</node>
<node CREATED="1238425808630" ID="Freemind_Link_1294854083" MODIFIED="1238427813545" POSITION="right" TEXT="Reflections over the weekend">
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
<node CREATED="1238426269478" ID="Freemind_Link_674135358" MODIFIED="1238431325025" POSITION="right" TEXT="Before we&apos;re done:">
<icon BUILTIN="button_ok"/>
<node CREATED="1238426273798" ID="Freemind_Link_918478796" MODIFIED="1238431325026" TEXT="scenario(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238426283366" ID="Freemind_Link_990041422" MODIFIED="1238431325026" TEXT="sim(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</map>
