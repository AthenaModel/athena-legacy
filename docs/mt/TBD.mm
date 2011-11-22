<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node TEXT="To Be Done" ID="ID_1469859847" CREATED="1320093190250" MODIFIED="1320339554139">
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="In Engine" POSITION="right" ID="ID_1559292349" CREATED="1320855757191" MODIFIED="1320855758651">
<node TEXT="::aram" ID="ID_1872325616" CREATED="1320855768119" MODIFIED="1320855770019">
<node TEXT="Saveable" ID="ID_1679407378" CREATED="1320855770960" MODIFIED="1320855772690">
<node TEXT="Can we simply define an ::aram wart, and register it as saveable only in App thread?" ID="ID_1138045786" CREATED="1320855781623" MODIFIED="1320855806498"/>
</node>
</node>
<node TEXT="::bsystem" ID="ID_1558655288" CREATED="1320855999247" MODIFIED="1320856001187">
<node TEXT="For now, we only need a mam(n) in the main thread." ID="ID_1141458618" CREATED="1320856004367" MODIFIED="1320856044818"/>
<node TEXT="bsystem(n) can be left in ::sim, and doesn&apos;t need to be in ::engine." ID="ID_1623681844" CREATED="1320856100612" MODIFIED="1320856121032"/>
<node TEXT="It can move into ::engine when we begin to adjust belief systems at run time." ID="ID_307540610" CREATED="1320856121547" MODIFIED="1320856137190"/>
</node>
<node TEXT="::eventq" ID="ID_1882875344" CREATED="1320855808094" MODIFIED="1320855811081">
<node TEXT="Saveable" ID="ID_1234414197" CREATED="1320855811557" MODIFIED="1320855813145">
<node TEXT="Can we simply define an ::eventq wart, and register it as saveable only in App thread?" ID="ID_784006160" CREATED="1320855781623" MODIFIED="1320855828129"/>
</node>
</node>
<node TEXT="::situation" ID="ID_1053578136" CREATED="1320855646883" MODIFIED="1320855766379">
<node TEXT="Saveable" ID="ID_985176921" CREATED="1320855842901" MODIFIED="1320855844488">
<node TEXT="Registers as a saveable so that it can flush its cache on restore." ID="ID_689199382" CREATED="1320855650955" MODIFIED="1320855662702"/>
<node TEXT="Also flushes cache on DbSyncA." ID="ID_1440289821" CREATED="1320855663178" MODIFIED="1320855696493"/>
<node TEXT="Is this redundant?" ID="ID_1491882634" CREATED="1320855697066" MODIFIED="1320855864799"/>
</node>
</node>
</node>
<node TEXT="Fix [parmdb] vs [parm] confusion in athena(1) code." POSITION="right" ID="ID_803341418" CREATED="1320856427002" MODIFIED="1320856455884">
<node TEXT="Some times it retrieves parms using parmdb, and sometimes using parm." ID="ID_650663845" CREATED="1320856456472" MODIFIED="1320856468156"/>
</node>
<node TEXT="Determine what application infrastructure/data sync are required by the engine thread" POSITION="right" ID="ID_832077590" CREATED="1320703793586" MODIFIED="1320703819155">
<node TEXT="::log" ID="ID_1558267840" CREATED="1320703827992" MODIFIED="1320703831112"/>
<node TEXT="::map" ID="ID_1794842578" CREATED="1320703831463" MODIFIED="1320703832711"/>
<node TEXT="::parm" ID="ID_938618130" CREATED="1320703836058" MODIFIED="1320703837540"/>
<node TEXT="::rdb" ID="ID_654309373" CREATED="1320703840168" MODIFIED="1320703841307"/>
<node TEXT="::econ" FOLDED="true" ID="ID_312359763" CREATED="1320703860581" MODIFIED="1320703862032">
<node TEXT="In App, to drive econsheet" ID="ID_525879968" CREATED="1320703862992" MODIFIED="1320703873023"/>
</node>
</node>
<node TEXT="Determine what the ::engine object has to do." POSITION="right" ID="ID_819297182" CREATED="1320795835061" MODIFIED="1320795848672">
<node TEXT="Threaded" ID="ID_1349340921" CREATED="1320795868732" MODIFIED="1320795871976"/>
<node TEXT="Unthreaded" ID="ID_844266405" CREATED="1320795872284" MODIFIED="1320795877295"/>
</node>
<node TEXT="Looking for notifier bindings, esp. to ::sim &lt;State&gt;" POSITION="right" ID="ID_1353906143" CREATED="1320795881307" MODIFIED="1320795897814"/>
<node TEXT="Add Engine thread" FOLDED="true" POSITION="right" ID="ID_1862623788" CREATED="1320339452486" MODIFIED="1320703891634">
<node TEXT="Fill in main object" ID="ID_1326094270" CREATED="1320348375636" MODIFIED="1320348383775">
<node TEXT="Create mapref(n) called map, to respond to shared map projection requests" ID="ID_2657481" CREATED="1320348388634" MODIFIED="1320348400870"/>
<node TEXT="Arrange for map to be properly configured." ID="ID_161357669" CREATED="1320348401259" MODIFIED="1320348409982"/>
<node TEXT="Create relevant order interfaces" ID="ID_488178027" CREATED="1320351015898" MODIFIED="1320351023189"/>
</node>
</node>
<node TEXT="Make threading optional for ::engine" POSITION="right" ID="ID_89797418" CREATED="1320703954375" MODIFIED="1320795863376"/>
<node TEXT="Fix all known problems." POSITION="right" ID="ID_1205170327" CREATED="1320339533547" MODIFIED="1320339538455"/>
<node TEXT="Make sure that lib/*/* directories are included in source tarball!" POSITION="right" ID="ID_216393512" CREATED="1320344469925" MODIFIED="1320703925202">
<icon BUILTIN="yes"/>
</node>
<node TEXT="Done" FOLDED="true" POSITION="left" ID="ID_1140761717" CREATED="1320703985170" MODIFIED="1320703986199">
<node TEXT="Assume that the Engine thread is created at start-up and re-initialized as required (as the engine is now)!" ID="ID_676544333" CREATED="1320339262708" MODIFIED="1320441110568">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Create stub app_sim_shared package" ID="ID_1440734759" CREATED="1320339239012" MODIFIED="1320347676561">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Create stub app_sim_engine package" ID="ID_1086058014" CREATED="1320343871132" MODIFIED="1320347676560">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Create stub app_sim_ui" ID="ID_127212576" CREATED="1320703646283" MODIFIED="1320703677835">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Create app_sim_logger package" FOLDED="true" ID="ID_240333363" CREATED="1320703684169" MODIFIED="1320703721660">
<icon BUILTIN="button_ok"/>
<node TEXT="Proof of concept for threading." ID="ID_1974492418" CREATED="1320703713938" MODIFIED="1320703718774"/>
</node>
<node TEXT="Move obvious &quot;ui&quot; modules to ui/, examining each for dependencies" ID="ID_1271944829" CREATED="1320343938850" MODIFIED="1320703933907">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Make sure that lib/*/* directories are included in executable!" ID="ID_1492579603" CREATED="1320344469925" MODIFIED="1320703917210">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Remove &quot;redo&quot; entries from the cif table, and keep them in memory." ID="ID_1283985088" CREATED="1320705669186" MODIFIED="1320771120385">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Make threading optional for Logger thread" ID="ID_1043112530" CREATED="1320703940639" MODIFIED="1320772631910">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Fixed up parm(sim) for use in shared." ID="ID_1784194467" CREATED="1320793133607" MODIFIED="1320793140931"/>
</node>
</node>
</map>
