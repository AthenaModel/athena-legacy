<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1238011746256" ID="Freemind_Link_272188125" MODIFIED="1238100355417" TEXT="Bug 1963: Enable/disable order &#xa;controls automatically as order &#xa;state changes.">
<node CREATED="1238079118522" ID="Freemind_Link_1339261709" MODIFIED="1238084249782" POSITION="right" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238079128890" ID="Freemind_Link_1558685355" MODIFIED="1238079156692" TEXT="Define a state controller for each condition"/>
<node CREATED="1238079165370" ID="Freemind_Link_1298337336" MODIFIED="1238079173076" TEXT="Global conditions, like order validity">
<node CREATED="1238079209851" ID="Freemind_Link_1255406237" MODIFIED="1238079226610" TEXT="::cond::orderIsValid"/>
</node>
<node CREATED="1238079175690" ID="Freemind_Link_1646320213" MODIFIED="1238079190308" TEXT="Local conditions, like &quot;Delete Entity&quot; buttons">
<node CREATED="1238079228330" ID="Freemind_Link_499116166" MODIFIED="1238079233684" TEXT="Defined as components"/>
</node>
<node CREATED="1238079255770" ID="Freemind_Link_1688196888" MODIFIED="1238079268372" TEXT="Update all relevant menu items, buttons, etc. to be controlled by a statecontroller"/>
</node>
<node CREATED="1238079100554" ID="_" MODIFIED="1238084220534" POSITION="right" TEXT="New objects/procs">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078188172" ID="Freemind_Link_1764236787" MODIFIED="1238084220535" TEXT="statecontroller">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078193149" ID="Freemind_Link_1396177566" MODIFIED="1238084208638" TEXT="Snit object">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238078544251" ID="Freemind_Link_295307935" MODIFIED="1238084213206" TEXT="Behavior">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078197629" ID="Freemind_Link_405701648" MODIFIED="1238078366310" TEXT="Controls the -state of one or more other objects">
<node CREATED="1238078367323" ID="Freemind_Link_1127251702" MODIFIED="1238078370934" TEXT="Typically widgets"/>
<node CREATED="1238078371756" ID="Freemind_Link_1159522875" MODIFIED="1238078391878" TEXT="Menu items specified as menu/label pair"/>
<node CREATED="1238078410380" ID="Freemind_Link_1109676735" MODIFIED="1238078424182" TEXT="objdict: dictionary of object specific data"/>
</node>
<node CREATED="1238078235468" ID="Freemind_Link_226552369" MODIFIED="1238086769061" TEXT="Updates the state of controlled objects on update"/>
<node CREATED="1238082597395" ID="Freemind_Link_1424390995" MODIFIED="1238082608397" TEXT="If an object no longer exists, it is silently forgotten"/>
</node>
<node CREATED="1238078558556" ID="Freemind_Link_1851375145" MODIFIED="1238084220536" TEXT="Options">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078253197" ID="Freemind_Link_545056045" MODIFIED="1238095407871" TEXT="-condition">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078253197" ID="Freemind_Link_958028884" MODIFIED="1238078475139" TEXT="boolean expression evaluated &#xa;for each controlled object"/>
<node CREATED="1238078327853" ID="Freemind_Link_1198595796" MODIFIED="1238078343318" TEXT="Can reference objdict"/>
</node>
<node CREATED="1238095344314" ID="Freemind_Link_1216785602" MODIFIED="1238095407872" TEXT="-events">
<icon BUILTIN="button_ok"/>
<node CREATED="1238095350729" ID="Freemind_Link_1614300281" MODIFIED="1238095358483" TEXT="List of notifier subjects and event names"/>
<node CREATED="1238095358905" ID="Freemind_Link_802911938" MODIFIED="1238095372019" TEXT="Controller binds itself to all of them"/>
<node CREATED="1238095372666" ID="Freemind_Link_1221361426" MODIFIED="1238095399176" TEXT="Updates all controlled objects when any &#xa;of the listed events is sent"/>
</node>
</node>
<node CREATED="1238078569052" ID="Freemind_Link_268144220" MODIFIED="1238084220536" TEXT="Methods">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078577116" ID="Freemind_Link_439394552" MODIFIED="1238095411279" TEXT="&lt;html&gt;control &lt;i&gt;object&lt;/i&gt; ?&lt;i&gt;objdict&lt;/i&gt;?&lt;/html&gt;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078580491" ID="Freemind_Link_1755929682" MODIFIED="1238079343348" TEXT="Controller controls an object with its objdict"/>
</node>
<node CREATED="1238086775532" ID="Freemind_Link_1272335995" MODIFIED="1238095411280" TEXT="&lt;html&gt;update ?&lt;i&gt;objects&lt;/i&gt;?&lt;/html&gt;">
<icon BUILTIN="button_ok"/>
<node CREATED="1238086778139" ID="Freemind_Link_1644638168" MODIFIED="1238087590259" TEXT="Controller updates state of some or all controlled objects"/>
</node>
</node>
</node>
<node CREATED="1238078926938" ID="Freemind_Link_1800530885" MODIFIED="1238084220536" TEXT="menuitem $mnu $which $label opts">
<icon BUILTIN="button_ok"/>
<node CREATED="1238078965066" ID="Freemind_Link_1664248145" MODIFIED="1238079068084" TEXT="Like $menu add $which -label $label  ..., but returns &quot;$mnu $label&quot;"/>
<node CREATED="1238079279818" ID="Freemind_Link_456102677" MODIFIED="1238079310756" TEXT="Works with statecontroller control"/>
</node>
</node>
<node CREATED="1238084252048" ID="Freemind_Link_317379171" MODIFIED="1238084321242" POSITION="right" TEXT="Global Conditions">
<node CREATED="1238084257712" ID="Freemind_Link_1340428634" MODIFIED="1238084329134" TEXT="::cond::simNotRunning">
<icon BUILTIN="button_ok"/>
<node CREATED="1238084267104" ID="Freemind_Link_1993010398" MODIFIED="1238084273354" TEXT="Simulation state is not RUNNING"/>
<node CREATED="1238084312159" ID="Freemind_Link_1920844421" MODIFIED="1238084314282" TEXT="No objdict"/>
</node>
<node CREATED="1238084275056" ID="Freemind_Link_443775385" MODIFIED="1238084329135" TEXT="::cond::orderIsValid">
<icon BUILTIN="button_ok"/>
<node CREATED="1238084280080" ID="Freemind_Link_463364699" MODIFIED="1238084295162" TEXT="An order is currently valid"/>
<node CREATED="1238084295776" ID="Freemind_Link_986273241" MODIFIED="1238088115282" TEXT="objdict">
<node CREATED="1238088102681" ID="Freemind_Link_1175988225" MODIFIED="1238088108066" TEXT="order: the order name"/>
</node>
</node>
<node CREATED="1238088035769" ID="Freemind_Link_1737306358" MODIFIED="1238095420551" TEXT="::cond::orderIsValidSingle">
<icon BUILTIN="button_ok"/>
<node CREATED="1238088048457" ID="Freemind_Link_955070900" MODIFIED="1238088073586" TEXT="The order is valid, and 1 item is selected in browser"/>
<node CREATED="1238088118360" ID="Freemind_Link_265993463" MODIFIED="1238088120789" TEXT="objdict">
<node CREATED="1238088121272" ID="Freemind_Link_1178885228" MODIFIED="1238088124466" TEXT="order: the order name"/>
<node CREATED="1238088124984" ID="Freemind_Link_464861994" MODIFIED="1238088130114" TEXT="browser: the browser"/>
</node>
</node>
<node CREATED="1238088085752" ID="Freemind_Link_1657569090" MODIFIED="1238095423703" TEXT="::cond::orderIsValidMulti">
<icon BUILTIN="button_ok"/>
<node CREATED="1238088062521" ID="Freemind_Link_547294295" MODIFIED="1238088083586" TEXT="The order is valid, and multiple items are selected in browser"/>
<node CREATED="1238088118360" ID="Freemind_Link_682934822" MODIFIED="1238088120789" TEXT="objdict">
<node CREATED="1238088121272" ID="Freemind_Link_756039446" MODIFIED="1238088124466" TEXT="order: the order name"/>
<node CREATED="1238088124984" ID="Freemind_Link_729988018" MODIFIED="1238088130114" TEXT="browser: the browser"/>
</node>
</node>
</node>
<node CREATED="1238086818618" ID="Freemind_Link_37290438" MODIFIED="1238086830246" POSITION="right" TEXT="Widgets to be controlled">
<node CREATED="1238086830683" ID="Freemind_Link_904842437" MODIFIED="1238087287416" TEXT="appwin">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087233738" ID="Freemind_Link_1937730500" MODIFIED="1238087287417" TEXT="File/New Scenario">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087237899" ID="Freemind_Link_446019027" MODIFIED="1238087287419" TEXT="File/Open Scenario">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087242811" ID="Freemind_Link_567571080" MODIFIED="1238087287418" TEXT="File/Import Map">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087251402" ID="Freemind_Link_860909173" MODIFIED="1238087287418" TEXT="Order/items...">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087357817" ID="Freemind_Link_875599374" MODIFIED="1238096400296" TEXT="civgroupbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087362426" ID="Freemind_Link_628483469" MODIFIED="1238096400293" TEXT="GROUP:CIVILIAN:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087125386" ID="Freemind_Link_1736862547" MODIFIED="1238096400296" TEXT="GROUP:CIVILIAN:DELETE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087377321" ID="Freemind_Link_245136937" MODIFIED="1238096400295" TEXT="GROUP:CIVILIAN:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087381866" ID="Freemind_Link_1715777665" MODIFIED="1238096400294" TEXT="GROUP:CIVILIAN:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087407034" ID="Freemind_Link_562959786" MODIFIED="1238096565605" TEXT="coopbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087411434" ID="Freemind_Link_1421420205" MODIFIED="1238096565606" TEXT="COOPERATION:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087415162" ID="Freemind_Link_431049404" MODIFIED="1238096565607" TEXT="COOPERATION:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087438682" ID="Freemind_Link_1281971431" MODIFIED="1238096727152" TEXT="frcgroupbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087441513" ID="Freemind_Link_1896741286" MODIFIED="1238096727149" TEXT="GROUP:FORCE:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087134522" ID="Freemind_Link_447159499" MODIFIED="1238096727151" TEXT="GROUP:FORCE:DELETE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087676393" ID="Freemind_Link_1846769322" MODIFIED="1238096727150" TEXT="GROUP:FORCE:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087681305" ID="Freemind_Link_1696657928" MODIFIED="1238096727150" TEXT="GROUP:FORCE:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087013387" ID="Freemind_Link_1131356743" MODIFIED="1238097933130" TEXT="mapviewer">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087705273" ID="Freemind_Link_301013543" MODIFIED="1238087716871" TEXT="NBHOOD:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087211162" ID="Freemind_Link_982008495" MODIFIED="1238097893682" TEXT="NBHOOD:RAISE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087214042" ID="Freemind_Link_741051230" MODIFIED="1238097893683" TEXT="NBHOOD:LOWER">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087719273" ID="Freemind_Link_1043805933" MODIFIED="1238087787803" TEXT="UNIT:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087737033" ID="Freemind_Link_861247080" MODIFIED="1238097933131" TEXT="UNIT:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087104891" ID="Freemind_Link_1448572324" MODIFIED="1238096940244" TEXT="nbgroupbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087798778" ID="Freemind_Link_1236719645" MODIFIED="1238096940245" TEXT="GROUP:NBHOOD:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087140298" ID="Freemind_Link_1867530680" MODIFIED="1238096940247" TEXT="GROUP:NBHOOD:DELETE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087805497" ID="Freemind_Link_1828217620" MODIFIED="1238096940247" TEXT="GROUP:NBHOOD:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087813801" ID="Freemind_Link_71743470" MODIFIED="1238096940246" TEXT="GROUP:NBHOOD:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087154346" ID="Freemind_Link_244362738" MODIFIED="1238095442655" TEXT="nbhoodbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087160011" ID="Freemind_Link_392916991" MODIFIED="1238095442656" TEXT="NBHOOD:RAISE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087164443" ID="Freemind_Link_334509265" MODIFIED="1238095442659" TEXT="NBHOOD:LOWER">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087167082" ID="Freemind_Link_314705893" MODIFIED="1238095442658" TEXT="NBHOOD:DELETE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087834665" ID="Freemind_Link_630762796" MODIFIED="1238095442658" TEXT="NBHOOD:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087838904" ID="Freemind_Link_1927028121" MODIFIED="1238095442657" TEXT="NBHOOD:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087863337" ID="Freemind_Link_461132219" MODIFIED="1238097090468" TEXT="nbrelbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087868009" ID="Freemind_Link_152353650" MODIFIED="1238097090469" TEXT="NBHOOD:RELATIONSHIP:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087868009" ID="Freemind_Link_380280965" MODIFIED="1238097090470" TEXT="NBHOOD:RELATIONSHIP:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087180522" ID="Freemind_Link_867128880" MODIFIED="1238097232140" TEXT="orggroupbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087898872" ID="Freemind_Link_93744407" MODIFIED="1238097232141" TEXT="GROUP:ORGANIZATION:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087184794" ID="Freemind_Link_975466188" MODIFIED="1238097232143" TEXT="GROUP:ORGANIZATION:DELETE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087905865" ID="Freemind_Link_972425168" MODIFIED="1238097232142" TEXT="GROUP:ORGANIZATION:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087911832" ID="Freemind_Link_1511358131" MODIFIED="1238097232142" TEXT="GROUP:ORGANIZATION:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087863337" ID="Freemind_Link_73245389" MODIFIED="1238097351051" TEXT="relbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087868009" ID="Freemind_Link_1265878463" MODIFIED="1238097351053" TEXT="RELATIONSHIP:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087868009" ID="Freemind_Link_76657581" MODIFIED="1238097351053" TEXT="RELATIONSHIP:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087863337" ID="Freemind_Link_812650804" MODIFIED="1238097609331" TEXT="satbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238087868009" ID="Freemind_Link_1153355967" MODIFIED="1238097460276" TEXT="SATISFACTION:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087868009" ID="Freemind_Link_435054889" MODIFIED="1238097460277" TEXT="SATISFACTION:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238087198682" ID="Freemind_Link_476718828" MODIFIED="1238097601588" TEXT="unitbrowser">
<icon BUILTIN="button_ok"/>
<node CREATED="1238088005160" ID="Freemind_Link_1087759173" MODIFIED="1238097601589" TEXT="UNIT:CREATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238087202330" ID="Freemind_Link_1504049460" MODIFIED="1238097601591" TEXT="UNIT:DELETE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238088012552" ID="Freemind_Link_1303479297" MODIFIED="1238097601590" TEXT="UNIT:UPDATE">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238088017272" ID="Freemind_Link_1702224013" MODIFIED="1238097601590" TEXT="UNIT:UPDATE:MULTI">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
</map>
