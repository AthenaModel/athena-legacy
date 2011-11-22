<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node ID="ID_1986379951" CREATED="1319485181739" MODIFIED="1319485346440">
<richcontent TYPE="NODE">
<html>
  <head>
    
  </head>
  <body>
    <p style="text-align: center">
      Conclusions
    </p>
    <p style="text-align: center">
      And
    </p>
    <p style="text-align: center">
      Constraints
    </p>
  </body>
</html></richcontent>
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="Use Architecture 1: App/Engine" POSITION="right" ID="ID_546590926" CREATED="1320258575924" MODIFIED="1320258586407"/>
<node TEXT="Focus on multi-threaded implementation." POSITION="right" ID="ID_1138024862" CREATED="1320259551855" MODIFIED="1320259562526">
<node TEXT="Keep single-threaded variant in mind, so as not to rule it out" ID="ID_39997273" CREATED="1320259563625" MODIFIED="1320259577525"/>
<node TEXT="But don&apos;t try to implement both modes at the same time." ID="ID_1438697758" CREATED="1320259577783" MODIFIED="1320259597486"/>
</node>
<node TEXT="Orders" POSITION="right" ID="ID_1799368430" CREATED="1320258589582" MODIFIED="1320258592015">
<node TEXT="Some orders must be available in both threads" ID="ID_1746783572" CREATED="1319485187213" MODIFIED="1319485200672">
<node TEXT="E.g., ATTRIT:*" ID="ID_668128366" CREATED="1319485203612" MODIFIED="1319485212543"/>
</node>
<node TEXT="The App and Engine threads have different order interfaces" ID="ID_1937832630" CREATED="1320258604753" MODIFIED="1320258614144"/>
<node TEXT="The Engine thread can send uncif&apos;d orders in the RUNNING or TACTIC states" FOLDED="true" ID="ID_296556953" CREATED="1319485221491" MODIFIED="1320258626055">
<node TEXT="Executive tactics" ID="ID_1215512758" CREATED="1319485255018" MODIFIED="1319485257574"/>
<node TEXT="Scheduled orders" ID="ID_1638929240" CREATED="1319485257970" MODIFIED="1319485261533"/>
</node>
<node TEXT="The Engine thread cannot send cif&apos;d orders" ID="ID_1367636408" CREATED="1319485264274" MODIFIED="1320258644104"/>
</node>
<node TEXT="Thread package" POSITION="right" ID="ID_1297326169" CREATED="1320258649946" MODIFIED="1320258684321">
<node TEXT="thread::names&apos; return value includes the main thread" ID="ID_608483511" CREATED="1320169866472" MODIFIED="1320169901650"/>
<node TEXT="thread::send with no -async truly blocks; it doesn&apos;t enter the event loop recursively" ID="ID_268081574" CREATED="1320169906884" MODIFIED="1320169923576"/>
<node TEXT="Threads do not inherit the parent&apos;s auto_path" ID="ID_579950036" CREATED="1320181081242" MODIFIED="1320181096881"/>
<node TEXT="Threads get the Thread package automatically (but no others)" ID="ID_509089323" CREATED="1320258703572" MODIFIED="1320258713649"/>
</node>
<node TEXT="Thread comm" POSITION="right" ID="ID_1791547964" CREATED="1320258728727" MODIFIED="1320258734733">
<node TEXT="App uses thread::send -async for long running commands" ID="ID_498368843" CREATED="1320258735287" MODIFIED="1320258755114">
<node TEXT="E.g., time advance" ID="ID_383248760" CREATED="1320258756667" MODIFIED="1320258759662"/>
<node TEXT="[sim state] prevents unwanted user actions while Engine is running" ID="ID_1983205362" CREATED="1320258760013" MODIFIED="1320258794342"/>
</node>
<node TEXT="App uses [thread::send] synchronously for quick requests" ID="ID_65015985" CREATED="1320258800511" MODIFIED="1320258821977">
<node TEXT="Only when Engine is not running" ID="ID_829047533" CREATED="1320258828974" MODIFIED="1320258848747"/>
<node TEXT="E.g., invocation of DAM rule sets (if this is even possible from App)" ID="ID_1519866987" CREATED="1320258856383" MODIFIED="1320258890781"/>
</node>
</node>
<node TEXT="Package Architecture" POSITION="right" ID="ID_750649346" CREATED="1319485420084" MODIFIED="1320258936958">
<node TEXT="Each thread has a main package which handles thread initialization" ID="ID_772639220" CREATED="1320258942004" MODIFIED="1320334493624"/>
<node TEXT="A thread can only load one main package" ID="ID_231302804" CREATED="1320259298209" MODIFIED="1320334498660"/>
<node TEXT="A thread package should contain only the code necessary to set up and operate that particular thread." ID="ID_1305368589" CREATED="1320685374453" MODIFIED="1320685399334"/>
<node TEXT="Every thread should have an &quot;app&quot; object, which is responsible for initializing the thread and for providing general services." ID="ID_1964830449" CREATED="1320685496258" MODIFIED="1320685520406">
<node TEXT="This allows code to be loaded in multiple threads, and find the resources it needs." ID="ID_262544648" CREATED="1320685521031" MODIFIED="1320685539931"/>
</node>
<node TEXT="Other code should reside in functionality packages" ID="ID_183016863" CREATED="1320685399983" MODIFIED="1320685416246">
<node TEXT="app_sim_shared" ID="ID_1393137692" CREATED="1320685416697" MODIFIED="1320685421672">
<node TEXT="Non-UI models, scenario building, etc." ID="ID_1458428137" CREATED="1320685422489" MODIFIED="1320685435589"/>
</node>
<node TEXT="app_sim_ui" ID="ID_286497237" CREATED="1320685437037" MODIFIED="1320685439590">
<node TEXT="User-Interface-specific code" ID="ID_893023523" CREATED="1320685440001" MODIFIED="1320685447732"/>
</node>
</node>
<node TEXT="Packages" ID="ID_1059383844" CREATED="1320259061072" MODIFIED="1320259063927">
<node TEXT="app_sim(n)" ID="ID_1093717242" CREATED="1320259065526" MODIFIED="1320259067897">
<node TEXT="Main package for App thread (and the application as a whole)" ID="ID_1319993860" CREATED="1320259068451" MODIFIED="1320334513659"/>
<node TEXT="Resides in lib/app_sim/" ID="ID_1896315536" CREATED="1320259225957" MODIFIED="1320259269061"/>
<node TEXT="Loaded by athena(1) in main thread" ID="ID_809268682" CREATED="1320259081836" MODIFIED="1320259109503"/>
<node TEXT="Invoked by [app init]" ID="ID_287658688" CREATED="1320259109838" MODIFIED="1320259115610"/>
</node>
<node TEXT="app_sim_engine(n)" ID="ID_1780977289" CREATED="1320259154228" MODIFIED="1320259207643">
<node TEXT="Main package for Engine thread" ID="ID_758240454" CREATED="1320259157855" MODIFIED="1320334521659"/>
<node TEXT="Resides in lib/app_sim/engine/" ID="ID_1868001299" CREATED="1320259232439" MODIFIED="1320259266276"/>
<node TEXT="Loaded by App into Engine on creation" ID="ID_1240189848" CREATED="1320259163916" MODIFIED="1320259192090"/>
<node TEXT="Invoked by [app init]" ID="ID_1364566474" CREATED="1320259192565" MODIFIED="1320685469199"/>
</node>
<node TEXT="app_sim_logger(n)" ID="ID_1904319761" CREATED="1320259210194" MODIFIED="1320259219179">
<node TEXT="Main package for Logger thread" ID="ID_1560692864" CREATED="1320259242322" MODIFIED="1320334535850"/>
<node TEXT="Resides in lib/app_sim/logger/" ID="ID_1751842962" CREATED="1320259250613" MODIFIED="1320259263086"/>
<node TEXT="Loaded by App into Logger on creation" ID="ID_573635466" CREATED="1320259272563" MODIFIED="1320259286665"/>
<node TEXT="Invoked by [app init]" ID="ID_1283772702" CREATED="1320259287063" MODIFIED="1320685487722"/>
</node>
<node TEXT="app_sim_shared(n)" ID="ID_257070265" CREATED="1320259312569" MODIFIED="1320259316235">
<node TEXT="Main code package" ID="ID_1048919340" CREATED="1320259332381" MODIFIED="1320685629990"/>
<node TEXT="Resides in lib/app_sim/shared" ID="ID_42337794" CREATED="1320259343024" MODIFIED="1320259346784"/>
<node TEXT="Loaded by main packages as a dependency" ID="ID_1417326325" CREATED="1320259316820" MODIFIED="1320334555658"/>
<node TEXT="Initialized by [shared init]." ID="ID_1045023643" CREATED="1320259372704" MODIFIED="1320685572791">
<node TEXT="shared init mostly just verifies that required infrastructure is present, e.g., ::log, ::rdb." ID="ID_1681333840" CREATED="1320685573247" MODIFIED="1320685599232"/>
</node>
<node TEXT="If necessary/convenient, can be split into multiple packages" ID="ID_763563522" CREATED="1320259385098" MODIFIED="1320259397328"/>
<node TEXT="If code can go in projectlib(n) without exposing application internals, it should" ID="ID_54846112" CREATED="1320267001851" MODIFIED="1320267039331">
<icon BUILTIN="yes"/>
</node>
</node>
<node TEXT="app_sim_ui(n)" ID="ID_800605968" CREATED="1320685604723" MODIFIED="1321053636024">
<node TEXT="User Interface Package" ID="ID_1682728259" CREATED="1320685614757" MODIFIED="1320685635199"/>
<node TEXT="Resides in lib/app_sim/ui" ID="ID_1692013278" CREATED="1320685635754" MODIFIED="1320685641127"/>
<node TEXT="Loaded by app_sim as a dependency." ID="ID_1747348794" CREATED="1320685642615" MODIFIED="1320685650051"/>
<node TEXT="This code could remain in app_sim, but since we&apos;re modularizing anyway...." ID="ID_932669464" CREATED="1320685652338" MODIFIED="1320685683218"/>
</node>
</node>
</node>
</node>
</map>
