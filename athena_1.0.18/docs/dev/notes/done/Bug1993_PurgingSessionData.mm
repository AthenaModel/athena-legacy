<map version="0.8.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1238773465938" ID="Freemind_Link_1081743270" MODIFIED="1238773486590" TEXT="Purging Session Data">
<node CREATED="1238773796340" ID="Freemind_Link_1195416061" MODIFIED="1238774710311" POSITION="right" TEXT="Concept">
<icon BUILTIN="flag"/>
<node CREATED="1238773503428" ID="_" MODIFIED="1238773530798" TEXT="Session defined">
<node CREATED="1238773516723" ID="Freemind_Link_634905701" MODIFIED="1238773548382" TEXT="Created when Athena is invoked"/>
<node CREATED="1238773591347" ID="Freemind_Link_1626646897" MODIFIED="1238773670349" TEXT="~/.athena/&lt;pid&gt;/..."/>
<node CREATED="1238773548836" ID="Freemind_Link_814150636" MODIFIED="1238773553710" TEXT="Contains working data">
<node CREATED="1238773553988" ID="Freemind_Link_267213790" MODIFIED="1238773556302" TEXT="RDB"/>
<node CREATED="1238773557124" ID="Freemind_Link_1110751735" MODIFIED="1238773558382" TEXT="Logs"/>
</node>
</node>
<node CREATED="1237479159342" ID="Freemind_Link_978533443" MODIFIED="1238773834334" TEXT="At present, the session is deleted on exit">
<node CREATED="1238773840722" ID="Freemind_Link_1891692293" MODIFIED="1238773858302" TEXT="Except for Control-C"/>
<node CREATED="1238773872931" ID="Freemind_Link_1484702799" MODIFIED="1238773891757" TEXT="Makes post-mortems difficult"/>
<node CREATED="1238773937795" ID="Freemind_Link_758110641" MODIFIED="1238773943501" TEXT="Undeleted sessions accumulate"/>
</node>
<node CREATED="1237479168366" ID="Freemind_Link_28557513" MODIFIED="1238773972061" TEXT="Should not delete sessions on exit"/>
<node CREATED="1237479186254" ID="Freemind_Link_1095851202" MODIFIED="1237479202138" TEXT="Should purge older sessions">
<node CREATED="1237479203454" ID="Freemind_Link_369530055" MODIFIED="1238773992285" TEXT="workdir(n) writes a timestamp file to session periodically"/>
<node CREATED="1237479218718" ID="Freemind_Link_65984085" MODIFIED="1238774132156" TEXT="At startup, app(sim) asks workdir(n) to delete old sessions"/>
<node CREATED="1238774084691" ID="Freemind_Link_141001743" MODIFIED="1238774106812" TEXT="Probably want an app parmset for preferences like this"/>
</node>
</node>
<node CREATED="1238774147906" ID="Freemind_Link_77019026" MODIFIED="1238781010355" POSITION="right" TEXT="workdir(n) changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238774166563" ID="Freemind_Link_920312791" MODIFIED="1238779905589" TEXT="Touches work directory once every 10 seconds using [file mtime]">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238779831048" ID="Freemind_Link_1067526789" MODIFIED="1238779905590" TEXT="Sessions are considered &quot;inactive&quot; when their&#xa;[file mtime] is more than ten minutes.">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238774182963" ID="Freemind_Link_301498328" MODIFIED="1238779905590" TEXT="On request, purges inactive sessions older than X hours">
<icon BUILTIN="button_ok"/>
<node CREATED="1238779884423" ID="Freemind_Link_1673946815" MODIFIED="1238779891633" TEXT="X may be zero; deletes all inactive sessions"/>
</node>
<node CREATED="1238776270094" ID="Freemind_Link_254328164" MODIFIED="1238781010356" TEXT="workdir(n) man page">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node CREATED="1238774598113" ID="Freemind_Link_1960782731" MODIFIED="1238779911597" POSITION="right" TEXT="app(sim) changes">
<icon BUILTIN="button_ok"/>
<node CREATED="1238774609073" ID="Freemind_Link_865984231" MODIFIED="1238779909381" TEXT="At start-up, purges old sessions">
<icon BUILTIN="button_ok"/>
</node>
<node CREATED="1238774632210" ID="Freemind_Link_1420207289" MODIFIED="1238779909382" TEXT="Time limit is a module variable for now">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</map>
