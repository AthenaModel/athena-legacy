<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node TEXT="Cell Model IDE" ID="ID_1374927924" CREATED="1341603422432" MODIFIED="1345745265690">
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="cellmodel(5) IDE" POSITION="right" ID="ID_1252001141" CREATED="1345235120861" MODIFIED="1345235136259">
<icon BUILTIN="idea"/>
</node>
<node TEXT="To Do" POSITION="left" ID="ID_895967303" CREATED="1345670881486" MODIFIED="1345670883890">
<node TEXT="Executive" ID="ID_772441423" CREATED="1345671868602" MODIFIED="1345671894958"/>
<node TEXT="CLI in .main" ID="ID_1431289223" CREATED="1345671895633" MODIFIED="1345671898685"/>
<node TEXT="Tabs in .main, including Detail Browser" ID="ID_498831741" CREATED="1345671918480" MODIFIED="1345671929228"/>
</node>
<node TEXT="HTML" FOLDED="true" POSITION="left" ID="ID_766569321" CREATED="1345243822968" MODIFIED="1345243824542">
<node TEXT="appserver display of expanded model, with links from cell to cell" ID="ID_640097853" CREATED="1345243824929" MODIFIED="1345243836782"/>
</node>
<node TEXT="Tabbed window" FOLDED="true" POSITION="left" ID="ID_1639094298" CREATED="1345242239808" MODIFIED="1345242245069">
<node TEXT="Cell Model tab" ID="ID_424385705" CREATED="1345242586052" MODIFIED="1345242589593"/>
<node TEXT="Sheets tab" ID="ID_1492455643" CREATED="1345242590077" MODIFIED="1345242592297"/>
<node TEXT="Other tabs for running and browsing the contents." ID="ID_1776415332" CREATED="1345242601749" MODIFIED="1345242612626"/>
</node>
<node TEXT="Projects" POSITION="left" ID="ID_595781084" CREATED="1345242245847" MODIFIED="1345242273259">
<node TEXT="Project file is an SQLite file" ID="ID_378604453" CREATED="1345242253007" MODIFIED="1345242258611"/>
<node TEXT="Need project module" FOLDED="true" ID="ID_227721713" CREATED="1345242258910" MODIFIED="1345242290289">
<node TEXT="Like scenario module in app_sim" ID="ID_1877568682" CREATED="1345242291941" MODIFIED="1345242297177"/>
</node>
<node TEXT="Contains" ID="ID_1849644612" CREATED="1345242302923" MODIFIED="1345242321888">
<node TEXT="Any number of cell models" ID="ID_1841986765" CREATED="1345242322627" MODIFIED="1345584526711"/>
<node TEXT="Each cell model has zero or more sheets" ID="ID_41975989" CREATED="1345242334404" MODIFIED="1345584545511"/>
</node>
<node TEXT="The entire project is loaded and saved as one." ID="ID_473569592" CREATED="1345242379070" MODIFIED="1345242385907"/>
</node>
<node TEXT="Infrastructure" FOLDED="true" POSITION="left" ID="ID_1772245955" CREATED="1345584587507" MODIFIED="1345584590497">
<node TEXT="Editor Widget" ID="ID_758488912" CREATED="1345235139334" MODIFIED="1345242238924">
<node TEXT="Based on ctext" ID="ID_1941842186" CREATED="1345235142454" MODIFIED="1345241740864">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="cellmodel(5) syntax highlighting" ID="ID_1261974155" CREATED="1345235149823" MODIFIED="1345241740866">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Syntax highlighting packages" ID="ID_426787954" CREATED="1345235172527" MODIFIED="1345241740865">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="snit wrapper for ctext" ID="ID_702889873" CREATED="1345235178943" MODIFIED="1345241740865">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="indent is 4 spaces" ID="ID_647278443" CREATED="1345235203354" MODIFIED="1345241740865">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node TEXT="Scenario Manager" ID="ID_1899824140" CREATED="1345584741073" MODIFIED="1345584747414">
<node TEXT="Manages RDB, etc." ID="ID_640005286" CREATED="1345584748593" MODIFIED="1345584755565"/>
</node>
<node TEXT="appserver" ID="ID_1500688260" CREATED="1345584608389" MODIFIED="1345588560147">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Project Tree" ID="ID_1701660678" CREATED="1345584635862" MODIFIED="1345584638459">
<node TEXT="Uses linktree" ID="ID_527342596" CREATED="1345584638798" MODIFIED="1345584662851"/>
</node>
<node TEXT="Tab manager" ID="ID_1940770079" CREATED="1345584610821" MODIFIED="1345584671260">
<node TEXT="Edit tab" ID="ID_1316333411" CREATED="1345584671687" MODIFIED="1345584674276">
<node TEXT="Edits item selected in project tree" ID="ID_1792660133" CREATED="1345584674704" MODIFIED="1345584681052"/>
<node TEXT="Content varies depending on type of item" ID="ID_224778892" CREATED="1345584684264" MODIFIED="1345584697798"/>
</node>
</node>
</node>
<node TEXT="Architectures" FOLDED="true" POSITION="right" ID="ID_474804534" CREATED="1345747973710" MODIFIED="1345747981198">
<node TEXT="SQLite Project File" ID="ID_1828977772" CREATED="1345744482457" MODIFIED="1345744489773">
<node TEXT="Document format for athena_cell" ID="ID_49291887" CREATED="1345744525926" MODIFIED="1345744553881"/>
<node TEXT="SQLite database" ID="ID_138103534" CREATED="1345744558795" MODIFIED="1345744568654"/>
<node TEXT="Contains one or more cell models with attached cmsheet scripts, plus metadata" ID="ID_553781791" CREATED="1345744490202" MODIFIED="1345744574309"/>
<node TEXT="Advantages" ID="ID_1511536629" CREATED="1345744575191" MODIFIED="1345744577078">
<node TEXT="Related cell model information is stored in a single file." ID="ID_1019317089" CREATED="1345744577632" MODIFIED="1345744606757"/>
<node TEXT="It sounds fun to do." ID="ID_515556618" CREATED="1345744608840" MODIFIED="1345744612880"/>
</node>
<node TEXT="Disadvantages" ID="ID_1384265990" CREATED="1345744615181" MODIFIED="1345744618769">
<node TEXT="SQLite DB" ID="ID_1159770083" CREATED="1345744619417" MODIFIED="1345744737088">
<node TEXT="The project file would be part of the Athena source code." ID="ID_1289850427" CREATED="1345744737548" MODIFIED="1345744761869"/>
<node TEXT="Athena.exe can&apos;t access SQLite DBs that are stored within athena.exe." ID="ID_1493091599" CREATED="1345744762267" MODIFIED="1345744778428"/>
<node TEXT="Adds complexity; and is probably not worth it." ID="ID_570991490" CREATED="1345744779138" MODIFIED="1345744786330"/>
<node TEXT="But, could make &quot;athena cell -export&quot; export the current files; do this in the build process." ID="ID_498352710" CREATED="1345747309841" MODIFIED="1345747357781">
<icon BUILTIN="ksmiletris"/>
</node>
</node>
<node TEXT="User interactions" ID="ID_811505725" CREATED="1345744794294" MODIFIED="1345744797975">
<node TEXT="I don&apos;t completely understand how a user should interact with the application." ID="ID_1786107448" CREATED="1345744798248" MODIFIED="1345744843005"/>
<node TEXT="It&apos;s nice to edit a file and have the choice to explicitly save or not." ID="ID_759691481" CREATED="1345744850992" MODIFIED="1345744887199"/>
<node TEXT="But here, we have two &quot;files&quot;:  The project as a whole, and the individual script." ID="ID_1039370325" CREATED="1345744942696" MODIFIED="1345744959607"/>
<node TEXT="How do we distinguish between saving or not saving the individual script when they save the project?" ID="ID_1142528317" CREATED="1345745002429" MODIFIED="1345745025174"/>
<node TEXT="Could use Wiki-style editing." ID="ID_197209738" CREATED="1345747342383" MODIFIED="1345747354661">
<icon BUILTIN="ksmiletris"/>
</node>
</node>
</node>
</node>
<node TEXT="Project Metadata File" ID="ID_1162708421" CREATED="1345745040680" MODIFIED="1345745049880">
<node TEXT="" ID="ID_1904145098" CREATED="1345745073038" MODIFIED="1345745075440">
<icon BUILTIN="idea"/>
<node TEXT="Most IDEs keep the source files on the disk." ID="ID_466837258" CREATED="1345745076181" MODIFIED="1345745084746"/>
<node TEXT="The project file stores metadata about the project, including which files are included." ID="ID_1107322630" CREATED="1345745085112" MODIFIED="1345745103068"/>
<node TEXT="This allows the project to be built, etc." ID="ID_84475221" CREATED="1345745103450" MODIFIED="1345745112904"/>
</node>
<node TEXT="Advantages" ID="ID_832582211" CREATED="1345745119229" MODIFIED="1345745121616">
<node TEXT="Project file doesn&apos;t get delivered, so can safely be SQLite." ID="ID_697338733" CREATED="1345745121983" MODIFIED="1345745133480"/>
<node TEXT="Allows a number of artifacts to be grouped." ID="ID_914884599" CREATED="1345745136779" MODIFIED="1345745148448"/>
</node>
<node TEXT="Disadvantages" ID="ID_571507720" CREATED="1345745149423" MODIFIED="1345745151810">
<node TEXT="I&apos;ve not often used IDEs of this sort; I don&apos;t have a good gut feel for the interaction patterns." ID="ID_1776191836" CREATED="1345745152255" MODIFIED="1345745220910"/>
<node TEXT="How do you synchronize the project with the files on the disk?" ID="ID_27709652" CREATED="1345745221370" MODIFIED="1345745237360"/>
<node TEXT="Not clear that there&apos;s much metadata beyond the scripts." ID="ID_1762468103" CREATED="1345745241689" MODIFIED="1345745255558"/>
</node>
</node>
<node TEXT="Wiki editing" ID="ID_1290173802" CREATED="1345744887925" MODIFIED="1345744890436">
<node TEXT="Do everything in the detail browser" ID="ID_1119223350" CREATED="1345744890663" MODIFIED="1345744897745"/>
<node TEXT="Displays an HTML page about the model, with an edit button." ID="ID_1862478870" CREATED="1345744900202" MODIFIED="1345744911450"/>
<node TEXT="Takes you to a different page, with an editor window in it, as in a Wiki." ID="ID_482484995" CREATED="1345744911832" MODIFIED="1345744932159"/>
<node TEXT="Modal!" ID="ID_1204389036" CREATED="1345744932588" MODIFIED="1345744937190"/>
</node>
</node>
<node TEXT="Simplest Thing" FOLDED="true" POSITION="right" ID="ID_1079068103" CREATED="1345747988054" MODIFIED="1345747991596">
<node TEXT="What&apos;s the simplest thing that I can do that would be somewhat useful?" ID="ID_1092497164" CREATED="1345747992134" MODIFIED="1345748021252">
<icon BUILTIN="idea"/>
</node>
<node TEXT="Required Features" ID="ID_655518136" CREATED="1345748152605" MODIFIED="1345748163220">
<node TEXT="A tool" ID="ID_1373841446" CREATED="1345748022648" MODIFIED="1346084871007">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="that can edit and save one cellmodel at a time" ID="ID_592308092" CREATED="1345748026337" MODIFIED="1346084871009">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="that can validate the cell model source code, taking me to the line that is in error" ID="ID_22106532" CREATED="1345748031914" MODIFIED="1346084871008">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="that can let me explore the content of valid cell models" ID="ID_248058343" CREATED="1345748057116" MODIFIED="1346882637943">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="that can help me run the model and examine the root of runtime errors" ID="ID_1122750597" CREATED="1345748117816" MODIFIED="1345748134883"/>
<node TEXT="that can let me import and edit the input values, distinct from those in the cellmodel(5) script" ID="ID_37886187" CREATED="1345748199639" MODIFIED="1345748216581"/>
</node>
<node TEXT="Features Not Required" ID="ID_359409862" CREATED="1345748163852" MODIFIED="1345748169499">
<node TEXT="Project file" ID="ID_1251994346" CREATED="1345748169819" MODIFIED="1345748171520"/>
<node TEXT="SQLite storage" ID="ID_935404100" CREATED="1345748171839" MODIFIED="1345748176488"/>
<node TEXT="cmsheet scripts (which don&apos;t exist yet anyway)" ID="ID_1919353422" CREATED="1345748176886" MODIFIED="1345748187447"/>
</node>
<node TEXT="Architecture" ID="ID_89524609" CREATED="1345748227735" MODIFIED="1345748229872">
<node TEXT="Window with" ID="ID_369292037" CREATED="1345748230270" MODIFIED="1345748238397">
<node TEXT="Main menu" ID="ID_973373937" CREATED="1345748238733" MODIFIED="1345748240667">
<node TEXT="Standard document-centric menus" ID="ID_759239644" CREATED="1345748301040" MODIFIED="1345748336639"/>
</node>
<node TEXT="Toolbar" ID="ID_314621180" CREATED="1345748241081" MODIFIED="1345748243467"/>
<node TEXT="Script tab, for editing cellmodel(5) scripts" ID="ID_390534167" CREATED="1345748243850" MODIFIED="1345748265237"/>
<node TEXT="Detail browser tab, for exploring the cell model" ID="ID_179385037" CREATED="1345748267024" MODIFIED="1345748278474"/>
<node TEXT="Tabs for running the cell model, and editing inputs" ID="ID_1643232303" CREATED="1345748280229" MODIFIED="1345748287701">
<node TEXT="Possibly embedded in detail browser tab" ID="ID_543064630" CREATED="1345748288115" MODIFIED="1345748299815"/>
</node>
</node>
<node TEXT="cmscript module" FOLDED="true" ID="ID_1465916911" CREATED="1345748397370" MODIFIED="1345748399804">
<node TEXT="For managing the currently loaded cellmodel(5) script" ID="ID_1759192769" CREATED="1345748400077" MODIFIED="1345748408064"/>
<node TEXT="Associated with the editor window" ID="ID_1722054661" CREATED="1345748409008" MODIFIED="1345748417494"/>
<node TEXT="Replaced project/projectdb." ID="ID_553789273" CREATED="1345748422923" MODIFIED="1345748428570"/>
</node>
</node>
</node>
<node TEXT="Problems" POSITION="right" ID="ID_1459946860" CREATED="1345760892431" MODIFIED="1347396461516">
<node TEXT="After editing the file, the checkstate is unchanged.  It&apos;s supposed to go back to &quot;unchecked&quot;." ID="ID_352119609" CREATED="1347396461878" MODIFIED="1347396487181"/>
<node TEXT="Executing &quot;check&quot; (or, eventually, &quot;solve&quot;) should cause the detail browser to refresh." ID="ID_1382632313" CREATED="1347396498920" MODIFIED="1347396527326"/>
</node>
</node>
</map>
