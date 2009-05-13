<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1241213122622" ID="Freemind_Link_1686775927" MODIFIED="1241213157958" TEXT="&lt;html&gt;&lt;center&gt;Environmental&lt;br&gt;&#xa;Situations&lt;/center&gt;">
<node CREATED="1241214858627" ID="Freemind_Link_1749967338" MODIFIED="1241805984321" POSITION="right" TEXT="&quot;pending&quot; envsits">
<icon BUILTIN="button_ok"/>
<node CREATED="1241214867699" ID="Freemind_Link_1112186275" MODIFIED="1241214875628" TEXT="Should &quot;pending&quot; be a situation state?">
<node CREATED="1241797822719" ID="Freemind_Link_1582444302" MODIFIED="1241797828264" TEXT="Yes, but what to call it?"/>
<node CREATED="1241798545242" ID="Freemind_Link_1624504815" MODIFIED="1241798628146" TEXT="INITIAL"/>
</node>
<node CREATED="1241214877059" ID="Freemind_Link_1043798464" MODIFIED="1242239320597" TEXT="General infrastructure for entities are editable or &#xa;not based on their own state rather than the sim state">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1241806376128" ID="Freemind_Link_1791139188" MODIFIED="1242056393702" POSITION="right" TEXT="GUI">
<node CREATED="1241806380560" ID="Freemind_Link_641049560" MODIFIED="1241806858902" TEXT="Interactions">
<icon BUILTIN="button_ok"/>
<node CREATED="1241213233752" ID="Freemind_Link_1295280977" MODIFIED="1241214333338" TEXT="Allow editing a situation by right-clicking on it.">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213247847" ID="Freemind_Link_51362897" MODIFIED="1241214327803" TEXT="Allow creating a situation by right-clicking on neighborhood">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213261687" ID="Freemind_Link_288381587" MODIFIED="1241214327802" TEXT="Allow creating a unit by right-clicking on neighborhood">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241806398655" ID="Freemind_Link_1552550497" MODIFIED="1241806858901" TEXT="Envsit Browser">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806403487" ID="Freemind_Link_103837556" MODIFIED="1241806771645" TEXT="Allow display of All, Live, or Ended envsits">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056427383" ID="Freemind_Link_22891150" MODIFIED="1242056459572" TEXT="Create button">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056435094" ID="Freemind_Link_1712944561" MODIFIED="1242056459573" TEXT="Edit button">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056438822" ID="Freemind_Link_220278718" MODIFIED="1242059151377" TEXT="Resolve button">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242056443926" ID="Freemind_Link_1802858313" MODIFIED="1242056459574" TEXT="Delete button">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241213617573" ID="_" MODIFIED="1241806764149" TEXT="Mapviewer should display live envsits only.">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806719729" ID="Freemind_Link_1947838192" MODIFIED="1241806764150" TEXT="Colors">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806442111" ID="Freemind_Link_29521002" MODIFIED="1241806473063" TEXT="INITIAL state: red on white"/>
<node CREATED="1242237172626" ID="Freemind_Link_753359251" MODIFIED="1242237182130" TEXT="ENDED state: green on white"/>
<node CREATED="1241806454784" ID="Freemind_Link_357525230" MODIFIED="1241806465383" TEXT="Others: red on yellow"/>
</node>
</node>
</node>
<node CREATED="1241806800271" ID="Freemind_Link_1087315745" MODIFIED="1242163479816" POSITION="right" TEXT="Orders">
<icon BUILTIN="button_ok"/>
<node CREATED="1241213192663" ID="Freemind_Link_339564971" MODIFIED="1241816376760" TEXT="Fix S:E:UPDATE dialog constraints">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213169736" ID="Freemind_Link_89786008" MODIFIED="1241816376760" TEXT="Fix g data entry in all orders, dialogs">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241213225078" ID="Freemind_Link_289214706" MODIFIED="1242057678171" TEXT="Add S:E:RESOLVE order">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241806779215" ID="Freemind_Link_1026149228" MODIFIED="1242163479817" POSITION="right" TEXT="scenario">
<icon BUILTIN="button_ok"/>
<node CREATED="1241214763395" ID="Freemind_Link_139901386" MODIFIED="1242163472384" TEXT="mutate reconcile">
<icon BUILTIN="button_ok"/>
<node CREATED="1241214703075" ID="Freemind_Link_1632242702" MODIFIED="1242163439452" TEXT="Creating or modifying a neighborhood must fix up envsit &quot;n&quot; field"/>
<node CREATED="1241214746547" ID="Freemind_Link_1655030319" MODIFIED="1242057701214" TEXT="Deleting a group must fix up envsit g and resolver fields"/>
</node>
<node CREATED="1242163442722" ID="Freemind_Link_872768653" MODIFIED="1242163472385" TEXT="Sanity Check">
<icon BUILTIN="button_ok"/>
<node CREATED="1242163447586" ID="Freemind_Link_534316694" MODIFIED="1242163459308" TEXT="Every envsit must be in a neighborhood"/>
<node CREATED="1242163459682" ID="Freemind_Link_609590258" MODIFIED="1242163468348" TEXT="No more than one envsit of a type in a neighborhood"/>
</node>
</node>
<node CREATED="1241214774083" ID="Freemind_Link_664817675" MODIFIED="1242237203184" POSITION="right" TEXT="Test suite">
<icon BUILTIN="button_ok"/>
<node CREATED="1241798163883" ID="Freemind_Link_200208835" MODIFIED="1242163495402" TEXT="Write 010-envsit.test">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1242163506979" ID="Freemind_Link_1748453134" MODIFIED="1242164766509" TEXT="Update 010-sim.test (sanity check)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1241798174027" ID="Freemind_Link_1793404936" MODIFIED="1242237200136" TEXT="Write 020-SITUATION-ENVIRONMENTAL.test">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241214801330" ID="Freemind_Link_1737846328" MODIFIED="1242238225550" POSITION="right" TEXT="Update orders(sim) man page">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806832142" ID="Freemind_Link_303434512" MODIFIED="1242238225552" TEXT="S:E:* orders">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241806819695" ID="Freemind_Link_1120882551" MODIFIED="1242238225551" POSITION="right" TEXT="Update order(sim) man page">
<icon BUILTIN="button_ok"/>
<node CREATED="1241806826000" ID="Freemind_Link_1470105764" MODIFIED="1242238225552" TEXT="prepare -oldnum">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1241214808690" ID="Freemind_Link_1271819979" MODIFIED="1242239295629" POSITION="right" TEXT="Write envsit(sim) man page">
<icon BUILTIN="button_ok"/>
</node>
</node>
</map>
