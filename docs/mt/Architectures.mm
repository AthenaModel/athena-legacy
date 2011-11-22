<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node TEXT="Architectures" ID="ID_651567401" CREATED="1320247176546" MODIFIED="1320247181148">
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="Problem" POSITION="right" ID="ID_1595308380" CREATED="1320251557804" MODIFIED="1320251570045">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="help"/>
<node TEXT="How to keep the Athena GUI responsive while time is advancing" ID="ID_1358695480" CREATED="1320251531981" MODIFIED="1320251555971"/>
<node TEXT="Desires" FOLDED="true" ID="ID_818397684" CREATED="1320251586006" MODIFIED="1320251589683">
<node TEXT="Not a fruitful source of errors" ID="ID_447849110" CREATED="1320255747533" MODIFIED="1320255756362"/>
<node TEXT="Clean, maintainable architecture" ID="ID_179357935" CREATED="1320251590423" MODIFIED="1320251600276"/>
<node TEXT="Minimum of effort required to get there" ID="ID_1211812243" CREATED="1320251601183" MODIFIED="1320251670942"/>
<node TEXT="Potential to run everything in one thread when desired" ID="ID_1787463462" CREATED="1320251671377" MODIFIED="1320251695575"/>
</node>
</node>
<node TEXT="Conclusions" POSITION="right" ID="ID_1170974514" CREATED="1320257594089" MODIFIED="1320257596928">
<node TEXT="Use Architecture 1" ID="ID_1051691799" CREATED="1320257617279" MODIFIED="1320257624907">
<node TEXT="Few if any Mars changes" ID="ID_1663284158" CREATED="1320257639181" MODIFIED="1320257653861"/>
<node TEXT="Little data to be transported between App and Engine except via RDB" ID="ID_767532853" CREATED="1320257654493" MODIFIED="1320257686426"/>
<node TEXT="Synchronization is mostly a solved problem." ID="ID_1158761670" CREATED="1320257687042" MODIFIED="1320257694047"/>
<node TEXT="Does not limit user access to data" ID="ID_1938402016" CREATED="1320257725348" MODIFIED="1320257730294"/>
<node TEXT="No difficulty keeping the App&apos;s in-memory and RDB data in sync; both are updated on &lt;Tick&gt;." ID="ID_268864502" CREATED="1320257754092" MODIFIED="1320257781298"/>
</node>
</node>
<node TEXT="Options" POSITION="right" ID="ID_966799781" CREATED="1320257597373" MODIFIED="1320257598387">
<node TEXT="Architecture 1: App/Engine" FOLDED="true" ID="ID_417992169" CREATED="1320177937063" MODIFIED="1320257183319">
<icon BUILTIN="full-1"/>
<icon BUILTIN="button_ok"/>
<node TEXT="Concept" ID="ID_1254306284" CREATED="1320247318223" MODIFIED="1320247325461">
<icon BUILTIN="idea"/>
<node TEXT="The code that runs during a time tick, and all objects needed to support that, reside in the &quot;Engine&quot;." ID="ID_710497644" CREATED="1320247472772" MODIFIED="1320247498528"/>
<node TEXT="All other code, including the GUI, the scenario editing code, and so forth, reside in the &quot;App&quot;." ID="ID_142041543" CREATED="1320247500704" MODIFIED="1320247520423"/>
<node TEXT="The App is responsible for creating and invoking the Engine as needed." ID="ID_1102665200" CREATED="1320247520930" MODIFIED="1320247537794"/>
<node TEXT="The Engine can run in a separate thread if so desired, so that the App remains responsive." ID="ID_93645554" CREATED="1320247538269" MODIFIED="1320247563276"/>
</node>
<node TEXT="Threads" ID="ID_1541371939" CREATED="1320250709687" MODIFIED="1320250711324">
<node TEXT="App" ID="ID_1313825621" CREATED="1319477780804" MODIFIED="1320093174830">
<node TEXT="Initialize application" ID="ID_324927437" CREATED="1319477984814" MODIFIED="1319477990098"/>
<node TEXT="GUI" ID="ID_1412081750" CREATED="1319477990550" MODIFIED="1319477991490"/>
<node TEXT="Scenario Editing" ID="ID_537946306" CREATED="1319478145833" MODIFIED="1319478149820"/>
<node TEXT="Order Processing" ID="ID_1712202460" CREATED="1319478150769" MODIFIED="1319478156573"/>
<node TEXT="Opening/Saving Scenario Files" ID="ID_1007226157" CREATED="1319478164785" MODIFIED="1319478174404"/>
<node TEXT="Overall Simulation Control" ID="ID_1590873433" CREATED="1319478181128" MODIFIED="1319478199275"/>
</node>
<node TEXT="Engine" ID="ID_171084147" CREATED="1319477782564" MODIFIED="1320247231428">
<node TEXT="Engine Initialization" ID="ID_1824425447" CREATED="1320090638334" MODIFIED="1320247231428"/>
<node TEXT="Engine Time Step" ID="ID_1853172797" CREATED="1319478710568" MODIFIED="1320247231428"/>
<node TEXT="DAM Rules" ID="ID_1557302822" CREATED="1319478705712" MODIFIED="1319478707876"/>
</node>
<node TEXT="Logger" ID="ID_1787542420" CREATED="1320169520424" MODIFIED="1320250722332">
<icon BUILTIN="help"/>
<node TEXT="Writes to the debugging log" ID="ID_57404185" CREATED="1320169523864" MODIFIED="1320169528872"/>
<node TEXT="Managed by logmanager object" ID="ID_1689505893" CREATED="1320169529192" MODIFIED="1320169542779"/>
<node TEXT="logmanager" FOLDED="true" ID="ID_66406732" CREATED="1320169544300" MODIFIED="1320169551040">
<node TEXT="Creates and initializes logger thread" ID="ID_1304746998" CREATED="1320169551515" MODIFIED="1320169563434"/>
<node ID="ID_1883057929" CREATED="1320169563816" MODIFIED="1320169676550">
<richcontent TYPE="NODE">
<html>
  <head>
    
  </head>
  <body>
    <p>
      Defines &quot;log&quot; command, which calls
    </p>
    <p>
      
    </p>
    <p>
      &#160;&#160; <font face="Courier New">&#160;thread::send $logthread [list log {*}$args]</font>
    </p>
  </body>
