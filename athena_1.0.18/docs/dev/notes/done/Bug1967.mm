<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1238171285579" ID="Freemind_Link_164640460" MODIFIED="1238174577560" TEXT="Scenario Sanity Check">
<node CREATED="1238171311427" ID="_" MODIFIED="1238171324314" POSITION="right" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1237479063275" ID="Freemind_Link_1873084845" MODIFIED="1238174587800" TEXT="The scenario must be sane before time can advance."/>
<node CREATED="1238171344773" ID="Freemind_Link_426910570" MODIFIED="1238171427950" TEXT="Do a sanity check on SIM:RUN">
<node CREATED="1238171428405" ID="Freemind_Link_759586256" MODIFIED="1238171433550" TEXT="Order is rejected."/>
<node CREATED="1238171434340" ID="Freemind_Link_875208047" MODIFIED="1238171449006" TEXT="Present warnings to user"/>
</node>
<node CREATED="1238170280470" ID="Freemind_Link_1857797714" MODIFIED="1238173690494" TEXT="Conditions">
<icon BUILTIN="button_ok"/>
<node CREATED="1238170282869" ID="Freemind_Link_320313644" MODIFIED="1238170286656" TEXT="At least one nbhood"/>
<node CREATED="1238170287253" ID="Freemind_Link_236425242" MODIFIED="1238170293808" TEXT="At least one FRC group"/>
<node CREATED="1238173505296" ID="Freemind_Link_1273631840" MODIFIED="1238173515113" TEXT="At least one CIV group"/>
<node CREATED="1238170294358" ID="Freemind_Link_790565463" MODIFIED="1238170299952" TEXT="At least one nbgroup per neighborhood"/>
<node CREATED="1238173516192" ID="Freemind_Link_650706235" MODIFIED="1238173521850" TEXT="At least one nbgroup per CIV group"/>
</node>
<node CREATED="1238173533168" ID="Freemind_Link_476733601" MODIFIED="1238173657909" TEXT="These conditions assume that all neighborhoods must&#xa;have resident civilians.  We might instead want to track&#xa;satisfaction only for neighborhoods that do have &#xa;resident civilians.">
<icon BUILTIN="help"/>
</node>
</node>
<node CREATED="1237478995798" ID="Freemind_Link_1090109606" MODIFIED="1238174388141" POSITION="right" TEXT="sim(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171490835" ID="Freemind_Link_752525374" MODIFIED="1238174386229" TEXT="sim check ?-log?">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171508052" ID="Freemind_Link_1274803095" MODIFIED="1238171514157" TEXT="Performs sanity check"/>
<node CREATED="1238171514692" ID="Freemind_Link_1441734208" MODIFIED="1238171523054" TEXT="Logs results to debugging log"/>
<node CREATED="1238171524308" ID="Freemind_Link_1253796134" MODIFIED="1238171536364" TEXT="Returns a boolean flag."/>
</node>
<node CREATED="1238171567604" ID="Freemind_Link_43310679" MODIFIED="1238174386229" TEXT="SIM:RUN">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171571172" ID="Freemind_Link_1028498519" MODIFIED="1238171579101" TEXT="Calls &quot;sim check -log&quot;"/>
<node CREATED="1238171579732" ID="Freemind_Link_460230865" MODIFIED="1238171599661" TEXT="On failure, rejects order with explanatory message"/>
</node>
</node>
<node CREATED="1238171602644" ID="Freemind_Link_1245358500" MODIFIED="1238174395357" POSITION="right" TEXT="appwin(sim) Changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171612611" ID="Freemind_Link_556644434" MODIFIED="1238171635705" TEXT="Sends SIM:RUN when play button is pressed">
<icon BUILTIN="flag"/>
</node>
<node CREATED="1238171887427" ID="Freemind_Link_1319861674" MODIFIED="1238174395357" TEXT="Displays rejections to user">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238171939475" ID="Freemind_Link_1489528397" MODIFIED="1238174395358" TEXT="Catches errors">
<icon BUILTIN="button_ok"/>
<node CREATED="1238171945810" ID="Freemind_Link_156063273" MODIFIED="1238171972962" TEXT="Should be only rejections; other errors &#xa;are handled by order(sim)"/>
</node>
</node>
</node>
</map>
