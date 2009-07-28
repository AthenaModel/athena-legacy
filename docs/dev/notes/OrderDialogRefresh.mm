<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1248795870175" ID="Freemind_Link_1546661020" MODIFIED="1248795883245" TEXT="Order Dialog Refresh">
<node CREATED="1248795920819" ID="_" MODIFIED="1248795939308" POSITION="right" TEXT="Definition">
<node CREATED="1248795939760" ID="Freemind_Link_21238445" MODIFIED="1248796027896" TEXT="An order dialog consists of one or more fields."/>
<node CREATED="1248795958607" ID="Freemind_Link_1317598091" MODIFIED="1248796031848" TEXT="Each field is related to a particular order parameter."/>
<node CREATED="1248795967231" ID="Freemind_Link_1204761977" MODIFIED="1248796035391" TEXT="It is the order handler&apos;s job to determine which parameter values are valid."/>
<node CREATED="1248796002480" ID="Freemind_Link_1041613653" MODIFIED="1248796021785" TEXT="However, some fields (e.g., pulldowns) need to know something about what&apos;s valid."/>
<node CREATED="1248796084447" ID="Freemind_Link_1258228285" MODIFIED="1248796098378" TEXT="What&apos;s valid can depend on:">
<node CREATED="1248796098879" ID="Freemind_Link_1252102088" MODIFIED="1248796126361" TEXT="The previous field values in the dialog."/>
<node CREATED="1248796111983" ID="Freemind_Link_793356245" MODIFIED="1248796123033" TEXT="The state of the simulation in general."/>
</node>
<node CREATED="1248796127998" ID="Freemind_Link_1701912749" MODIFIED="1248796174682" TEXT="Refreshing a field">
<node CREATED="1248796175151" ID="Freemind_Link_1443595644" MODIFIED="1248796195721" TEXT="Means letting it determine what&apos;s currently valid."/>
<node CREATED="1248796197934" ID="Freemind_Link_99923503" MODIFIED="1248796203450" TEXT="Can involve:">
<node CREATED="1248796203918" ID="Freemind_Link_1962176992" MODIFIED="1248796212760" TEXT="Enabling/disabling the field"/>
<node CREATED="1248796213039" ID="Freemind_Link_1044598681" MODIFIED="1248796220376" TEXT="Setting/clearing the field&apos;s current value"/>
<node CREATED="1248796220767" ID="Freemind_Link_535039967" MODIFIED="1248796232280" TEXT="Setting the list of valid values (for enumerations)"/>
<node CREATED="1248796237071" ID="Freemind_Link_1455148465" MODIFIED="1248796238888" TEXT="?????"/>
</node>
</node>
<node CREATED="1248796253630" ID="Freemind_Link_495172278" MODIFIED="1248796301595" TEXT="When a field&apos;s value changes, all subsequent &#xa;fields are refreshed">
<node CREATED="1248796269471" ID="Freemind_Link_648418871" MODIFIED="1248796276744" TEXT="In principle"/>
<node CREATED="1248796278590" ID="Freemind_Link_444908815" MODIFIED="1248796318678" TEXT="In practice, a flag indicates whether a change to&#xa;the field&apos;s value triggers a refresh."/>
</node>
<node CREATED="1248796322047" ID="Freemind_Link_229350460" MODIFIED="1248796343974" TEXT="Refreshing the dialog means refresh all fields, &#xa;from first to last."/>
</node>
<node CREATED="1248796361727" ID="Freemind_Link_331688781" MODIFIED="1248796369993" POSITION="right" TEXT="What happens when a field is refreshed">
<node CREATED="1248796370350" ID="Freemind_Link_1523104328" MODIFIED="1248796375625" TEXT="Key fields">
<node CREATED="1248796375918" ID="Freemind_Link_686380251" MODIFIED="1248796383544" TEXT="The list of valid values is re-read from the database"/>
</node>
<node CREATED="1248796409646" ID="Freemind_Link_1219368543" MODIFIED="1248796415801" TEXT="Enum fields with -type">
<node CREATED="1248796416110" ID="Freemind_Link_41925917" MODIFIED="1248796422536" TEXT="The list of valid values is re-read from the type"/>
</node>
<node CREATED="1248796424527" ID="Freemind_Link_866703381" MODIFIED="1248796429481" TEXT="Any field with -refreshcmd">
<node CREATED="1248796429838" ID="Freemind_Link_1227913749" MODIFIED="1248796445624" TEXT="The -refreshcmd is called, and it does what it does"/>
</node>
</node>
<node CREATED="1248796513613" ID="Freemind_Link_1572591128" MODIFIED="1248796526425" POSITION="right" TEXT="The dialog as a whole is refreshed:">
<node CREATED="1248796527566" ID="Freemind_Link_1499725192" MODIFIED="1248796533016" TEXT="When popped up"/>
<node CREATED="1248796533391" ID="Freemind_Link_799560329" MODIFIED="1248796539112" TEXT="On &quot;Clear&quot;"/>
<node CREATED="1248796539742" ID="Freemind_Link_1300874506" MODIFIED="1248796561678" TEXT="When the simulation state might have &#xa;changed in a significant way.">
<node CREATED="1248796562798" ID="Freemind_Link_813493451" MODIFIED="1248796570327" TEXT="After each order is processed"/>
<node CREATED="1248796571230" ID="Freemind_Link_641523173" MODIFIED="1248796576696" TEXT="After each time tick"/>
</node>
</node>
<node CREATED="1248796594447" ID="Freemind_Link_1014424441" MODIFIED="1248796601001" POSITION="right" TEXT="For the future:">
<node CREATED="1248796601438" ID="Freemind_Link_1696289691" MODIFIED="1248796626711" TEXT="Characterize exactly what -refreshcmds actually do in practice"/>
<node CREATED="1248796627021" ID="Freemind_Link_595042895" MODIFIED="1248796633847" TEXT="See if there&apos;s an easier way to do the same thing"/>
<node CREATED="1248796636461" ID="Freemind_Link_102316584" MODIFIED="1248796645240" TEXT="See if there are other rules that should be followed">
<node CREATED="1248796645517" ID="Freemind_Link_1165307397" MODIFIED="1248796660103" TEXT="I.e., if the enum has no valid values, it&apos;s disabled."/>
</node>
</node>
</node>
</map>
