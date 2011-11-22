<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node TEXT="RDB" ID="ID_660772105" CREATED="1320794967286" MODIFIED="1320794970467">
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="scenario(sim) creates a new RDB file each time a scenario is opened or created." POSITION="right" ID="ID_451759935" CREATED="1320794975343" MODIFIED="1320794989490"/>
<node TEXT="All application views and functions need to be available in both threads." POSITION="right" ID="ID_121675314" CREATED="1321037460767" MODIFIED="1321037470839"/>
<node TEXT="Engine thread needs to keep synchronized" POSITION="right" ID="ID_1387409621" CREATED="1320795006638" MODIFIED="1320795027450"/>
<node TEXT="Engine will need to [rdb close]/[rdb open] each time scenario(sim) creates a new RDB." POSITION="right" ID="ID_1622978917" CREATED="1320795028174" MODIFIED="1320795054249"/>
<node TEXT="Probably not a good idea for App to delete the .rdb file that Engine has open." POSITION="right" ID="ID_189697380" CREATED="1320795101747" MODIFIED="1320795124278"/>
<node TEXT="Need to propagate &lt;DbSyncA&gt; to Engine" FOLDED="true" POSITION="right" ID="ID_152604274" CREATED="1320795737936" MODIFIED="1320795752667">
<node TEXT="nbhood refresh geoset" ID="ID_1295159411" CREATED="1320795753335" MODIFIED="1320795758971"/>
<node TEXT="situation flushes its cache" ID="ID_456526991" CREATED="1320795759407" MODIFIED="1320795797450"/>
</node>
<node TEXT="Needed in Engine thread" FOLDED="true" POSITION="right" ID="ID_1261646536" CREATED="1320855475801" MODIFIED="1320855481228">
<node TEXT="A scenariodb called ::rdb" ID="ID_1176348033" CREATED="1320855481721" MODIFIED="1320855490019"/>
<node TEXT="That has all application SQL functions defined" ID="ID_1443744151" CREATED="1320855490336" MODIFIED="1320855498724"/>
<node TEXT="Along with the GUI views." FOLDED="true" ID="ID_667020297" CREATED="1320855499096" MODIFIED="1320855506732">
<node TEXT="gui_views.sql should be renamed." ID="ID_414429559" CREATED="1320855507079" MODIFIED="1320855512427"/>
</node>
</node>
<node TEXT="Minimal synchronization:" FOLDED="true" POSITION="right" ID="ID_301043161" CREATED="1320795126899" MODIFIED="1320855469515">
<icon BUILTIN="button_ok"/>
<node TEXT="When a new scenario is opened/created, do this." ID="ID_1650758143" CREATED="1320795154666" MODIFIED="1320795163349"/>
<node TEXT="thread::send {rdb close}" FOLDED="true" ID="ID_245878353" CREATED="1320795163801" MODIFIED="1320795177205">
<node TEXT="Synchronous!" ID="ID_751957995" CREATED="1320795204360" MODIFIED="1320795210739"/>
</node>
<node TEXT="create new RDB" ID="ID_1347695753" CREATED="1320795177649" MODIFIED="1320795184012"/>
<node TEXT="thread::send {rdb open}" FOLDED="true" ID="ID_1035423362" CREATED="1320795184569" MODIFIED="1320795189501">
<node TEXT="Synchronous!" ID="ID_1436261987" CREATED="1320795216008" MODIFIED="1320795219284"/>
</node>
<node TEXT="The thread::sends would actually be ::engine calls, no-op when single-threaded." ID="ID_655122164" CREATED="1320795295366" MODIFIED="1320795322680"/>
</node>
<node TEXT="Every tick synchronization" FOLDED="true" POSITION="right" ID="ID_1406716452" CREATED="1320795331908" MODIFIED="1320795338800">
<node TEXT="At the beginning of each request to the Engine, open the RDB." ID="ID_1902543183" CREATED="1320795339356" MODIFIED="1320795364463"/>
<node TEXT="At the end of each request to the Engine, close the RDB." ID="ID_1254870617" CREATED="1320795364899" MODIFIED="1320795372071"/>
<node TEXT="On OS X laptop, about 10 milliseconds overhead" ID="ID_205392851" CREATED="1320795376635" MODIFIED="1320795401453"/>
<node TEXT="For test scenario, this overhead would make it run about 5% slower." ID="ID_330949082" CREATED="1320795555269" MODIFIED="1320795596119"/>
<node TEXT="For large scenarios, it&apos;s probably irrelevant." ID="ID_158238846" CREATED="1320795596556" MODIFIED="1320795609312"/>
</node>
</node>
</map>
