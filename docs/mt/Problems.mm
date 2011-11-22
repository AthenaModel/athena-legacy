<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node TEXT="Problems" ID="ID_769325276" CREATED="1320168423560" MODIFIED="1320168426353">
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="Concept" FOLDED="true" POSITION="right" ID="ID_1778733390" CREATED="1320168427125" MODIFIED="1320248106933">
<icon BUILTIN="idea"/>
<node TEXT="Problems to be solved for either of the new architectures to work." ID="ID_1847004587" CREATED="1320248107861" MODIFIED="1320248138321"/>
<node TEXT="If a problem applies to only one of the architectures, it is tagged with that architecture" ID="ID_1918586837" CREATED="1320248159652" MODIFIED="1320248318540"/>
<node TEXT="App/Engine Architecture" ID="ID_432107343" CREATED="1320248374440" MODIFIED="1320248413858">
<icon BUILTIN="full-1"/>
</node>
<node TEXT="Sim/GUI Architecture" ID="ID_408807827" CREATED="1320248391742" MODIFIED="1320248405792">
<icon BUILTIN="full-2"/>
</node>
</node>
<node TEXT="Show-Stoppers" POSITION="right" ID="ID_417553089" CREATED="1320169316231" MODIFIED="1320169414453">
<icon BUILTIN="clanbomber"/>
</node>
<node TEXT="To Be Solved" POSITION="right" ID="ID_377847663" CREATED="1320169295163" MODIFIED="1320169312729">
<icon BUILTIN="smily_bad"/>
<node TEXT="Re-architecting Athena" ID="ID_1424753094" CREATED="1320169144084" MODIFIED="1320248449312">
<node TEXT="Athena code must be pulled into distinct sets for the two threads" ID="ID_1039201905" CREATED="1320169155168" MODIFIED="1320169198411"/>
<node TEXT="Long and tedious" ID="ID_401514145" CREATED="1320169208637" MODIFIED="1320169212303"/>
<node TEXT="Expect to find additional problems over time" ID="ID_452823302" CREATED="1320169212561" MODIFIED="1320169228894"/>
</node>
<node TEXT="Handling of unexpected errors in threads" ID="ID_758921361" CREATED="1320266402316" MODIFIED="1320266419913"/>
<node TEXT="Synchronize simclock across threads" ID="ID_435140049" CREATED="1320170222801" MODIFIED="1320170228901">
<node TEXT="All threads need the simclock" ID="ID_761339728" CREATED="1320170229611" MODIFIED="1320170234026"/>
<node TEXT="Must be synchronized across threads" ID="ID_1999054226" CREATED="1320170234736" MODIFIED="1320170240118"/>
<node TEXT="Handled for Logger thread (but Engine thread doesn&apos;t yet exist)" ID="ID_536584998" CREATED="1320335565142" MODIFIED="1320335628575">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node TEXT="Executive object" ID="ID_803421110" CREATED="1320704332876" MODIFIED="1320704343655">
<node TEXT="Should be type-with-instances" ID="ID_1650985173" CREATED="1320354689280" MODIFIED="1320354693643"/>
<node TEXT="Should use distinct instances for CLI/strategy" ID="ID_898079161" CREATED="1320354712280" MODIFIED="1320354721379"/>
<node TEXT="Should reset each strategy tock" ID="ID_1943350563" CREATED="1320354694000" MODIFIED="1320354705835"/>
<node TEXT="Dependencies?" ID="ID_212899575" CREATED="1320359005059" MODIFIED="1320359008087"/>
</node>
<node TEXT="SIM:PAUSE semantics" ID="ID_1460449198" CREATED="1320252457159" MODIFIED="1320252486725">
<node TEXT="SIM:PAUSE assumes that it can only be called during strategy execution or between ticks." ID="ID_988304142" CREATED="1320252487167" MODIFIED="1320252502948"/>
<node TEXT="With any successful architecture, SIM:PAUSE can be called during a tick." ID="ID_345385709" CREATED="1320252503318" MODIFIED="1320252535663"/>
</node>
<node TEXT="Synchronize Econ data across threads" ID="ID_440769659" CREATED="1320250898352" MODIFIED="1320250907738">
<node TEXT="The Econ cellmodel is stored in memory, not in the RDB" ID="ID_1006155959" CREATED="1320250909277" MODIFIED="1320250921234"/>
<node TEXT="The econsheet(n) module needs a copy of the cell model" ID="ID_912073933" CREATED="1320250922765" MODIFIED="1320250939235"/>
</node>
<node TEXT="Synchronize parm data across threads" ID="ID_1566374703" CREATED="1320343440394" MODIFIED="1320343448494">
<node TEXT="Engine thread will need own parmdb, updated when App changes it." ID="ID_980718338" CREATED="1320343448938" MODIFIED="1320343485148"/>
</node>
<node TEXT="order scheduling" ID="ID_546509893" CREATED="1320334301630" MODIFIED="1320334308129">
<node TEXT="When the App thread schedules an order, it must actually be scheduled in the Engine thread." ID="ID_1744505028" CREATED="1320334308790" MODIFIED="1320334339776"/>
</node>
<node TEXT="Loading mods in the correct thread" FOLDED="true" ID="ID_1585782874" CREATED="1320168446883" MODIFIED="1320248453322">
<node TEXT="Current implementation of mods won&apos;t work" ID="ID_1465891396" CREATED="1320168468864" MODIFIED="1320168494290"/>
<node TEXT="Assumes that all code is loaded in the main thread." ID="ID_655021077" CREATED="1320168494625" MODIFIED="1320168503392"/>
<node TEXT="Knowing which thread to put mods into could be difficult." ID="ID_781751764" CREATED="1320168518423" MODIFIED="1320168586096"/>
</node>
<node TEXT="Intermittent Tcl error on application termination" ID="ID_453615533" CREATED="1320188124292" MODIFIED="1320249139895">
<node TEXT="&quot;called Tcl_FindHashEntry on deleted table&quot;" ID="ID_1994187647" CREATED="1320249035147" MODIFIED="1320249044601"/>
<node TEXT="Requires help from ActiveState; or possibly a move to Tcl 8.6" ID="ID_633969861" CREATED="1320259663451" MODIFIED="1320259674807"/>
<node TEXT="Probably not a show stopper" ID="ID_1267122017" CREATED="1320259654434" MODIFIED="1320259658505"/>
</node>
<node TEXT="Need condition order redesign code" ID="ID_1182294503" CREATED="1320418762136" MODIFIED="1320418768715"/>
</node>
<node TEXT="Solved" POSITION="right" ID="ID_66662576" CREATED="1320169352481" MODIFIED="1320169374852">
<icon BUILTIN="ksmiletris"/>
<node TEXT="Cross-thread notifier events" ID="ID_1406120307" CREATED="1320170258892" MODIFIED="1320248929564">
<node ID="ID_1413137248" CREATED="1320170295365" MODIFIED="1320248903699">
<richcontent TYPE="NODE">
<html>
  <head>
    
  </head>
  <body>
    <p>
      Sending thread subscribes to relevant notifier events (possibly using [notifier trace]) and calls [notifier send] in the receiving thread using [thread::send -async].
    </p>
  </body>