</html></richcontent>
</node>
<node TEXT="Releases thread on application exit" ID="ID_571386544" CREATED="1320169687689" MODIFIED="1320169806661"/>
</node>
</node>
</node>
<node TEXT="Advantages" ID="ID_483248630" CREATED="1320250726543" MODIFIED="1320250730725">
<node TEXT="Takes advantage of multiple cores" ID="ID_1285309273" CREATED="1320251885340" MODIFIED="1320251890954"/>
<node TEXT="Little new asynchroneity; state machine already mostly exists." ID="ID_391837837" CREATED="1320250736354" MODIFIED="1320250751189"/>
<node TEXT="Engine code is already somewhat segregated from the rest of Athena" ID="ID_1396495186" CREATED="1320250759752" MODIFIED="1320250771275"/>
<node TEXT="Order/Order Dialog code works as is" ID="ID_270271287" CREATED="1320250785991" MODIFIED="1320250797133">
<node TEXT="Orders can be defined in both threads." ID="ID_1699190724" CREATED="1320250798208" MODIFIED="1320250805949"/>
<node TEXT="Engine uses only uncif&apos;d orders" ID="ID_846007973" CREATED="1320250806424" MODIFIED="1320250822508"/>
</node>
<node TEXT="Most engine code doesn&apos;t use in-memory data that the App needs to know about" ID="ID_684969533" CREATED="1320250832359" MODIFIED="1320250882540"/>
<node TEXT="Almost all information is available to the App automatically." ID="ID_345041056" CREATED="1320256590578" MODIFIED="1320256620093"/>
<node TEXT="Only application code is involved in the split" ID="ID_1692402" CREATED="1320251218252" MODIFIED="1320251229116">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="help"/>
</node>
</node>
<node TEXT="Disadvantages" ID="ID_1261666422" CREATED="1320251163450" MODIFIED="1320251172079">
<node TEXT="Locking will need to be handled somewhat differently" ID="ID_389957601" CREATED="1320251186827" MODIFIED="1320251195765"/>
</node>
</node>
<node TEXT="Architecture 2: Sim/GUI" FOLDED="true" ID="ID_1820792865" CREATED="1320177964473" MODIFIED="1320257190511">
<icon BUILTIN="full-2"/>
<icon BUILTIN="button_cancel"/>
<node TEXT="Concept" ID="ID_1117544165" CREATED="1320247593962" MODIFIED="1320247613384">
<icon BUILTIN="idea"/>
<node TEXT="The application is split into two distinct applications, the Sim and the GUI." ID="ID_492941483" CREATED="1320247615810" MODIFIED="1320247679405"/>
<node TEXT="The Sim and the GUI are loaded into distinct threads." ID="ID_240653885" CREATED="1320247730198" MODIFIED="1320247740869"/>
<node TEXT="This is similar to the JNEM architecture, which has jnem_sim and jnem_console, but using threads" ID="ID_1800622463" CREATED="1320247679880" MODIFIED="1320247728771"/>
<node TEXT="The Sim contains everything needed to run Athena in batch mode (i.e., with no GUI)." ID="ID_677464734" CREATED="1320247636160" MODIFIED="1320247723210"/>
<node TEXT="The GUI contains only the GUI." ID="ID_251147295" CREATED="1320247759113" MODIFIED="1320247776960"/>
<node TEXT="The GUI communicates with the Sim via orders (and perhaps other requests) and notifier events, which convey game truth." ID="ID_979250905" CREATED="1320247778091" MODIFIED="1320247819587"/>
</node>
<node TEXT="Threads" FOLDED="true" ID="ID_806601577" CREATED="1320250962535" MODIFIED="1320250963947">
<node TEXT="Sim" ID="ID_1492977542" CREATED="1320178211778" MODIFIED="1320247872323">
<node TEXT="Package: app_sim(n)" ID="ID_1721286248" CREATED="1320178353599" MODIFIED="1320178358981"/>
<node TEXT="Main thread" ID="ID_1869941748" CREATED="1320178214890" MODIFIED="1320178218478"/>
<node TEXT="Contains only non-GUI code" ID="ID_1676254609" CREATED="1320178218767" MODIFIED="1320178226520"/>
<node TEXT="Responds to orders, and a few other requests (e.g., exit)" ID="ID_1138931821" CREATED="1320178227012" MODIFIED="1320178238634"/>
<node TEXT="First thread to start; creates GUI by default" ID="ID_1158827015" CREATED="1320178297165" MODIFIED="1320178307773"/>
<node TEXT="In -batch mode, no GUI is created; runs script to completion and halts." ID="ID_333363913" CREATED="1320178308577" MODIFIED="1320178339995"/>
</node>
<node TEXT="GUI" ID="ID_64365999" CREATED="1320178077917" MODIFIED="1320178088353">
<node TEXT="Package: app_sim_gui(n)" ID="ID_707205476" CREATED="1320178360814" MODIFIED="1320178373957"/>
<node TEXT="Contains all Tk code, and other code used only by the UI (e.g., appserver)" ID="ID_278761025" CREATED="1320178088985" MODIFIED="1320178104257"/>
<node TEXT="Sends orders (and possibly other requests) to the Sim thread." ID="ID_198852093" CREATED="1320178104951" MODIFIED="1320247848120"/>
<node TEXT="Receives notifier events from the Sim thread." ID="ID_1673456833" CREATED="1320178135829" MODIFIED="1320247853509"/>
<node TEXT="Performs no lengthy blocking tasks." ID="ID_85858907" CREATED="1320178277969" MODIFIED="1320178291230"/>
<node TEXT="Does not write to log" ID="ID_1525130838" CREATED="1320178390704" MODIFIED="1320178412762"/>
<node TEXT="Talks to Sim thread via facade objects that send requests to the Sim thread." ID="ID_1479971333" CREATED="1320178462456" MODIFIED="1320247868938"/>
</node>
</node>
<node TEXT="Advantages" ID="ID_450719674" CREATED="1320250959924" MODIFIED="1320250976868">
<node TEXT="Takes advantage of multiple cores" ID="ID_549489083" CREATED="1320251896980" MODIFIED="1320251902811"/>
<node TEXT="More like JNEM architecture" ID="ID_659662044" CREATED="1320250977423" MODIFIED="1320250992517"/>
<node TEXT="Natural division between GUI and non-GUI code" ID="ID_1414948730" CREATED="1320251005600" MODIFIED="1320251029341"/>
<node TEXT="Protocol mostly in place" ID="ID_131391899" CREATED="1320251041864" MODIFIED="1320251047550">
<node TEXT="GUI sends orders" ID="ID_1641249104" CREATED="1320251047936" MODIFIED="1320251050998"/>
<node TEXT="Sim sends notifier events" ID="ID_1892021767" CREATED="1320251051409" MODIFIED="1320251061126"/>
</node>
</node>
<node TEXT="Disadvantages" ID="ID_608414797" CREATED="1320251034673" MODIFIED="1320251067391">
<node TEXT="orders defined in Sim but orderdialogs are in GUI" ID="ID_823827660" CREATED="1320251068192" MODIFIED="1320251086221"/>
<node TEXT="GUI can no longer query Sim code directly, hence much more monitor data will be needed" ID="ID_1062745294" CREATED="1320251088416" MODIFIED="1320251119502"/>
</node>
</node>
<node TEXT="Use subprocesses vs. threads" FOLDED="true" ID="ID_1718710152" CREATED="1320257822365" MODIFIED="1320257835969">
<icon BUILTIN="button_cancel"/>
<node TEXT="Subprocesses avoid some issues, but add asynchroneity" ID="ID_1970784472" CREATED="1320257852723" MODIFIED="1320257877824"/>
<node TEXT="Unclear what protocol to use to talk to child process" ID="ID_1424566652" CREATED="1320257889157" MODIFIED="1320257904773"/>
<node TEXT="Architecturally, the problems are similar." ID="ID_1404430171" CREATED="1320257909336" MODIFIED="1320257937572"/>
<node TEXT="Start with threads; go to subprocesses if it seems necessary." ID="ID_388163454" CREATED="1320257938017" MODIFIED="1320257946737"/>
</node>
<node TEXT="Fine-grained Engine" FOLDED="true" ID="ID_350970773" CREATED="1320251784331" MODIFIED="1320257211696">
<icon BUILTIN="clanbomber"/>
<node TEXT="Concept" ID="ID_679168249" CREATED="1320251821260" MODIFIED="1320251829072">
<icon BUILTIN="idea"/>
<node TEXT="Break the Engine code into many small steps" ID="ID_1537995973" CREATED="1320251832810" MODIFIED="1320251933876"/>
<node TEXT="Run the steps as individual events in the event loop." ID="ID_505525774" CREATED="1320251832810" MODIFIED="1320251943331"/>
</node>
<node TEXT="Advantages" ID="ID_1067339978" CREATED="1320251947454" MODIFIED="1320251952092">
<node TEXT="No threading involved" ID="ID_1526421717" CREATED="1320251952431" MODIFIED="1320251957316"/>
</node>
<node TEXT="Disadvantages" ID="ID_1182014334" CREATED="1320251958959" MODIFIED="1320251963493">
<node TEXT="Can&apos;t make use of multiple cores" ID="ID_102146117" CREATED="1320251964080" MODIFIED="1320251971253"/>
<node TEXT="Engine uses minimal number of RDB queries; this would increase the number greatly." ID="ID_1496352362" CREATED="1320251972113" MODIFIED="1320252040812"/>
<node TEXT="GRAM is a significant factor; splitting it in this way would be a lot of work." ID="ID_394781901" CREATED="1320252042214" MODIFIED="1320252060540"/>
</node>
<node TEXT="Practically speaking, this is a non-starter." ID="ID_997731650" CREATED="1320257227928" MODIFIED="1320257235400"/>
</node>
<node TEXT="Sqlite progress callback" FOLDED="true" ID="ID_1900475539" CREATED="1320252065880" MODIFIED="1320257211696">
<icon BUILTIN="clanbomber"/>
<node TEXT="Concept" ID="ID_1362527724" CREATED="1320252080800" MODIFIED="1320252113688">
<icon BUILTIN="idea"/>
<node TEXT="Most engine time is spent in Sqlite3" ID="ID_1473933797" CREATED="1320252223809" MODIFIED="1320252234247"/>
<node TEXT="Sqlite3 progress callback can be called periodically during a query." ID="ID_1654784559" CREATED="1320252118344" MODIFIED="1320252149518"/>
<node TEXT="Before advancing time, define such a callback with a small increment" ID="ID_1356378858" CREATED="1320252149968" MODIFIED="1320252186318"/>
<node TEXT="Callback calls [update], allowing the GUI to be responsive" ID="ID_1787823591" CREATED="1320252175129" MODIFIED="1320252251191"/>
<node TEXT="After advancing time, remove the callback." ID="ID_439774019" CREATED="1320252268370" MODIFIED="1320252286279"/>
</node>
<node TEXT="Advantages" ID="ID_1768303341" CREATED="1320252254722" MODIFIED="1320252257039">
<node TEXT="No threading involved." ID="ID_1479069491" CREATED="1320252257370" MODIFIED="1320252260608"/>
<node TEXT="Minimal code required" ID="ID_222217265" CREATED="1320252261131" MODIFIED="1320252266183"/>
<node TEXT="No architecture changes required" ID="ID_989096884" CREATED="1320252303259" MODIFIED="1320252309744"/>
</node>
<node TEXT="Disadvantages" ID="ID_420743873" CREATED="1320252292570" MODIFIED="1320252295623">
<node TEXT="Doesn&apos;t make use of multiple cores" ID="ID_1242368069" CREATED="1320252296041" MODIFIED="1320252302312"/>
<node TEXT="&quot;Update considered harmful&quot;" ID="ID_1027895688" CREATED="1320252311707" MODIFIED="1320252320320"/>
<node TEXT="Nested SQLite queries--and not in a good way" ID="ID_759243958" CREATED="1320257244308" MODIFIED="1320257261265">
<node TEXT="For the GUI to be responsive, it needs to query the RDB for data." ID="ID_1993890917" CREATED="1320257266764" MODIFIED="1320257282021"/>
<node TEXT="Progress callbacks are executed at arbitrary points during a query." ID="ID_412487639" CREATED="1320257282996" MODIFIED="1320257326867"/>
<node TEXT="Querying the same database using the same handle in a progress callback sounds rather dangerous." ID="ID_1192227905" CREATED="1320257327437" MODIFIED="1320257344097"/>
</node>
</node>
</node>
</node>
</node>
</map>
