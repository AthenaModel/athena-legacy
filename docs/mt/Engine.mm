<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node TEXT="Engine" ID="ID_560855709" CREATED="1320853765753" MODIFIED="1320853768108">
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="lives in shared/" POSITION="right" ID="ID_623477076" CREATED="1320853794520" MODIFIED="1320853797244"/>
<node TEXT="master/slave architecture" POSITION="right" ID="ID_91705813" CREATED="1320853787632" MODIFIED="1320853793820"/>
<node TEXT="As slave, initializes the models and invokes them at relevant points in time." POSITION="right" ID="ID_779711174" CREATED="1320853799024" MODIFIED="1320853832995"/>
<node TEXT="As master, creates the Engine thread, which creates the engine in slave mode" POSITION="right" ID="ID_1303745102" CREATED="1320853833463" MODIFIED="1320853900753"/>
<node TEXT="Thus, in threaded mode the master runs in App and the slave in Engine." POSITION="right" ID="ID_244324003" CREATED="1320853872886" MODIFIED="1320853906088"/>
<node TEXT="In unthreaded mode, the slave runs in App." POSITION="right" ID="ID_1786562605" CREATED="1320853909140" MODIFIED="1320853919832"/>
<node TEXT="The master creates warts in App for important modules in Engine, e.g., ::aram" POSITION="right" ID="ID_174405214" CREATED="1320854094135" MODIFIED="1320854122729"/>
<node TEXT="Warts" POSITION="right" ID="ID_1962629752" CREATED="1320853981650" MODIFIED="1320853982894">
<node TEXT="A wart is a command in App that accesses a command of the same name in another thread." ID="ID_462622511" CREATED="1320853983490" MODIFIED="1320854002309"/>
<node TEXT="Every subcommand passed to the wart is immediately forwarded synchronously to the command in the other thread." ID="ID_933788284" CREATED="1320854010889" MODIFIED="1320854034468"/>
<node TEXT="This allows a rule set running in App to update GRAM in Engine, e.g., if ATTRIT:GROUP is used while paused." ID="ID_1212232242" CREATED="1320854036848" MODIFIED="1320854075019"/>
<node TEXT="A wart can be defined by a very simple proc." ID="ID_35418655" CREATED="1320854079015" MODIFIED="1320854173724"/>
</node>
</node>
</map>