</html></richcontent>
</node>
</node>
<node TEXT="Thread-safe Logging" FOLDED="true" ID="ID_1810080186" CREATED="1320168890203" MODIFIED="1320248601428">
<node TEXT="Multiple threads need to write to the debugging log." ID="ID_621441757" CREATED="1320168932534" MODIFIED="1320248958253"/>
<node TEXT="Access needs to be synchronized" ID="ID_685798183" CREATED="1320168953032" MODIFIED="1320168961831"/>
<node TEXT="Thread doing the logging needs to be responsive at all times" ID="ID_1969681004" CREATED="1320248959915" MODIFIED="1320248973846"/>
<node TEXT="Solutions" FOLDED="true" ID="ID_1909166973" CREATED="1320170544782" MODIFIED="1320170546685">
<node TEXT="Save log to RDB" ID="ID_288416754" CREATED="1320170551154" MODIFIED="1320170635520">
<icon BUILTIN="button_cancel"/>
<node TEXT="RDB is thread-safe; multiple threads can write to it." ID="ID_1225488567" CREATED="1320170556700" MODIFIED="1320170571193"/>
<node TEXT="All logs included with scenario; means you can browse old logs if you need to." ID="ID_1963873232" CREATED="1320170571700" MODIFIED="1320170589141"/>
<node TEXT="But Model thread locks RDB for writing while it is working." ID="ID_101017557" CREATED="1320170595607" MODIFIED="1320170617728"/>
<node TEXT="App thread can&apos;t write to log while Model thread is working." ID="ID_397061140" CREATED="1320170618079" MODIFIED="1320170629358"/>
</node>
<node TEXT="One log per thread" ID="ID_1075663279" CREATED="1320170655722" MODIFIED="1320170691797">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="help"/>
<node TEXT="Each log creates its own logger" ID="ID_1190626628" CREATED="1320170667726" MODIFIED="1320170672999"/>
<node TEXT="Log browser either displays separate logs, or multiplexes them somehow" ID="ID_480487475" CREATED="1320170673334" MODIFIED="1320170686907"/>
</node>
<node TEXT="Logger thread" ID="ID_987304812" CREATED="1320170693927" MODIFIED="1320171889464">
<icon BUILTIN="help"/>
<node TEXT="Create a worker thread that manages the log file" ID="ID_1117301972" CREATED="1320170699847" MODIFIED="1320170706508"/>
<node TEXT="Use a &quot;log&quot; wrapper to send all log commands to the Logger thread for handling" ID="ID_1946247231" CREATED="1320170707701" MODIFIED="1320170722241"/>
<node TEXT="Use &quot;thread::send -async&quot;" ID="ID_1323133782" CREATED="1320170730860" MODIFIED="1320170762278">
<node TEXT="No need to block, no response is needed" ID="ID_313420464" CREATED="1320170763019" MODIFIED="1320170770211"/>
</node>
<node TEXT="Issues" ID="ID_1015878219" CREATED="1320170775195" MODIFIED="1320170781903">
<node TEXT="Logger needs to query the simclock" ID="ID_740225101" CREATED="1320170782364" MODIFIED="1320248765812"/>
<node TEXT="Logger needs to notify main thread when it opens a new file" ID="ID_1098692830" CREATED="1320170859896" MODIFIED="1320248762536"/>
<node TEXT="Model thread sends log message slightly after App thread has created a new scenario (and hence a new log directory)?" ID="ID_1174033291" CREATED="1320172098349" MODIFIED="1320172154575">
<icon BUILTIN="yes"/>
</node>
</node>
<node TEXT="Design" ID="ID_1144238444" CREATED="1320171895992" MODIFIED="1320171960171">
<icon BUILTIN="help"/>
<node TEXT="Half-Object + protocol" ID="ID_126833589" CREATED="1320171900602" MODIFIED="1320171915641"/>
<node TEXT="In other threads, instance of &quot;logger_thread&quot; object" ID="ID_80031962" CREATED="1320171915976" MODIFIED="1320171955132">
<node TEXT="Creates thread or connects to thread" ID="ID_1062263512" CREATED="1320171971707" MODIFIED="1320172000154"/>
<node TEXT="Threads other than App thread need to be told the ID of the logger thread" ID="ID_1305836638" CREATED="1320172001098" MODIFIED="1320172019054"/>
<node TEXT="Delegates all logger methods to logger thread using thread::send -async" ID="ID_1520162829" CREATED="1320172028484" MODIFIED="1320172052851"/>
</node>
</node>
</node>
</node>
</node>
</node>
<node TEXT="OBE" POSITION="right" ID="ID_1808375475" CREATED="1320258447480" MODIFIED="1320258468416">
<icon BUILTIN="smiley-neutral"/>
<node TEXT="orderdialog/order interface" FOLDED="true" ID="ID_1118432367" CREATED="1320248626818" MODIFIED="1320258458775">
<icon BUILTIN="full-2"/>
<node TEXT="Orders are defined and processed in Sim thread." ID="ID_1870639308" CREATED="1320248680328" MODIFIED="1320248708729"/>
<node TEXT="Order Dialogs appear in GUI thread." ID="ID_113121005" CREATED="1320248709658" MODIFIED="1320248719860"/>
<node TEXT="Order Dialogs require Order metadata" ID="ID_1137714015" CREATED="1320248720477" MODIFIED="1320248779050"/>
<node TEXT="Order Dialogs call [order send] and [order check] directly" ID="ID_1794211622" CREATED="1320248779744" MODIFIED="1320248795797"/>
</node>
<node TEXT="MAP:IMPORT order requires Tk" ID="ID_1317251256" CREATED="1320424623357" MODIFIED="1320424633711">
<icon BUILTIN="full-2"/>
</node>
</node>
<node TEXT="Implemented" POSITION="right" ID="ID_947468181" CREATED="1320169396045" MODIFIED="1320169404438">
<icon BUILTIN="button_ok"/>
<node TEXT="Thread-safe binary extensions" FOLDED="true" ID="ID_26884035" CREATED="1320168601236" MODIFIED="1320258565191">
<font NAME="SansSerif" SIZE="12"/>
<node ID="ID_727737407" CREATED="1320258531081" MODIFIED="1320258558904">
<richcontent TYPE="NODE">
<html>
  <head>
    
  </head>
  <body>
    <p>
      I <i>think</i>&#160;we're OK here.
    </p>
  </body>
