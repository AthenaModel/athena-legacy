<map version="0.9.0">
<!--To view this file, download free mind mapping software Freeplane from http://freeplane.sourceforge.net -->
<node ID="ID_1092520834" CREATED="1319468768235" MODIFIED="1319485490663">
<richcontent TYPE="NODE">
<html>
  <head>
    
  </head>
  <body>
    <p style="text-align: center">
      Athena
    </p>
    <p style="text-align: center">
      Packages
    </p>
  </body>
</html></richcontent>
<hook NAME="MapStyle" max_node_width="600"/>
<node TEXT="Assignment of Athena modules to packages" POSITION="right" ID="ID_671368838" CREATED="1319488703848" MODIFIED="1320343669079"/>
<node TEXT="app_sim(n)" POSITION="right" ID="ID_177341292" CREATED="1319488712296" MODIFIED="1320343674503">
<node TEXT="app.tcl" ID="ID_1401521112" CREATED="1319470673659" MODIFIED="1320352301579">
<icon BUILTIN="messagebox_warning"/>
<node TEXT="Define &quot;profile&quot; in shared/" ID="ID_130121631" CREATED="1320352302665" MODIFIED="1320352307909"/>
</node>
<node TEXT="cif.tcl" ID="ID_195287865" CREATED="1319470701082" MODIFIED="1320771152268">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="map.tcl" ID="ID_327822539" CREATED="1320348077045" MODIFIED="1320774991305">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="sim.tcl" ID="ID_1462177396" CREATED="1319471060047" MODIFIED="1320706817971">
<icon BUILTIN="messagebox_warning"/>
<node TEXT="Part stays in ::sim; part goes in ::engine, which manages the engine thread (if any)" ID="ID_468708681" CREATED="1320706731297" MODIFIED="1320706748613"/>
</node>
<node TEXT="sanity.tcl" ID="ID_1940505409" CREATED="1319471001545" MODIFIED="1320706978064">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_ok"/>
<node TEXT="Could be shared, but could also stay right here." ID="ID_25427908" CREATED="1320707050204" MODIFIED="1320707066327"/>
<node TEXT="Requires ::econ, to query economics" ID="ID_1585060733" CREATED="1320707068301" MODIFIED="1320707080991"/>
</node>
<node TEXT="scenario.tcl" ID="ID_1520295791" CREATED="1319471012744" MODIFIED="1320706824633">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="messagebox_warning"/>
<node TEXT="See what needs to go into Engine thread to create and synchronize an RDB" ID="ID_1063967617" CREATED="1320706758722" MODIFIED="1320706797473"/>
</node>
</node>
<node TEXT="app_sim_engine(n)" POSITION="right" ID="ID_1340196419" CREATED="1319488718512" MODIFIED="1320343683710">
<node TEXT="app.tcl" ID="ID_901522405" CREATED="1320348840837" MODIFIED="1320686632854">
<icon BUILTIN="messagebox_warning"/>
<node TEXT="Not written yet." ID="ID_742580044" CREATED="1320348850101" MODIFIED="1320348852856"/>
<node TEXT="Initialize thread" ID="ID_1462087539" CREATED="1320348853252" MODIFIED="1320348855736"/>
<node TEXT="Create mapref(n) called ::map" ID="ID_1882827362" CREATED="1320348856340" MODIFIED="1320348862064"/>
<node TEXT="Keep ::map synchronized with App thread" ID="ID_963312406" CREATED="1320348862429" MODIFIED="1320348871448"/>
</node>
</node>
<node TEXT="app_sim_logger" FOLDED="true" POSITION="right" ID="ID_181832659" CREATED="1320686528476" MODIFIED="1320686544177">
<icon BUILTIN="button_ok"/>
<node TEXT="app.tcl" ID="ID_1077821882" CREATED="1320686533163" MODIFIED="1320686539232">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node TEXT="app_sim_shared(n)" FOLDED="true" POSITION="right" ID="ID_1161190746" CREATED="1319488723504" MODIFIED="1320343688206">
<node TEXT="aam.tcl" ID="ID_1353461592" CREATED="1320343136244" MODIFIED="1320700798317">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="aam_rules.tcl" ID="ID_1414316445" CREATED="1319470638380" MODIFIED="1320700798317">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="activity.tcl" ID="ID_1917067043" CREATED="1320352582226" MODIFIED="1320354228782">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="actsit.tcl" ID="ID_1334339029" CREATED="1319470656475" MODIFIED="1320700819549">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="actsit_rules.tcl" ID="ID_1495154038" CREATED="1319470660571" MODIFIED="1320700819549">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="apptypes.tcl" FOLDED="true" ID="ID_974824307" CREATED="1319476703870" MODIFIED="1320349165856">
<icon BUILTIN="button_ok"/>
<node TEXT="Split out gradients into gradients.tcl" ID="ID_1946706881" CREATED="1320347820109" MODIFIED="1320347847407"/>
<node TEXT="Has dependencies on map.tcl, which requires TK" ID="ID_742944480" CREATED="1320347877524" MODIFIED="1320347963676"/>
</node>
<node TEXT="actor.tcl" ID="ID_1244863738" CREATED="1319470649932" MODIFIED="1320704372227">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="agent.tcl" ID="ID_1576490616" CREATED="1319470669707" MODIFIED="1320424920695">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="bsystem.tcl" ID="ID_1715279619" CREATED="1319470690778" MODIFIED="1320704261115">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="cash.tcl" ID="ID_400912427" CREATED="1319470697362" MODIFIED="1320427188288">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="civgroup.tcl" ID="ID_1752134554" CREATED="1319470703818" MODIFIED="1320704377765">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="coop.tcl" ID="ID_214714688" CREATED="1320437605370" MODIFIED="1320440057942">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="control.tcl" ID="ID_540206610" CREATED="1320430781799" MODIFIED="1320431324156">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="control_model.tcl" ID="ID_235335160" CREATED="1319470770960" MODIFIED="1320686472867">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="control_rules.tcl" ID="ID_1781523192" CREATED="1319470775440" MODIFIED="1320686472867">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="coverage_model.tcl" ID="ID_489249766" CREATED="1319470642412" MODIFIED="1320354179092">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="dam.tcl" ID="ID_386232234" CREATED="1319470786311" MODIFIED="1320701103371">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="demog.tcl" ID="ID_1995352534" CREATED="1319470788639" MODIFIED="1320701103371">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="demsit.tcl" ID="ID_725796703" CREATED="1319470803575" MODIFIED="1320701103371">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="demsit_rules.tcl" ID="ID_393516398" CREATED="1319470806375" MODIFIED="1320701103371">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="econ.tcl" ID="ID_275035199" CREATED="1319470828134" MODIFIED="1320701120781">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="ensit.tcl" ID="ID_1282072362" CREATED="1319470846157" MODIFIED="1320701120781">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="ensit_rules.tcl" ID="ID_1557426074" CREATED="1319470850077" MODIFIED="1320701120781">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="executive.tcl" ID="ID_557878338" CREATED="1319470858725" MODIFIED="1320704360379">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="firings.tcl" ID="ID_684932498" CREATED="1319470862189" MODIFIED="1320706685510">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="frcgroup.tcl" ID="ID_250785277" CREATED="1319470875061" MODIFIED="1320701178712">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="goal.tcl" ID="ID_1979515594" CREATED="1320428518263" MODIFIED="1320428525921">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="group.tcl" ID="ID_1770376450" CREATED="1319470884204" MODIFIED="1320354656838">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="helpers.tcl" ID="ID_272142030" CREATED="1319470885821" MODIFIED="1320424924459">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="hist.tcl" ID="ID_407493952" CREATED="1319470889820" MODIFIED="1320701133355">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="mad.tcl" ID="ID_825033238" CREATED="1319470892588" MODIFIED="1320704261115">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="nbhood.tcl" ID="ID_519656311" CREATED="1319470927907" MODIFIED="1320701183112">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="nbrel.tcl" ID="ID_1686255583" CREATED="1319470938395" MODIFIED="1320702489931">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="nbstat.tcl" ID="ID_1240351914" CREATED="1319476801578" MODIFIED="1320354195424">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="ptype.tcl" FOLDED="true" ID="ID_1344688123" CREATED="1319470987937" MODIFIED="1320358959810">
<icon BUILTIN="button_ok"/>
<node TEXT="::actor names" ID="ID_1901957538" CREATED="1320349207698" MODIFIED="1320351618153">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::activity civ names" ID="ID_1208788373" CREATED="1320349323814" MODIFIED="1320354234072">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::activity frc names" ID="ID_644701709" CREATED="1320349354189" MODIFIED="1320354234072">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::activity org names" ID="ID_1977320141" CREATED="1320349357853" MODIFIED="1320354234071">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::civgroup names" ID="ID_935252676" CREATED="1320349292519" MODIFIED="1320358862624">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::frcgroup names" ID="ID_934438724" CREATED="1320349253384" MODIFIED="1320358862623">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::group names" ID="ID_1996533847" CREATED="1320349278111" MODIFIED="1320354769314">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::nbhood names" ID="ID_715057311" CREATED="1320349235473" MODIFIED="1320358867696">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="::orggroup names" ID="ID_1156699048" CREATED="1320349256056" MODIFIED="1320358867695">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node TEXT="orggroup.tcl" ID="ID_1324976368" CREATED="1319470959026" MODIFIED="1320701190335">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="parm.tcl" ID="ID_1319691546" CREATED="1319470966434" MODIFIED="1320793157040">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="personnel.tcl" ID="ID_570623883" CREATED="1319470971442" MODIFIED="1320428742848">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="rel.tcl" ID="ID_1970726387" CREATED="1320437755241" MODIFIED="1320437760936">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="sat.tcl" ID="ID_822786107" CREATED="1320437631174" MODIFIED="1320440066175">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="security_model.tcl" ID="ID_1051182748" CREATED="1319471016248" MODIFIED="1320354191432">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="service.tcl" ID="ID_1091866852" CREATED="1320434825214" MODIFIED="1320434830185">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="service_rules.tcl" ID="ID_1753205184" CREATED="1319471050015" MODIFIED="1320434820000">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="sigevent.tcl" ID="ID_1399452028" CREATED="1319471055591" MODIFIED="1320427379217">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="situation.tcl" ID="ID_308993344" CREATED="1319471064559" MODIFIED="1320701164079">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="sqdeploy.tcl" ID="ID_701039469" CREATED="1319471067687" MODIFIED="1320437679913">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="sqservice.tcl" ID="ID_378033349" CREATED="1319471079966" MODIFIED="1320437679912">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="strategy.tcl" ID="ID_1377825319" CREATED="1319471091886" MODIFIED="1320701169259">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="unit.tcl" ID="ID_1474375129" CREATED="1320428730115" MODIFIED="1320428735136">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Conditions" FOLDED="true" ID="ID_622153547" CREATED="1319489015214" MODIFIED="1320702525858">
<icon BUILTIN="button_ok"/>
<node TEXT="cond_collection.tcl" ID="ID_1668093197" CREATED="1319470711202" MODIFIED="1320420279356">
<font ITALIC="false"/>
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition.tcl" ID="ID_1830999362" CREATED="1319476717261" MODIFIED="1320420279356">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_after.tcl" ID="ID_780398182" CREATED="1319470716954" MODIFIED="1320420279355">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_at.tcl" ID="ID_957143113" CREATED="1319470721849" MODIFIED="1320428603018">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_before.tcl" ID="ID_644326138" CREATED="1319470727049" MODIFIED="1320420284941">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_cash.tcl" ID="ID_1328437353" CREATED="1319470730385" MODIFIED="1320427530862">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_control.tcl" ID="ID_280814284" CREATED="1319470733649" MODIFIED="1320420289883">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_during.tcl" ID="ID_571261918" CREATED="1319470737409" MODIFIED="1320420289882">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_expr.tcl" ID="ID_1656743385" CREATED="1319470740953" MODIFIED="1320702519977">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_influence.tcl" ID="ID_216662525" CREATED="1319470745001" MODIFIED="1320420294109">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_met.tcl" ID="ID_1125011041" CREATED="1319470749897" MODIFIED="1320428490834">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_mood.tcl" ID="ID_484153659" CREATED="1319470752553" MODIFIED="1320420303484">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_nbcoop.tcl" ID="ID_1593247549" CREATED="1319470755904" MODIFIED="1320420303484">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_nbmood.tcl" ID="ID_396639567" CREATED="1319470759640" MODIFIED="1320420303483">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_troops.tcl" ID="ID_189685041" CREATED="1319470763232" MODIFIED="1320427790043">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="condition_unmet.tcl" ID="ID_1719491777" CREATED="1319470767848" MODIFIED="1320428499233">
<icon BUILTIN="button_ok"/>
</node>
</node>
<node TEXT="Tactics" FOLDED="true" ID="ID_654016174" CREATED="1320343592533" MODIFIED="1320702541482">
<icon BUILTIN="button_ok"/>
<node TEXT="tactic.tcl" ID="ID_664659690" CREATED="1319471100774" MODIFIED="1320424969777">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_assign.tcl" ID="ID_1506953222" CREATED="1319471106029" MODIFIED="1320428611850">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_attroe.tcl" ID="ID_1178408499" CREATED="1319471110781" MODIFIED="1320427237170">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_defroe.tcl" ID="ID_1911107649" CREATED="1319471115709" MODIFIED="1320424504926">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_demob.tcl" ID="ID_188923588" CREATED="1319471119413" MODIFIED="1320427818239">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_deploy.tcl" ID="ID_552852192" CREATED="1319471128725" MODIFIED="1320427818238">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_displace.tcl" ID="ID_287673529" CREATED="1319471133893" MODIFIED="1320427818238">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_executive.tcl" ID="ID_780143970" CREATED="1319471137773" MODIFIED="1320702535850">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_fund.tcl" ID="ID_1960522512" CREATED="1319471142981" MODIFIED="1320427250252">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_fundeni.tcl" ID="ID_55899904" CREATED="1319471145980" MODIFIED="1320434798285">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_mobilize.tcl" ID="ID_1127347092" CREATED="1319471150380" MODIFIED="1320427827750">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_save.tcl" ID="ID_1950230111" CREATED="1319471153876" MODIFIED="1320427258793">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_spend.tcl" ID="ID_731987046" CREATED="1319471157284" MODIFIED="1320427258792">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="tactic_support.tcl" ID="ID_1556316090" CREATED="1319471162028" MODIFIED="1320430802345">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
<node TEXT="app_sim_ui(n)" FOLDED="true" POSITION="right" ID="ID_967605698" CREATED="1320702454565" MODIFIED="1320702834890">
<icon BUILTIN="button_ok"/>
<node TEXT="appwin.tcl" ID="ID_1329202836" CREATED="1319470681347" MODIFIED="1320702618313">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="appserver.tcl" ID="ID_73247680" CREATED="1319476697422" MODIFIED="1320702618313">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="gradient.tcl" ID="ID_140112041" CREATED="1320348765639" MODIFIED="1320702618313">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="mapicon_situation.tcl" ID="ID_1827211593" CREATED="1319470901884" MODIFIED="1320702646721">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="mapicon_unit.tcl" ID="ID_733836075" CREATED="1319470906316" MODIFIED="1320702646721">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="mapicons.tcl" ID="ID_326666021" CREATED="1319470911548" MODIFIED="1320702646721">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="nbchart.tcl" ID="ID_956993100" CREATED="1319470919355" MODIFIED="1320702654419">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="plotviewer.tcl" ID="ID_598270992" CREATED="1319470981202" MODIFIED="1320702654419">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="report.tcl" ID="ID_1036506836" CREATED="1319470998465" MODIFIED="1320706701251">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="toolbutton.tcl" ID="ID_1735133912" CREATED="1319471173092" MODIFIED="1320702618313">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="timechart.tcl" ID="ID_147769786" CREATED="1319471165060" MODIFIED="1320702654419">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="view.tcl" ID="ID_936628291" CREATED="1319471178891" MODIFIED="1320702618313">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="Browsers" FOLDED="true" ID="ID_368376490" CREATED="1319471254753" MODIFIED="1320702731609">
<icon BUILTIN="button_ok"/>
<node TEXT="activitybrowser.tcl" ID="ID_246202276" CREATED="1319470644948" MODIFIED="1320702634116">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="actorbrowser.tcl" ID="ID_903039520" CREATED="1319470652420" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="actsitbrowser.tcl" ID="ID_687239943" CREATED="1319470664187" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="bsystembrowser.tcl" ID="ID_1696705836" CREATED="1319470694034" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="civgroupbrowser.tcl" ID="ID_778767407" CREATED="1319470707842" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="coopbrowser.tcl" ID="ID_634033529" CREATED="1319470782463" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="demogbrowser.tcl" ID="ID_858851291" CREATED="1319470792423" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="demognbrowser.tcl" ID="ID_1079150884" CREATED="1319470796359" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="demsitbrowser.tcl" ID="ID_1876667592" CREATED="1319470809807" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="detailbrowser.tcl" ID="ID_1774361779" CREATED="1319470813326" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="econcapbrowser.tcl" ID="ID_1603543349" CREATED="1319470829766" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="econngbrowser.tcl" ID="ID_1168994237" CREATED="1319470833854" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="econpopbrowser.tcl" ID="ID_84990650" CREATED="1319470838038" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="econsheet.tcl" ID="ID_200104818" CREATED="1319470842093" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="ensitbrowser.tcl" ID="ID_1669582416" CREATED="1319470853677" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="frcgroupbrowser.tcl" ID="ID_666827369" CREATED="1319470867069" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="madbrowser.tcl" ID="ID_1268061326" CREATED="1319471692116" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="mapviewer.tcl" ID="ID_1781341625" CREATED="1319470913588" MODIFIED="1320702646721">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="nbcoopbrowser.tcl" ID="ID_268537284" CREATED="1319470923907" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="nbhoodbrowser.tcl" ID="ID_726664863" CREATED="1319470932490" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="nbrelbrowser.tcl" ID="ID_973836665" CREATED="1319470942339" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="orderbrowser.tcl" ID="ID_72177721" CREATED="1319471704507" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="ordersentbrowser.tcl" ID="ID_1717405157" CREATED="1319470948338" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="orggroupbrowser.tcl" ID="ID_1000832832" CREATED="1319470963314" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="personnelbrowser.tcl" ID="ID_721329207" CREATED="1319470977753" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="relbrowser.tcl" ID="ID_152583249" CREATED="1319470993385" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="satbrowser.tcl" ID="ID_1898662968" CREATED="1319471005713" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="securitybrowser.tcl" ID="ID_1885941424" CREATED="1319471031984" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="sqdeploybrowser.tcl" ID="ID_1880814286" CREATED="1319471074863" MODIFIED="1320702634131">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="sqservicebrowser.tcl" ID="ID_584848854" CREATED="1319471085686" MODIFIED="1320702634116">
<icon BUILTIN="button_ok"/>
</node>
<node TEXT="strategybrowser.tcl" ID="ID_1736704653" CREATED="1319471097038" MODIFIED="1320702634116">
<icon BUILTIN="button_ok"/>
</node>
</node>
</node>
</node>
</map>
