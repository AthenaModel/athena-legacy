<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1242252143767" ID="Freemind_Link_564723163" MODIFIED="1242252152227" TEXT="Generic Report Browser">
<node CREATED="1242252154009" ID="_" MODIFIED="1242252156371" POSITION="left" TEXT="Components">
<node CREATED="1242252156744" ID="Freemind_Link_1909454119" MODIFIED="1242252168595" TEXT="reportviewer(n)">
<node CREATED="1242252180665" ID="Freemind_Link_1100913683" MODIFIED="1242252189331" TEXT="Displays one report"/>
<node CREATED="1242252231240" ID="Freemind_Link_624280492" MODIFIED="1242252237490" TEXT="Allows report to be marked/unmarked"/>
</node>
<node CREATED="1242252169497" ID="Freemind_Link_1093163714" MODIFIED="1242252176195" TEXT="reportbrowser(n)">
<node CREATED="1242252277704" ID="Freemind_Link_33730278" MODIFIED="1242252296786" TEXT="Report bin tree"/>
<node CREATED="1242252297144" ID="Freemind_Link_743330433" MODIFIED="1242252303186" TEXT="List of report titles"/>
<node CREATED="1242252303737" ID="Freemind_Link_525533696" MODIFIED="1242252310674" TEXT="reportviewer(n)"/>
</node>
</node>
<node CREATED="1242252352265" ID="Freemind_Link_744434834" MODIFIED="1242315799299" POSITION="right" TEXT="Report Attributes">
<node CREATED="1242316095096" ID="Freemind_Link_1205559417" MODIFIED="1242316105538" TEXT="Attributes are defined in the &quot;reports&quot; table"/>
<node CREATED="1242253794405" ID="Freemind_Link_1334350872" MODIFIED="1242253796607" TEXT="Retain">
<node CREATED="1242252390632" ID="Freemind_Link_68081537" MODIFIED="1242252604134" TEXT="id">
<icon BUILTIN="ksmiletris"/>
<node CREATED="1242252593448" ID="Freemind_Link_511822734" MODIFIED="1242252596161" TEXT="Report ID"/>
<node CREATED="1242252596584" ID="Freemind_Link_584535658" MODIFIED="1242252602033" TEXT="INTEGER PRIMARY KEY"/>
</node>
<node CREATED="1242252458216" ID="Freemind_Link_1263018313" MODIFIED="1242252680565" TEXT="time">
<icon BUILTIN="ksmiletris"/>
<node CREATED="1242252662568" ID="Freemind_Link_294009706" MODIFIED="1242252675681" TEXT="Report time in ticks"/>
<node CREATED="1242315718090" ID="Freemind_Link_287189712" MODIFIED="1242315723635" TEXT="Used for sorting"/>
</node>
<node CREATED="1242252460280" ID="Freemind_Link_984538909" MODIFIED="1242325296781" TEXT="zulu">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1242252685687" ID="Freemind_Link_567930502" MODIFIED="1242325284977" TEXT="Report time stamp"/>
<node CREATED="1242325286232" ID="Freemind_Link_866494531" MODIFIED="1242325294684" TEXT="Rename &quot;stamp&quot;."/>
<node CREATED="1242315724729" ID="Freemind_Link_623820447" MODIFIED="1242315727507" TEXT="Used for display"/>
<node CREATED="1242252692696" ID="Freemind_Link_1950963867" MODIFIED="1242252845807" TEXT="Comment says it should be obsolete, but the&#xa;comment is mistaken: the startdate can change&#xa;in midstream."/>
</node>
<node CREATED="1242252453256" ID="Freemind_Link_1134412881" MODIFIED="1242315751327" TEXT="type">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1242252606760" ID="Freemind_Link_555977687" MODIFIED="1242252616097" TEXT="Report type, for binning"/>
<node CREATED="1242315755753" ID="Freemind_Link_676756756" MODIFIED="1242315768739" TEXT="Rename &quot;rtype&quot; (report type)"/>
</node>
<node CREATED="1242252455720" ID="Freemind_Link_649293179" MODIFIED="1242315778247" TEXT="subtype">
<icon BUILTIN="ksmiletris"/>
<node CREATED="1242252629064" ID="Freemind_Link_253094465" MODIFIED="1242252634609" TEXT="Report subtype, for binning"/>
</node>
<node CREATED="1242252465288" ID="Freemind_Link_243325968" MODIFIED="1242252865997" TEXT="title">
<icon BUILTIN="ksmiletris"/>
<node CREATED="1242252858742" ID="Freemind_Link_1181487095" MODIFIED="1242252863520" TEXT="Report title"/>
</node>
<node CREATED="1242252526488" ID="Freemind_Link_1970827740" MODIFIED="1242253416012" TEXT="text">
<icon BUILTIN="ksmiletris"/>
<node CREATED="1242253416998" ID="Freemind_Link_725408000" MODIFIED="1242253420528" TEXT="Text of the report"/>
</node>
</node>
<node CREATED="1242315833529" ID="Freemind_Link_1884881443" MODIFIED="1242315837156" TEXT="New">
<node CREATED="1242315837561" ID="Freemind_Link_1803871297" MODIFIED="1242315841589" TEXT="requested">
<node CREATED="1242315843273" ID="Freemind_Link_315095123" MODIFIED="1242315849571" TEXT="Flags reports requested by the user"/>
<node CREATED="1242315849944" ID="Freemind_Link_257630179" MODIFIED="1242315855811" TEXT="Vs. reports generated automatically"/>
<node CREATED="1242315931976" ID="Freemind_Link_105478848" MODIFIED="1242315938770" TEXT="Replaces &quot;mark&quot; for requested reports"/>
</node>
<node CREATED="1242315857160" ID="Freemind_Link_1193502599" MODIFIED="1242400097892" TEXT="hotlist">
<node CREATED="1242315861401" ID="Freemind_Link_1231481828" MODIFIED="1242315909043" TEXT="Flags reports on the hot list"/>
<node CREATED="1242315914841" ID="Freemind_Link_1026904384" MODIFIED="1242315930081" TEXT="Replaces &quot;mark&quot;."/>
<node CREATED="1242315957961" ID="Freemind_Link_1941158681" MODIFIED="1242315966290" TEXT="Should &quot;hot&quot; be set by an order?">
<node CREATED="1242315971176" ID="Freemind_Link_1034536769" MODIFIED="1242315977826" TEXT="No; it doesn&apos;t affect the simulation."/>
</node>
</node>
<node CREATED="1242315987305" ID="Freemind_Link_1874933352" MODIFIED="1242316031474" TEXT="meta1, meta2, meta3, meta4">
<node CREATED="1242315990697" ID="Freemind_Link_1748051573" MODIFIED="1242316017860" TEXT="Application defined"/>
<node CREATED="1242316036809" ID="Freemind_Link_1460876479" MODIFIED="1242316047906" TEXT="May be rtype/subtype dependent"/>
<node CREATED="1242316048328" ID="Freemind_Link_78627077" MODIFIED="1242316065313" TEXT="May be used by bin views"/>
</node>
</node>
<node CREATED="1242253797093" FOLDED="true" ID="Freemind_Link_587026395" MODIFIED="1242316082041" TEXT="Replace">
<node CREATED="1242252522744" ID="Freemind_Link_458313355" MODIFIED="1242253464748" TEXT="mark">
<icon BUILTIN="messagebox_warning"/>
<node CREATED="1242253145638" ID="Freemind_Link_1667958684" MODIFIED="1242253163776" TEXT="Flags reports for special attention"/>
<node CREATED="1242253194646" ID="Freemind_Link_1658525944" MODIFIED="1242253201584" TEXT="User can mark/unmark any report"/>
<node CREATED="1242253164182" ID="Freemind_Link_1936932523" MODIFIED="1242253174656" TEXT="User-requested reports are marked automatically"/>
<node CREATED="1242253174950" ID="Freemind_Link_1588419027" MODIFIED="1242253185536" TEXT="Browser shows marked reports in the Marked bin"/>
<node CREATED="1242253235943" ID="Freemind_Link_1706687681" MODIFIED="1242253241425" TEXT="Thoughts">
<node CREATED="1242253242326" ID="Freemind_Link_751826576" MODIFIED="1242253246976" TEXT="Probably worth keeping"/>
<node CREATED="1242253247238" ID="Freemind_Link_326496405" MODIFIED="1242253287792" TEXT="User-requested reports should be flagged separately"/>
<node CREATED="1242253291462" ID="Freemind_Link_75030860" MODIFIED="1242253412176" TEXT="Two bins">
<node CREATED="1242253310662" ID="Freemind_Link_1711766539" MODIFIED="1242253312880" TEXT="Requested"/>
<node CREATED="1242253313286" ID="Freemind_Link_266066959" MODIFIED="1242253314192" TEXT="Marked">
<node CREATED="1242253320246" ID="Freemind_Link_1846422300" MODIFIED="1242253331104" TEXT="&quot;Shelf&quot;?"/>
<node CREATED="1242253335254" ID="Freemind_Link_712571865" MODIFIED="1242253338560" TEXT="&quot;Saved&quot;?"/>
<node CREATED="1242253362918" ID="Freemind_Link_1319330769" MODIFIED="1242253395808" TEXT="&quot;Copy Stand&quot;?"/>
</node>
</node>
</node>
<node CREATED="1242315944904" ID="Freemind_Link_615488758" MODIFIED="1242315954930" TEXT="Replaced by &quot;requested&quot; and &quot;hot&quot;"/>
</node>
</node>
<node CREATED="1242253802901" FOLDED="true" ID="Freemind_Link_1972437819" MODIFIED="1242253804927" TEXT="Omit">
<node CREATED="1242252469287" ID="Freemind_Link_24422432" MODIFIED="1242252872021" TEXT="nbhood">
<icon BUILTIN="button_cancel"/>
<node CREATED="1242252878696" ID="Freemind_Link_1794439659" MODIFIED="1242252899937" TEXT="Report&apos;s neighborhood"/>
<node CREATED="1242252900679" ID="Freemind_Link_1709654594" MODIFIED="1242252930737" TEXT="Not generic."/>
<node CREATED="1242252932054" ID="Freemind_Link_484098420" MODIFIED="1242252939537" TEXT="Not currently used by browser"/>
</node>
<node CREATED="1242253003542" ID="Freemind_Link_999632794" MODIFIED="1242253041021" TEXT="pgroup">
<icon BUILTIN="button_cancel"/>
<node CREATED="1242253008759" ID="Freemind_Link_79480269" MODIFIED="1242253012624" TEXT="Report&apos;s pgroup"/>
<node CREATED="1242253013286" ID="Freemind_Link_244691678" MODIFIED="1242253020200" TEXT="See &quot;nbhood&quot;"/>
</node>
<node CREATED="1242252516536" ID="Freemind_Link_1106314101" MODIFIED="1242253041020" TEXT="fed_id">
<icon BUILTIN="button_cancel"/>
<node CREATED="1242253020806" ID="Freemind_Link_1911723128" MODIFIED="1242253024528" TEXT="Report&apos;s fed_id"/>
<node CREATED="1242253024998" ID="Freemind_Link_343035707" MODIFIED="1242253030264" TEXT="See &quot;nbhood&quot;"/>
</node>
<node CREATED="1242252521192" ID="Freemind_Link_1949311599" MODIFIED="1242253136060" TEXT="tag">
<icon BUILTIN="button_cancel"/>
<node CREATED="1242253045431" ID="Freemind_Link_72734912" MODIFIED="1242253052336" TEXT="Positive, Negative, or Neutral"/>
<node CREATED="1242253053047" ID="Freemind_Link_1454617066" MODIFIED="1242253064400" TEXT="Originally used to tag INPUT reports"/>
<node CREATED="1242253128838" ID="Freemind_Link_13867313" MODIFIED="1242253134472" TEXT="No longer used."/>
</node>
</node>
</node>
<node CREATED="1242316113992" ID="Freemind_Link_1577911905" MODIFIED="1242316116644" POSITION="right" TEXT="reporter(n)">
<node CREATED="1242316117705" ID="Freemind_Link_1581470341" MODIFIED="1242316132178" TEXT="New projectlib(n) module">
<node CREATED="1242316132808" ID="Freemind_Link_1019058169" MODIFIED="1242316136914" TEXT="Can move to marsutil(n) later"/>
</node>
<node CREATED="1242316138104" ID="Freemind_Link_439105233" MODIFIED="1242316378018" TEXT="reporter">
<node CREATED="1242416746744" ID="Freemind_Link_588835096" MODIFIED="1242416748917" TEXT="configure">
<node CREATED="1242416749287" ID="Freemind_Link_1668832763" MODIFIED="1242416910369" TEXT="Set options values"/>
<node CREATED="1242416911880" ID="Freemind_Link_457084575" MODIFIED="1242416913188" TEXT="options">
<node CREATED="1242416913639" ID="Freemind_Link_476532621" MODIFIED="1242416915573" TEXT="-db">
<node CREATED="1242416916584" ID="Freemind_Link_1059540698" MODIFIED="1242416922689" TEXT="sqldocument(n)"/>
</node>
<node CREATED="1242416923687" ID="Freemind_Link_151335669" MODIFIED="1242416926469" TEXT="-clock">
<node CREATED="1242416926855" ID="Freemind_Link_1867860858" MODIFIED="1242416932401" TEXT="simclock(n)"/>
</node>
<node CREATED="1242416933351" ID="Freemind_Link_1135189718" MODIFIED="1242416940773" TEXT="-reportcmd">
<node CREATED="1242416941208" ID="Freemind_Link_1448759874" MODIFIED="1242416946161" TEXT="Callback, called when report is saved"/>
<node CREATED="1242417058422" ID="Freemind_Link_693306392" MODIFIED="1242417067297" TEXT="Argument: dictionary of report options"/>
</node>
</node>
</node>
<node CREATED="1242416754456" ID="Freemind_Link_374818471" MODIFIED="1242416755365" TEXT="cget">
<node CREATED="1242416755817" ID="Freemind_Link_840599966" MODIFIED="1242416781506" TEXT="Get option values"/>
</node>
<node CREATED="1242316163096" ID="Freemind_Link_1247462120" MODIFIED="1242416796510" TEXT="save">
<node CREATED="1242316751832" ID="Freemind_Link_54599861" MODIFIED="1242316759009" TEXT="Adds a report; similar to code in JNEM"/>
</node>
<node CREATED="1242316166440" ID="Freemind_Link_1484596958" MODIFIED="1242316386178" TEXT="bin">
<node CREATED="1242416807448" ID="Freemind_Link_1737311727" MODIFIED="1242416817038" TEXT="clear" VSHIFT="10">
<node CREATED="1242416809272" ID="Freemind_Link_465350421" MODIFIED="1242416812501" TEXT="Deletes all bins"/>
</node>
<node CREATED="1242316236040" ID="Freemind_Link_720847480" MODIFIED="1242416820142" TEXT="define" VSHIFT="-2">
<node CREATED="1242316588856" ID="Freemind_Link_1089518598" MODIFIED="1242316595617" TEXT="Defines a new bin, including its base view"/>
</node>
<node CREATED="1242316251352" ID="Freemind_Link_249551640" MODIFIED="1242416865157" TEXT="children">
<node CREATED="1242316604792" ID="Freemind_Link_716511697" MODIFIED="1242416875393" TEXT="Returns the child bins of a given bin"/>
</node>
<node CREATED="1242316579143" ID="Freemind_Link_996452852" MODIFIED="1242316580243" TEXT="view">
<node CREATED="1242316625975" ID="Freemind_Link_1663727020" MODIFIED="1242416896418" TEXT="Gets the view associated with a particular bin"/>
</node>
<node CREATED="1242416961095" ID="Freemind_Link_1294597068" MODIFIED="1242417136108" TEXT="getall">
<node CREATED="1242416968999" ID="Freemind_Link_695741369" MODIFIED="1242416981473" TEXT="Gets a value representing all bin definitions"/>
</node>
<node CREATED="1242416984391" ID="Freemind_Link_665991822" MODIFIED="1242417139573" TEXT="setall">
<node CREATED="1242416986439" ID="Freemind_Link_681178646" MODIFIED="1242417000513" TEXT="Sets all bin definitions given a getbins value"/>
</node>
</node>
<node CREATED="1242316771544" ID="Freemind_Link_907430575" MODIFIED="1242316790693" TEXT="recent">
<node CREATED="1242316791047" ID="Freemind_Link_1536981039" MODIFIED="1242316814241" TEXT="Sets flag, include recent reports only, or all reports in bin"/>
</node>
</node>
<node CREATED="1242316818151" ID="Freemind_Link_426112660" MODIFIED="1242316823347" TEXT="Use by reportbrowser(n)">
<node CREATED="1242316823848" ID="Freemind_Link_503705263" MODIFIED="1242316841665" TEXT="Gets bin tree from reporter(n)"/>
<node CREATED="1242316850199" ID="Freemind_Link_1589585006" MODIFIED="1242316867793" TEXT="Asks for the name of the view corresponding to current bin"/>
<node CREATED="1242316869111" ID="Freemind_Link_1957492678" MODIFIED="1242316875857" TEXT="Uses view to retrieve reports"/>
<node CREATED="1242316896215" ID="Freemind_Link_1541852439" MODIFIED="1242417038442" TEXT="If bin changes, must get new view"/>
</node>
<node CREATED="1242316949271" ID="Freemind_Link_192174733" MODIFIED="1242316952227" TEXT="Client/Server">
<node CREATED="1242317007879" ID="Freemind_Link_1218210138" MODIFIED="1242317022323" TEXT="Publishing reports">
<node CREATED="1242316952727" ID="Freemind_Link_1337985998" MODIFIED="1242417044466" TEXT="Server creates reports using &quot;reporter save&quot;"/>
<node CREATED="1242317026854" ID="Freemind_Link_1101277690" MODIFIED="1242417057709" TEXT="reporter calls -reportcmd"/>
<node CREATED="1242317033895" ID="Freemind_Link_444498205" MODIFIED="1242417089937" TEXT="-reportcmd sends report dict to client"/>
<node CREATED="1242317061894" ID="Freemind_Link_1896871798" MODIFIED="1242417124834" TEXT="Client receives report dict and saves it."/>
</node>
<node CREATED="1242316997528" ID="Freemind_Link_1705280740" MODIFIED="1242317101905" TEXT="Publishing bin definitions">
<node CREATED="1242317102326" ID="Freemind_Link_536799035" MODIFIED="1242417189640" TEXT="On refresh, server sends the following to the client:&#xa;&quot;reporter bin setall [reporter bin getall]&quot;"/>
</node>
</node>
</node>
<node CREATED="1242253547830" ID="Freemind_Link_832535930" MODIFIED="1242253552272" POSITION="right" TEXT="Generic Binning">
<node CREATED="1242253609398" ID="Freemind_Link_1598130818" MODIFIED="1242417217201" TEXT="The application can define any bins it likes">
<node CREATED="1242253625654" ID="Freemind_Link_170199128" MODIFIED="1242253634783" TEXT="Name"/>
<node CREATED="1242253635062" ID="Freemind_Link_763319936" MODIFIED="1242253646879" TEXT="Parent Bin, or &quot;&quot;"/>
<node CREATED="1242253647493" ID="Freemind_Link_677559645" MODIFIED="1242253655071" TEXT="SQL view"/>
</node>
<node CREATED="1242417242199" ID="Freemind_Link_1589985234" MODIFIED="1242417254849" TEXT="The reportbrowser retrieves the bin tree"/>
</node>
<node CREATED="1242254129588" ID="Freemind_Link_1175082206" MODIFIED="1242254132016" POSITION="right" TEXT="Thoughts">
<node CREATED="1242254458501" ID="Freemind_Link_1696953448" MODIFIED="1242254479773" TEXT="Should use tablebrowser for the report list."/>
<node CREATED="1242317154374" ID="Freemind_Link_1173159262" MODIFIED="1242417265997" TEXT="Use tkhtml2 to display reports?">
<icon BUILTIN="button_cancel"/>
<node CREATED="1242317172294" ID="Freemind_Link_805909827" MODIFIED="1242417287337" TEXT="Could display plain text, using &lt;pre&gt;...&lt;/pre&gt;"/>
<node CREATED="1242317209093" ID="Freemind_Link_1132261456" MODIFIED="1242317219712" TEXT="Opens door to formatted reports..."/>
<node CREATED="1242317224231" ID="Freemind_Link_825792092" MODIFIED="1242417281625" TEXT="Generated formatted reports might take longer"/>
<node CREATED="1242317232247" ID="Freemind_Link_1092459996" MODIFIED="1242317240512" TEXT="Displaying formatted reports probably takes longer"/>
</node>
</node>
</node>
</map>
