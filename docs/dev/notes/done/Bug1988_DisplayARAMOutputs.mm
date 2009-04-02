<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1238513450107" ID="Freemind_Link_1362554758" MODIFIED="1238513460918" TEXT="Display ARAM Outputs">
<node CREATED="1238686916746" ID="Freemind_Link_727602711" MODIFIED="1238686927023" POSITION="right" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238513902140" ID="Freemind_Link_1093815571" MODIFIED="1238686924799" TEXT="Easy Outputs">
<node CREATED="1238513462364" ID="_" MODIFIED="1238513471062" TEXT="Satisfaction level">
<node CREATED="1238513537516" ID="Freemind_Link_546236318" MODIFIED="1238513541878" TEXT="In Sat tab"/>
</node>
<node CREATED="1238513471468" ID="Freemind_Link_1488824991" MODIFIED="1238513498038" TEXT="Satisfaction mood">
<node CREATED="1238513545372" ID="Freemind_Link_655608650" MODIFIED="1238513567142" TEXT="CIVs: In nbgroups tab"/>
<node CREATED="1238513567964" ID="Freemind_Link_934590409" MODIFIED="1238513580918" TEXT="ORGs: Mood is just CAS; no need to display it."/>
</node>
<node CREATED="1238513475964" ID="Freemind_Link_1063575566" MODIFIED="1238513480118" TEXT="Cooperation level">
<node CREATED="1238513589405" ID="Freemind_Link_1488117750" MODIFIED="1238513592214" TEXT="In Coop tab"/>
</node>
</node>
<node CREATED="1238513521053" ID="Freemind_Link_827038239" MODIFIED="1238513621094" TEXT="Join GRAM tables with GUI views">
<node CREATED="1238513624477" ID="Freemind_Link_1555932134" MODIFIED="1238687154563" TEXT="Ensure that GRAM tables are invalid in PREP state"/>
<node CREATED="1238687003417" ID="Freemind_Link_424287950" MODIFIED="1238687020051" TEXT="Use left outer join so that NULLs are OK"/>
<node CREATED="1238687021209" ID="Freemind_Link_783894674" MODIFIED="1238687032979" TEXT="In view, convert NULL to initial value, or 0.0">
<node CREATED="1238687039385" ID="Freemind_Link_760283125" MODIFIED="1238687126441" TEXT="Tablelist can&apos;t cope with non-numeric values&#xa;in columns sorted as floating point."/>
</node>
</node>
</node>
<node CREATED="1238686906474" ID="Freemind_Link_1024916433" MODIFIED="1238686911906" POSITION="right" TEXT="sim(sim) changes">
<node CREATED="1238687188600" ID="Freemind_Link_1421268975" MODIFIED="1238688061317" TEXT="&quot;clear&quot; GRAM on return to PREP">
<icon BUILTIN="button_ok"/>
<node CREATED="1238687205369" ID="Freemind_Link_1551832867" MODIFIED="1238687213139" TEXT="Ensures GRAM tables are invalid in PREP state"/>
</node>
</node>
<node CREATED="1238687231961" ID="Freemind_Link_218414122" MODIFIED="1238693023622" POSITION="right" TEXT="Outputs">
<node CREATED="1238687238921" ID="Freemind_Link_1573153266" MODIFIED="1238688071189" TEXT="Satisfaction level">
<icon BUILTIN="button_ok"/>
<node CREATED="1238687249913" ID="Freemind_Link_1923784955" MODIFIED="1238688071190" TEXT="Add to gui_sat_ngc view">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238692991085" ID="Freemind_Link_341350653" MODIFIED="1238693001610" TEXT="satbrowser(sim) uses browser_base(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687283705" ID="Freemind_Link_1746018501" MODIFIED="1238688071190" TEXT="Display in satbrowser(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687290745" ID="Freemind_Link_467958280" MODIFIED="1238688071190" TEXT="Update satbrowser(sim) on each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238694049754" ID="Freemind_Link_1183215814" MODIFIED="1238695436776" TEXT="nbgroup mood">
<icon BUILTIN="button_ok"/>
<node CREATED="1238694058762" ID="Freemind_Link_953932921" MODIFIED="1238695436774" TEXT="Add to gui_nbgroups">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238692991085" ID="Freemind_Link_1210867595" MODIFIED="1238695436775" TEXT="nbgroupbrowser(sim) uses browser_base(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238694076171" ID="Freemind_Link_511189845" MODIFIED="1238695436775" TEXT="Display in nbgroupbrowser(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238694084410" ID="Freemind_Link_1820930935" MODIFIED="1238695436775" TEXT="Update nbgroupbrowser(sim) on each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238687238921" ID="Freemind_Link_1557291643" MODIFIED="1238697284794" TEXT="Cooperation Level">
<icon BUILTIN="button_ok"/>
<node CREATED="1238687249913" ID="Freemind_Link_228174065" MODIFIED="1238696764835" TEXT="Add to gui_coop_nfg view">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238692991085" ID="Freemind_Link_806824872" MODIFIED="1238697284795" TEXT="coopbrowser(sim) uses browser_base(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687283705" ID="Freemind_Link_1418401896" MODIFIED="1238697284796" TEXT="Display in coopbrowser(sim)">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238687290745" ID="Freemind_Link_579471615" MODIFIED="1238697284795" TEXT="Update coopbrowser(sim) on each tick">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node CREATED="1238692222334" ID="Freemind_Link_1205103087" MODIFIED="1238693014892" POSITION="right" TEXT="Browser changes:">
<icon BUILTIN="button_ok"/>
<node CREATED="1238692232062" ID="Freemind_Link_444483456" MODIFIED="1238693654817" TEXT="tablebrowser(n):">
<node CREATED="1238692299374" ID="Freemind_Link_559358856" MODIFIED="1238693652025" TEXT="&quot;toolbar&quot; queries the toolbar">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238693643339" ID="Freemind_Link_135985490" MODIFIED="1238697697417" TEXT="Update manpage">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238692311022" ID="Freemind_Link_1565959369" MODIFIED="1238693014891" TEXT="browser_base(sim)">
<icon BUILTIN="button_ok"/>
<node CREATED="1238692323469" ID="Freemind_Link_428964578" MODIFIED="1238692325848" TEXT="New module"/>
<node CREATED="1238692326269" ID="Freemind_Link_474762533" MODIFIED="1238692331032" TEXT="Common behavior among browsers"/>
<node CREATED="1238692335887" ID="Freemind_Link_985382742" MODIFIED="1238692345624" TEXT="reloads only when mapped"/>
</node>
</node>
<node CREATED="1238513511116" ID="Freemind_Link_774003595" MODIFIED="1238697716513" POSITION="right" TEXT="Subsequent work, as needed">
<icon BUILTIN="flag"/>
<node CREATED="1238514000940" ID="Freemind_Link_682310181" MODIFIED="1238514005925" TEXT="Time Series Plots"/>
<node CREATED="1238513993932" ID="Freemind_Link_26326231" MODIFIED="1238514038997" TEXT="History and Causality Visualization"/>
<node CREATED="1238513921852" ID="Freemind_Link_1922832150" MODIFIED="1238513945126" TEXT="Roll-ups other than mood"/>
</node>
</node>
</map>