</html></richcontent>
<icon BUILTIN="smiley-neutral"/>
</node>
<node TEXT="All binary extensions used in multiple threads must be thread-safe" ID="ID_1374216697" CREATED="1320168608545" MODIFIED="1320168633838"/>
<node TEXT="This includes Marsbin" ID="ID_1792411472" CREATED="1320168826351" MODIFIED="1320168831733"/>
<node TEXT="Marsbin includes third-party coordinate conversion libraries" ID="ID_1147781868" CREATED="1320168668533" MODIFIED="1320168841023"/>
<node TEXT="Not our area of expertise" ID="ID_1035367436" CREATED="1320168675124" MODIFIED="1320168680506"/>
</node>
<node TEXT="CIF" FOLDED="true" ID="ID_1332529643" CREATED="1320705437023" MODIFIED="1320705438490">
<node TEXT="Only the App thread needs to update the CIF" ID="ID_1201525763" CREATED="1320705439402" MODIFIED="1320705454925"/>
<node TEXT="However, the &quot;export&quot; executive command needs to look at it, and could be called from the Engine thread." ID="ID_1239115277" CREATED="1320705455478" MODIFIED="1320705474620"/>
<node TEXT="CIF keeps the pointer to the top of the undo/redo stacks in memory." ID="ID_1939837180" CREATED="1320705475985" MODIFIED="1320705497856"/>
<node TEXT="Synchronizing the mark between threads would be a nuisance." ID="ID_569866017" CREATED="1320705498254" MODIFIED="1320705510438"/>
<node TEXT="All Undo/Redo information is cleared when we save." ID="ID_370796238" CREATED="1320705539478" MODIFIED="1320705578899"/>
<node TEXT="Conclusion" ID="ID_309730628" CREATED="1320705579594" MODIFIED="1320705585023">
<node TEXT="The redo data should NOT be in the cif table." ID="ID_1452104461" CREATED="1320705585545" MODIFIED="1320705601879"/>
<node TEXT="If it were removed from the cif table, the [cif mark] routine would be unnecessary." ID="ID_1789641952" CREATED="1320705602713" MODIFIED="1320705620185"/>
<node TEXT="The cif module could live only in the App thread; it need not be shared." ID="ID_706204638" CREATED="1320705620864" MODIFIED="1320705636901">
<node TEXT="[export] can look at the cif table directly." ID="ID_752867683" CREATED="1320705637330" MODIFIED="1320705653141"/>
</node>
</node>
</node>
</node>
</node>
</map>
