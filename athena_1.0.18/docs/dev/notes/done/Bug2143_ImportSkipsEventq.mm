<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1244136800220" ID="Freemind_Link_1527347729" MODIFIED="1244137967030" TEXT="Importing Skips eventq data">
<node CREATED="1244138024796" ID="Freemind_Link_755624677" MODIFIED="1244138030394" POSITION="left" TEXT="Problem">
<icon BUILTIN="flag"/>
<node CREATED="1244136810910" ID="_" MODIFIED="1244138033498" TEXT="Permanent tables defined solely by athena_sim(1) can&#xa;be exported by athena_export(1) but cannot be &#xa;imported by athena_import(1), because they do not&#xa;appear in the schema that&apos;s visible to athena_export(1)."/>
<node CREATED="1244137971964" ID="Freemind_Link_1537261072" MODIFIED="1244137998662" TEXT="eventq(n) events defined by the app add tables to the schema."/>
<node CREATED="1244137999788" ID="Freemind_Link_255775383" MODIFIED="1244138021206" TEXT="These tables are therefore lost on import."/>
</node>
<node CREATED="1244138041532" ID="Freemind_Link_1014555769" MODIFIED="1244138044438" POSITION="left" TEXT="Solution">
<node CREATED="1244137707516" ID="Freemind_Link_942404462" MODIFIED="1244138077850" TEXT="Option A is the pragmatic decision in the short run."/>
<node CREATED="1244137719259" ID="Freemind_Link_1925412338" MODIFIED="1244137775611" TEXT="Option C might be a good constraint in the long run&#xa;but will take more effort to implement in the&#xa;short run."/>
</node>
<node CREATED="1244136879326" ID="Freemind_Link_703144847" MODIFIED="1244145265422" POSITION="right" TEXT="Option A">
<icon BUILTIN="ksmiletris"/>
<node CREATED="1244136952894" ID="Freemind_Link_1575358145" MODIFIED="1244137137327" TEXT="All import/export is done by athena_sim(1) itself">
<font BOLD="true" NAME="SansSerif" SIZE="12"/>
</node>
<node CREATED="1244139097866" ID="Freemind_Link_121483282" MODIFIED="1244139102706" TEXT="For Users">
<node CREATED="1244136896413" ID="Freemind_Link_1308594166" MODIFIED="1244139123909" TEXT="Add File/Export menu item">
<node CREATED="1244139124298" ID="Freemind_Link_1029206073" MODIFIED="1244139128932" TEXT="Exports current scenario"/>
</node>
<node CREATED="1244139130650" ID="Freemind_Link_1815613021" MODIFIED="1244139135833" TEXT="Add File/Import menu item">
<node CREATED="1244139136314" ID="Freemind_Link_1099566228" MODIFIED="1244139177635" TEXT="Opens an .xml file."/>
</node>
<node CREATED="1244136930109" ID="Freemind_Link_927950856" MODIFIED="1244136952199" TEXT="Delete the athena_export(1)/athena_import(1) programs"/>
<node CREATED="1244137677516" ID="Freemind_Link_1621414426" MODIFIED="1244137686700" TEXT="Probably more convenient for the user anyway."/>
</node>
<node CREATED="1244139213898" ID="Freemind_Link_1847184838" MODIFIED="1244139217332" TEXT="For Developers">
<node CREATED="1244137018669" ID="Freemind_Link_1844985664" MODIFIED="1244139225881" TEXT="Add an undocumented &quot;super&quot; command to &#xa;export then re-import a database, for convenience&#xa;when updating a schema during development."/>
</node>
<node CREATED="1244137669164" ID="Freemind_Link_1937032728" MODIFIED="1244137671797" TEXT="And then,">
<node CREATED="1244136983917" ID="Freemind_Link_910246775" MODIFIED="1244137007583" TEXT="If command-line tools are needed, make them&#xa;additional entry points to athena_sim(1).">
<node CREATED="1244139377130" ID="Freemind_Link_876509106" MODIFIED="1244139381681" TEXT="Ugh."/>
</node>
</node>
<node CREATED="1244139279578" ID="Freemind_Link_187100259" MODIFIED="1244139282244" TEXT="But">
<node CREATED="1244139236634" ID="Freemind_Link_597908797" MODIFIED="1244145259575" TEXT="The menu items are inconvenient for developers, &#xa;as they require that you have to load a scenario into the&#xa;RDB before exporting it.  Thus, you have to export&#xa;*before* changing the schema.  (I would usually&#xa;forget.)  Thus, the &quot;super&quot; command is essential."/>
</node>
</node>
<node CREATED="1244137146813" ID="Freemind_Link_666637169" MODIFIED="1244137443634" POSITION="right" TEXT="Option B">
<icon BUILTIN="button_cancel"/>
<node CREATED="1244137155517" ID="Freemind_Link_1196895052" MODIFIED="1244137179068" TEXT="Add schema information to the exported XML file.">
<font BOLD="true" NAME="SansSerif" SIZE="12"/>
</node>
<node CREATED="1244137179853" ID="Freemind_Link_1498603088" MODIFIED="1244137238206" TEXT="On import, use a table&apos;s exported schema when the&#xa;importer has no schema for the table."/>
<node CREATED="1244137244604" ID="Freemind_Link_787569363" MODIFIED="1244137433922" TEXT="But">
<node CREATED="1244137263453" ID="Freemind_Link_1492276309" MODIFIED="1244137335364" TEXT="The schema is unneeded on import unless the schema&#xa;has changed."/>
<node CREATED="1244137336988" ID="Freemind_Link_221220900" MODIFIED="1244137354310" TEXT="If the schema has changed, we want the new schema to prevail."/>
<node CREATED="1244137357372" ID="Freemind_Link_750167466" MODIFIED="1244137426474" TEXT="Additions or changes to eventq event parameters&#xa;would always require hand edits to the exported&#xa;XML file.">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_cancel"/>
</node>
</node>
</node>
<node CREATED="1244137458125" ID="Freemind_Link_1184304634" MODIFIED="1244137462119" POSITION="right" TEXT="Option C">
<node CREATED="1244137463389" ID="Freemind_Link_1842501800" MODIFIED="1244137486316" TEXT="All permanent table definitions are visible in projectlib(n).">
<font BOLD="true" NAME="SansSerif" SIZE="12"/>
</node>
<node CREATED="1244137495293" ID="Freemind_Link_1899149527" MODIFIED="1244137508742" TEXT="The application is not allowed to add ad hoc table definitions to the scenario.">
<node CREATED="1244137628332" ID="Freemind_Link_1833495801" MODIFIED="1244137641508" TEXT="(Temporary tables/views/etc. are OK)"/>
</node>
<node CREATED="1244137610813" ID="Freemind_Link_567849670" MODIFIED="1244137654086" TEXT="All Athena applications then have access to the whole schema.">
<node CREATED="1244137821261" ID="Freemind_Link_1290441485" MODIFIED="1244137886435" TEXT="But only apps that create new scenario files&#xa;need a priori access to the schema.  How many&#xa;command line tools like that do we need?"/>
</node>
<node CREATED="1244137511085" ID="Freemind_Link_174117984" MODIFIED="1244137518647" TEXT="But">
<node CREATED="1244137519149" ID="Freemind_Link_877482338" MODIFIED="1244137545382" TEXT="Requires a change to eventq(n).">
<node CREATED="1244137548700" ID="Freemind_Link_1600167184" MODIFIED="1244137564678" TEXT="Event type parameters would be defined in projectlib(n)"/>
<node CREATED="1244137565116" ID="Freemind_Link_974724769" MODIFIED="1244137588619" TEXT="Event handlers could be defined elsewhere.  E.g., in&#xa;the application."/>
</node>
</node>
</node>
</node>
</map>
