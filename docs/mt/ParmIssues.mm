<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node TEXT="parm.tcl issues" ID="ID_1001881119" CREATED="1320775709574" MODIFIED="1320775715644">
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="Both App and Engine need access to the parmdb." POSITION="right" ID="ID_690924583" CREATED="1320775716863" MODIFIED="1320775752242"/>
<node TEXT="At present, the PARM::* orders can only successfully be used by the App thread." POSITION="right" ID="ID_1375347682" CREATED="1320775752926" MODIFIED="1320775947572"/>
<node TEXT="However, the &quot;parm&quot; executive commands are defined in both threads." POSITION="right" ID="ID_1599830545" CREATED="1320775798061" MODIFIED="1320775812656"/>
<node TEXT="The orders need to be defined in both threads, so that attempts to use the [parm] commands will get proper error messages." POSITION="right" ID="ID_702771520" CREATED="1320775813084" MODIFIED="1320775831351"/>
<node TEXT="parm.tcl does" POSITION="right" ID="ID_39892950" CREATED="1320775921857" MODIFIED="1320775926301">
<node TEXT="Initializes and wraps parmdb(5)" ID="ID_556148533" CREATED="1320775926832" MODIFIED="1320776145193"/>
<node TEXT="Defines PARM:* orders and mutators" ID="ID_20059239" CREATED="1320775933192" MODIFIED="1320775952460"/>
<node TEXT="Defines executive command bodies, which call &quot;order send cli&quot;." ID="ID_40101145" CREATED="1320775954016" MODIFIED="1320775968539">
<node TEXT="Is this OK in Engine?" ID="ID_599159612" CREATED="1320775969791" MODIFIED="1320775981558">
<icon BUILTIN="help"/>
</node>
<node TEXT="Should they use &quot;send&quot; instead?" ID="ID_763675527" CREATED="1320776067036" MODIFIED="1320776072935">
<node TEXT="Other orders do" ID="ID_1229525666" CREATED="1320776085396" MODIFIED="1320776088047"/>
</node>
<node TEXT="They should be defined in executive, in any event." ID="ID_1431127551" CREATED="1320776073420" MODIFIED="1320776129530"/>
</node>
<node TEXT="Locks/unlocks certain parameters on state change" ID="ID_1141165602" CREATED="1320776150529" MODIFIED="1320776163245">
<node TEXT="Based on notifier event" ID="ID_1879115623" CREATED="1320776236630" MODIFIED="1320776239962"/>
</node>
<node TEXT="Registers parm as a saveable, so that parameter settings are saved in snapshots and scenario files" ID="ID_1909262618" CREATED="1320776188808" MODIFIED="1320776205060"/>
</node>
<node TEXT="What prevents parm.tcl from being used as is in Engine?" POSITION="right" ID="ID_376935670" CREATED="1320776270702" MODIFIED="1320776281883">
<node TEXT="No need to register as a saveable; and ::scenario might not exist." ID="ID_1383791687" CREATED="1320776282501" MODIFIED="1320776297720"/>
<node TEXT="Can lock parameters immediately; sim state is effectively always &quot;running&quot; in Engine" ID="ID_1740136820" CREATED="1320776298885" MODIFIED="1320776329600"/>
</node>
<node TEXT="What is required to make parm available in Engine?" POSITION="right" ID="ID_394164477" CREATED="1320776351731" MODIFIED="1320776361678">
<node TEXT="Changes in App need to be propagated to Engine" ID="ID_956992390" CREATED="1320776363290" MODIFIED="1320776415772"/>
<node TEXT="parmdb(n) should allow definition of -notifycmd." ID="ID_596730943" CREATED="1320776430817" MODIFIED="1320776440132"/>
<node TEXT="parm(sim) should define a -notifycmd, and send a notifier event when parms change in any way." ID="ID_387860863" CREATED="1320776441552" MODIFIED="1320776492370"/>
<node TEXT="::engine should register to receive these notifier events." ID="ID_1816073760" CREATED="1320776493198" MODIFIED="1320776525481"/>
<node TEXT="On notify, ::engine can call [parm checkpoint] and send result to [parm restore] in the Engine thread." ID="ID_1050008904" CREATED="1320776525957" MODIFIED="1320776581919"/>
</node>
<node TEXT="To Be Done" POSITION="right" ID="ID_239715583" CREATED="1320776590475" MODIFIED="1320776596038">
<node TEXT="Add -mode option to parm(sim), &quot;master&quot; or &quot;slave&quot;." ID="ID_1923674565" CREATED="1320776596555" MODIFIED="1320793118239">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Move executive command implementations to executive.tcl" ID="ID_1197974689" CREATED="1320778722345" MODIFIED="1320791634018">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="master mode" ID="ID_331502702" CREATED="1320777879923" MODIFIED="1320777883495">
<node TEXT="::scenario register" ID="ID_404042162" CREATED="1320777884708" MODIFIED="1320793108794">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Lock/unlock parms on ::sim &lt;State&gt;" ID="ID_711712119" CREATED="1320777893602" MODIFIED="1320793108794">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node TEXT="slave mode" ID="ID_224955391" CREATED="1320777939985" MODIFIED="1320777941725">
<node TEXT="Don&apos;t ::scenario register" ID="ID_1199010457" CREATED="1320777942145" MODIFIED="1320793108794">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Lock parms immediately, and leave them locked." ID="ID_1646442046" CREATED="1320777951353" MODIFIED="1320793108793">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node TEXT="::engine object" ID="ID_632689542" CREATED="1320777979864" MODIFIED="1320777993931">
<node TEXT="Bind to ::parm &lt;Update&gt;" ID="ID_55196456" CREATED="1320777994480" MODIFIED="1320777999003"/>
<node TEXT="Synchronize Engine/::parm on change to App/::parm" ID="ID_1472955483" CREATED="1320777999440" MODIFIED="1320778018202"/>
</node>
</node>
</node>
</map>
