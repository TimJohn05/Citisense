#!/usr/bin/env python3
"""
CitiSense NLP Synthetic Data Generator v2 (11-Category Civic Taxonomy).
Generates diverse, realistic Taglish/English/slang civic complaints
for Calamba City, Laguna based on real community issues.
"""

import csv
import os
import random

CATEGORIES = [
    'waste',
    'road',
    'water',
    'lighting',
    'peace_order',
    'traffic_obstruction',
    'flood_drainage',
    'health_sanitation',
    'electrical_hazard',
    'public_facilities',
    'general_inquiry'
]

SENTIMENTS = ['negative', 'neutral', 'positive']
URGENCIES = ['low', 'moderate', 'emergency']

LOCATIONS = [
    'sa Brgy. Parian',
    'sa Brgy. Canlubang',
    'sa Brgy. Real',
    'sa Brgy. Looc',
    'sa Brgy. Bucal',
    'sa Brgy. Pansol',
    'sa Brgy. Mapagong',
    'sa Brgy. Halang',
    'sa Brgy. Saimsim',
    'sa Brgy. Crossing',
    'sa Brgy. Barandal',
    'sa Brgy. Turbina',
    'sa Brgy. Lawa',
    'sa Brgy. Bagong Kalsada',
    'sa Brgy. San Cristobal',
    'sa Brgy. Makiling',
    'sa Brgy. Batino',
    'sa Brgy. Bubuyan',
    'sa Brgy. Lingga',
    'sa Brgy. Banlic',
    'sa may Purok 4',
    'sa may Purok 6 extension',
    'sa Block 8 Lot 15',
    'sa tapat ng covered court',
    'sa tabi ng chapel',
    'sa may Bucal bypass road',
    'sa tapat ng elementary school',
    'sa may crossing papuntang palengke',
    'sa gilid ng barangay hall',
    'sa may tulay ng San Cristobal',
    'sa tabi ng bakery',
    'sa may Phase 2 subdivision gate',
    'sa tapat ng daycare center',
    'sa kahabaan ng main avenue',
    'sa tapat ng health center',
    'sa may gasoline station',
    'sa tabi ng simbahan',
    'sa harap ng public market',
    'sa may terminal ng jeep',
    'sa likod ng munisipyo',
    'sa tabi ng creek',
    'sa may Calamba-Tagaytay road',
    'sa may national highway',
    'sa may basketball court',
    'sa tapat ng Calamba Medical Center',
]

PREFIXES = [
    'Paki-check naman po,',
    'Good day po kapitan at mga tanod,',
    'Report ko lang po:',
    'Grabe po talaga,',
    'Nais ko lang i-report na',
    'Pakitulungan po kami dito,',
    'Attention po barangay officials,',
    'Magandang araw po,',
    'Hello po admin / desk officer,',
    'Concerned citizen here:',
    'Uy may problema dito,',
    'Paki-action naman po,',
    'Sobrang nakaka-stress na po,',
    'Please lang po,',
    'Gusto ko lang ipaalam na',
    'Hi po, nagrereklamo lang po,',
    'Ayusin nyo naman po to,',
    'Sana po mapansin,',
    'Urgent po ito,',
    'Nagreport na po kami dati pero',
    'FYI lang po sa barangay,',
    'Barangay update:',
    'Good evening po,',
    'Di na po namin kinakaya,',
    'Para sa kapakanan ng lahat,',
    '',
]


TEMPLATES = [
    # ==================== 1. WASTE MANAGEMENT ====================
    {
        'category': 'waste',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Tambak na naman po ang basura {loc}, nangangamoy na at nilalangaw.",
            "Hindi pa rin nahahakot ang mga nabubulok na kalat {loc} simula pa noong isang linggo.",
            "Puno na po at umaapaw ang garbage bin {loc}, kumakalat na ang dumi sa kalsada.",
            "Mabaho at nakaharang sa bangketa ang mga plastic bag ng basura {loc}.",
            "May nagtatapon po ng patapong construction debris at sirang gamit {loc}.",
            "The trash bins are full and stinking na {loc}, please collect na po.",
            "Grabe yung garbage {loc}, puro langaw at daga na ang umiikot.",
            "Ilang araw na pong hindi dinadaan ng garbage truck {loc}, ang baho na.",
            "Nakakalat na po ang basura sa kalsada {loc} kasi walang trash bin.",
            "May nagtapon ng dead animal {loc}, ang baho po at health hazard na.",
            "Overflowing na po yung trash can {loc} at kumakalat sa bangketa.",
            "Maraming basura ang nakakalat {loc} dahil walang regular na collection.",
            "Ang daming nakatambak na plastic at styrofoam {loc}, parang landfill na.",
            "Hindi segregated ang basura na tinitipon {loc}, halo-halo lahat.",
            "May illegal dumping ng hospital waste {loc}, delikado po sa mga bata.",
        ]
    },
    {
        'category': 'waste',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "May nagsisiga po ng goma at plastic {loc}, napakakapal ng maitim na usok at nahihirapan huminga ang mga bata!",
            "Nasusunog ang tambak na basura {loc}, kumakalat na ang apoy sa mga bahay!",
            "May nagtatapon ng toxic chemical waste {loc}, napapaso ang balat ng mga dumadaan!",
        ]
    },
    {
        'category': 'waste',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Maraming salamat po sa mga basurero at tanod, nahakot na po agad ang basura {loc}.",
            "Napakalinis na po ng paligid {loc} pagkatapos ng cleanup drive kaninang umaga!",
            "Thank you po kapitan sa mabilis na pag-aksyon sa tambak na basura sa may street namin.",
            "Maaliwalas at walang amoy na ang paligid {loc}, saludo sa sanitation team.",
            "Na-address na po yung garbage problem {loc}, ang linis na ngayon. Salamat!",
            "Kudos sa barangay waste team, consistent na ang collection schedule {loc}.",
        ]
    },
    {
        'category': 'waste',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Ano po ba ang bagong schedule ng collection ng biodegradable waste {loc}?",
            "Naitanong ko lang po kung pwede mag-request ng dagdag na trash bin {loc}.",
            "Hindi naman marumi pero sana maglagay ng sign na bawal magtapon {loc}.",
            "Kailan po ang susunod na cleanup drive {loc}? Gusto po naming sumali.",
            "May separate collection ba for recyclables and e-waste {loc}?",
            "Paano po mag-report ng illegal dumping {loc}? Sino po tatawagan?",
        ]
    },

    # ==================== 2. ROAD & INFRASTRUCTURE ====================
    {
        'category': 'road',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Malaki po ang lubak {loc}, lalo na kapag umuulan delikado sa motor.",
            "Sira na po ang aspalto at nagka-crack ang kalsada {loc}, nasira ang gulong ng motor ko.",
            "Walang road markings at lane separator {loc}, gulo ng daloy ng traffic.",
            "May aksidente na naman po dahil sa lubak {loc}, sana ayusin na.",
            "Grabe ang potholes {loc}, parang obstacle course na ang kalsada.",
            "The road {loc} is badly damaged, full of cracks and potholes.",
            "Ang hirap dumaan sa kalsada {loc}, baka mag-cause ng accident.",
            "Nasira na po ang drainage cover {loc}, bukas na ang butas sa gitna ng kalsada.",
            "Ang gutter {loc} ay collapsed na, bumabaha pag umuulan.",
            "Yung road shoulder {loc} gumuho na po, delikado sa mga pedestrian.",
            "Hindi pa natapos ang road widening project {loc}, ang hirap dumaan.",
            "Nawawala yung manhole cover {loc}, baka may mahulog na bata.",
        ]
    },
    {
        'category': 'road',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "Bumagsak po ang concrete barrier {loc}, nakaharang sa buong kalsada at may nasagasaan na!",
            "Nawala ang manhole cover {loc} at may nahulog na bata sa drain, tulungan po!",
            "Gumuho ang isang bahagi ng kalsada {loc} dahil sa pagbaha, hindi na madaanan!",
        ]
    },
    {
        'category': 'road',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Salamat sa engineering team, naayos na agad ang sirang gutter at lubak {loc}.",
            "Na-repave na po ang kalsada {loc}, ang ganda at smooth na ulit. Thank you!",
            "Thank you po sa road repair team, naayos na yung potholes {loc}.",
            "Napakaganda ng bagong kalsada {loc}, malinis at may markings na.",
        ]
    },
    {
        'category': 'road',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Nais lang po malaman kung bukas ang daan para sa mga delivery van {loc}.",
            "May road repair schedule po ba ang LGU para sa kalsada {loc}?",
            "Hanggang kailan po ang road closure {loc} dahil sa construction?",
            "Pwede po bang mag-request ng speed bump installation {loc}?",
            "Saan po pwede mag-report ng damaged road {loc} sa city hall?",
        ]
    },

    # ==================== 3. WATER SUPPLY ====================
    {
        'category': 'water',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Matagal ng walang tubig {loc}, pangatlong araw na po!",
            "Maputik at mabaho ang lumalabas sa gripo {loc}, hindi po ito safe inumin.",
            "Napakahina ng pressure ng tubig {loc} lalo na pag tanghali.",
            "May tumatagaktak na putik mula sa gripo {loc}, parang galing sa maruming source.",
            "Kulay brown ang tubig na lumalabas sa faucet {loc}, diko ipapainom sa family ko.",
            "Walang water supply {loc} for 3 days na, sobrang hirap po.",
            "The water {loc} is yellowish and smells bad, we can't use it.",
            "Ang baho ng tubig na lumalabas {loc}, parang may lasang kalawang.",
            "Low water pressure {loc}, halos hindi na tumatakbo ang washing machine.",
            "May toxic foam na nakita sa ilog malapit {loc}, baka contaminated na ang tubig namin.",
            "Pumutok po ang water pipe {loc}, nasasayang ang tubig at bumabaha sa kalsada.",
        ]
    },
    {
        'category': 'water',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "Walang tubig sa buong barangay {loc} simula pa kahapon, may mga sanggol at matatanda dito!",
            "Contaminated na po ang tubig {loc}, maraming nagkakasakit ng tiyan lalo na mga bata!",
            "Pumutok ang malaking water main {loc}, bumabaha at gumuguho ang kalsada!",
        ]
    },
    {
        'category': 'water',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Maayos na po ang supply ng tubig ngayon {loc}, wala nang problema.",
            "Nagawa na po ang tagas sa tubo {loc}, thank you sa water service team!",
            "Bumalik na po ang malinaw na tubig {loc} pagkatapos ng repair. Salamat!",
            "Thank you sa water district, na-fix na ang pipe burst {loc} within hours.",
        ]
    },
    {
        'category': 'water',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "May scheduled water interruption po ba bukas sa aming area {loc}?",
            "Saan po pwede mag-apply ng bagong water connection {loc}?",
            "Magkano po ang reconnection fee ng tubig {loc}?",
            "May advisory ba about water quality {loc}? May kumakalat na chismis.",
            "Kailan po inaayos ang water pipes sa area namin {loc}?",
        ]
    },

    # ==================== 4. STREET LIGHTING ====================
    {
        'category': 'lighting',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Pundido po ang bumbilya ng streetlight {loc}, napakadilim kapag naglalakad sa gabi.",
            "Sira at kumukurap ang ilaw sa poste {loc}, nagdudulot ng takot sa gabi.",
            "Totally dark po ang buong stretch {loc}, delikado lalo na sa mga babae at bata.",
            "Ang daming sirang streetlight {loc}, parang horror movie sa dilim.",
            "The streetlight {loc} has been broken for weeks, it's so dark and scary at night.",
            "Walang ilaw ang mga eskinita {loc}, madilim at delikadong lakaran.",
            "Flickering ang streetlight {loc}, nakakatakot lumabas ng gabi.",
            "Hindi gumagana ang solar streetlight {loc}, wala na yatang baterya.",
            "Sira na po ang ilaw {loc}, nakakaraming holdap at snatcher dahil dilim.",
            "Ang dilim ng kalsada {loc}, halos hindi makita ang mga dumadaan na sasakyan.",
        ]
    },
    {
        'category': 'lighting',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Maliwanag na po ulit ang buong street {loc} dahil napalitan na ang solar light. Salamat po!",
            "Napakaliwanag na ng area namin {loc}, salamat sa LED upgrade!",
            "Thank you sa pag-install ng mga bagong ilaw {loc}, feel safe na kami sa gabi.",
        ]
    },
    {
        'category': 'lighting',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Hindi sira ang ilaw pero natatakpan ng mga sanga ng puno {loc}.",
            "Saan po ba pwede mag-request ng karagdagang streetlight {loc}?",
            "May plan po ba ang barangay na mag-install ng solar lights {loc}?",
            "Sino po ang nag-mamaintain ng mga streetlights {loc}? Meralco po ba?",
        ]
    },

    # ==================== 5. PEACE & ORDER ====================
    {
        'category': 'peace_order',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Sobrang lakas ng videoke at sigawan {loc} kahit lampas 11 PM na, may pasok pa ang mga bata bukas.",
            "Nangungulit at nagwawala po ang lasing {loc}, pakipadala ng tanod bago pa magkasakitan.",
            "May mga nag-iinuman sa kalsada at nag-iingay {loc}, nambabastos ng mga dumadaang babae.",
            "May nagsasabong po ng manok {loc} tuwing linggo, ang ingay at ang dumi.",
            "There are drunk men harassing passersby {loc}, please send tanod immediately.",
            "Ang ingay ng mga tambay {loc} tuwing gabi, natatakot na mga kapitbahay.",
            "May away ng magkakapitbahay {loc}, baka lumala pa at may masaktan.",
            "Laging may nagwawala na lasing {loc}, di na makatulog yung mga residente.",
            "May grupo ng kabataan na nang-hhold up {loc} tuwing gabi, grabe na po.",
            "Ang lakas ng stereo at karaoke {loc}, hindi kami makatulog kahit weeknight.",
            "May nagpapaputok ng baril {loc} tuwing gabi, nakakatakot po!",
            "Suntukan at sigawan sa labas {loc}, parang gulo na po.",
        ]
    },
    {
        'category': 'peace_order',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "May holdaper at may hawak na kutsilyo {loc}, tulong po! May natatakot na mga bata!",
            "May away na may patalim na ginamit {loc}, duguan na ang isa, kailangan ng pulis at ambulansya!",
            "May nagsasaksakan {loc}, paki-tawag agad ang PNP! May mga tao na nagsitakbuhan!",
        ]
    },
    {
        'category': 'peace_order',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Salamat sa mga tanod sa maagang pagpapasara ng videoke at pag-roving kaninang gabi {loc}.",
            "Peaceful na po ang gabi dito {loc} dahil sa consistent na pagroonda. Maraming salamat!",
            "Thank you po sa tanod at pulis, nag-improve ang safety {loc}.",
            "Nagpapasalamat po kami sa barangay patrol, tahimik na po ang gabi {loc}.",
        ]
    },
    {
        'category': 'peace_order',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Ano po ba ang eksaktong curfew hours para sa mga menor de edad dito sa barangay?",
            "May blotter po ba ang barangay para sa noise complaint {loc}?",
            "Paano po mag-file ng reklamo about noise {loc}? Ano ang process?",
            "May schedule po ba ang tanod para sa nightly patrol {loc}?",
        ]
    },

    # ==================== 6. TRAFFIC & OBSTRUCTION ====================
    {
        'category': 'traffic_obstruction',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Nakaharang ang abandonadong van sa tapat ng driveway {loc}, hindi makalabas ang kotse namin.",
            "Inukupa ng sidewalk vendor ang buong daanan ng tao {loc}, napipilitan maglakad sa kalsada.",
            "Nakaharang po ang construction gravel at buhangin sa mismong bangketa {loc}.",
            "May sasakyan na nag-iillegal double parking sa kanto {loc}, nakaharang sa daanan.",
            "Tricycle terminal na ang gitna ng kalsada {loc}, ang hirap dumaan.",
            "The illegally parked vehicles {loc} are blocking the entire road, no one can pass.",
            "Maraming naka-park na kotse {loc}, di makadaan ng maayos ang mga sasakyan dahil sa sobrang traffic.",
            "Puno ng nakaparadang truck ang kalsada {loc}, halos di na makadaan ang ambulansya.",
            "May construction materials na nakakalat sa kalsada {loc}, delikado sa mga nagmomotor.",
            "Nakaharang ang jeepney na nag-aantay ng pasahero {loc}, ang traffic tuloy.",
            "May vendor na nag-display ng paninda sa bangketa {loc}, napipilitan ang mga pedestrian sa kalsada.",
            "Ang daming illegally parked tricycles {loc}, sobrang siksikan na.",
        ]
    },
    {
        'category': 'traffic_obstruction',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "Nakaharang ang naaksidenteng truck {loc}, totally blocked ang daan at hindi makadaan ang emergency vehicles!",
            "May major pile-up {loc}, kailangan ng traffic enforcer at rescue team ASAP!",
        ]
    },
    {
        'category': 'traffic_obstruction',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Na-clear na po ang illegally parked vehicles {loc}, salamat sa traffic enforcers!",
            "Thank you sa pagpapaalis ng mga sidewalk vendors na nakaharang {loc}.",
            "Maayos na ang daloy ng traffic {loc} dahil sa bagong traffic scheme. Salamat!",
        ]
    },
    {
        'category': 'traffic_obstruction',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Nais lang po humingi ng temporary one-side parking permit para sa family event {loc}.",
            "May towing policy po ba ang barangay for illegally parked vehicles {loc}?",
            "Pwede po bang mag-request ng no parking sign {loc}?",
            "May designated parking area po ba para sa mga delivery trucks {loc}?",
        ]
    },

    # ==================== 7. FLOOD & DRAINAGE ====================
    {
        'category': 'flood_drainage',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Barado po ang kanal at estero {loc}, kahit ambon lang ay umaapaw agad ang maruming tubig.",
            "Umapaw po ang maruming tubig sa baradong estero {loc} dahil sa ulan.",
            "Hindi na gumagana ang drainage system {loc}, bumabaha kahit kaunti lang ang ulan.",
            "Puno ng basura ang canal {loc} kaya hindi na umaagos ang tubig.",
            "Ang bilis bumaha {loc} kahit konting ulan lang, barado kasi ang drainage.",
            "The drainage {loc} is completely clogged, even light rain causes flooding.",
            "Itim at mabaho ang tubig na bumabaha {loc}, galing sa baradong kanal.",
            "Hindi nadredredge ang estero {loc}, kaya laging bumabaha tuwing tag-ulan.",
            "May baha pa rin {loc} kahit tumigil na ang ulan, kasi walang labasan ang tubig.",
            "Ang daming nakaharang na basura sa creek {loc}, kaya umapaw.",
            "Yung culvert {loc} barado na po, kaya lumalampas ang tubig sa kalsada.",
        ]
    },
    {
        'category': 'flood_drainage',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "Lagpas tuhod na po ang baha {loc} at pumapasok na sa loob ng mga bahay, kailangan ng rescue/bumbero!",
            "Flash flood {loc} dahil sa quarrying sa Mt. Makiling, kailangan ng immediate evacuation!",
            "Gumuguho na ang pader ng creek {loc} dahil sa lakas ng agos, baka bumagsak sa mga bahay!",
            "Lagpas bewang na ang baha {loc}, may mga stranded na senior citizen at bata, SOS!",
        ]
    },
    {
        'category': 'flood_drainage',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Mabilis humupa ang tubig ngayon {loc} dahil sa bagong drainage pump, salamat kapitan!",
            "Maraming salamat po sa matagumpay na declogging ng mga kanal {loc}, hindi na bumaha nitong bagyo!",
            "Na-dredge na po ang estero {loc}, hindi na bumabaha kahit malakas ang ulan!",
        ]
    },
    {
        'category': 'flood_drainage',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "May schedule po ba ng canal dredging sa area namin {loc}?",
            "Saan po pwede mag-report ng baradong drainage {loc}? Sa CENRO po ba?",
            "May flood map po ba ang barangay para malaman ang mga flood-prone area {loc}?",
            "Kailan po ang susunod na declogging operation {loc}?",
        ]
    },

    # ==================== 8. HEALTH & SANITATION ====================
    {
        'category': 'health_sanitation',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Nangangamoy dumi ng baboy/manok ang hangin {loc}, nakakasulasok sa kapitbahay.",
            "May rabid/nangangagat na stray dog {loc}, pakihuli agad!",
            "Maraming lamok at ipis {loc} dahil sa stagnant water, breeding ground ng dengue.",
            "May nagsisiga ng basura at gulong {loc}, ang kapal ng usok at nakakalason.",
            "The foul smell from the piggery {loc} is unbearable, it's a health hazard.",
            "Ang daming stray cats and dogs {loc}, nakakatakot ang mga bata lumabas.",
            "May open sewer {loc} na mabaho at may langaw, nakakahawa sa mga bata.",
            "Nagsisiga ng plastic at goma {loc}, sobrang makapal ang usok at amoy.",
            "May dead rat sa canal {loc}, puro langaw at baka may leptospirosis.",
            "Walang proper sanitation ang carinderia {loc}, baka may food poisoning.",
            "Ang daming ipis at daga {loc} dahil sa nakatambak na basura.",
        ]
    },
    {
        'category': 'health_sanitation',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "May outbreak ng dengue {loc}, maraming kabataan ang nako-confine sa hospital!",
            "May natagpuang patay na hayop sa water source {loc}, posibleng contaminated na ang supply!",
            "Kumakalat na ang leptospirosis {loc} dahil sa baha, kailangan ng medical team ASAP!",
        ]
    },
    {
        'category': 'health_sanitation',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Salamat sa barangay health workers sa libreng anti-rabies vaccination at fogging {loc}.",
            "Thank you po sa free medical mission {loc}, marami pong natulungan!",
            "Malinis na po ang surroundings {loc} after the sanitation drive. Salamat!",
            "Na-catch na po yung mga stray dogs {loc}, salamat sa animal control.",
        ]
    },
    {
        'category': 'health_sanitation',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "May schedule po ba ng libreng dengue misting o fogging operation {loc}?",
            "Saan po pwede magpa-anti-rabies vaccine ng aso namin {loc}?",
            "May free check-up po ba sa health center {loc} this week?",
            "Paano po mag-report ng unsanitary business establishment {loc}?",
        ]
    },

    # ==================== 9. ELECTRICAL HAZARD ====================
    {
        'category': 'electrical_hazard',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "May nakalaylay at nakalantad na live wire {loc}, sumasagi sa mga bubong at trucks delikado!",
            "May transformer na umuusok at may sparks ng apoy sa poste {loc}, tawagan agad ang bumbero at Meralco!",
            "Live wire na nahulog sa kalsada {loc} pagkatapos ng bagyo, nakakatay ng tao!",
            "Sumasabog ang transformer {loc}, may apoy na at kumakalat sa mga bahay!",
            "Exposed live wire hanging low {loc}, it's sparking and very dangerous!",
            "May live wire na nakalawit malapit sa paaralan {loc}, baka may ma-electrocute na bata!",
        ]
    },
    {
        'category': 'electrical_hazard',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "May jumper/illegal connection {loc}, parang lumalaki na kaya delikadong mag-short circuit anytime.",
            "Sirang poste ng kuryente {loc}, nakahilig at baka bumagsak anytime.",
            "Exposed wiring sa street light post {loc}, baka may ma-kuryente na bata.",
            "Yung mga wire sa poste {loc} nagsasalabat na, mukhang delikado.",
            "May butas yung junction box ng kuryente {loc}, kita na yung mga wire sa loob.",
        ]
    },
    {
        'category': 'electrical_hazard',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Naayos na po ng Meralco ang nakalawit na wire {loc}, safe na ulit. Salamat!",
            "Na-replace na ang sirang transformer {loc}, bumalik na ang kuryente. Thank you!",
        ]
    },
    {
        'category': 'electrical_hazard',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Nais lang po mag-request ng tree trimming malapit sa linya ng kuryente {loc}.",
            "Paano po mag-report ng exposed wiring sa Meralco {loc}?",
            "May inspection po ba ang Meralco for illegal connections {loc}?",
        ]
    },

    # ==================== 10. PUBLIC FACILITIES ====================
    {
        'category': 'public_facilities',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Sira po ang ring at may butas ang bubong ng covered court {loc}, hindi magamit kapag umuulan.",
            "Ang dumi at sira na ng public CR {loc}, walang tubig at nakakatakot pumasok.",
            "Sirang-sira na ang mga swing at slide sa playground {loc}, delikado para sa mga bata.",
            "Ang basketball court {loc} puno ng bitak at lubak, nata-trip ang mga naglalaro.",
            "The public restroom {loc} is filthy and has no running water, needs maintenance.",
            "Walang gumagana na ilaw sa covered court {loc}, hindi magamit sa gabi.",
            "Vandalized na ang mga benches at signage {loc}, sana ayusin.",
            "Sira ang gate ng playground {loc}, nakakpasok ang mga stray dogs.",
            "Ang community center {loc} ay need na ng repair, tulo ang bubong.",
            "Walang tubig ang public faucet/drinking fountain {loc}, sira na yata.",
        ]
    },
    {
        'category': 'public_facilities',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "Bumagsak ang kisame ng covered court {loc} habang may event, may mga natamaan!",
            "Gumuho ang bahagi ng public market {loc}, may mga tao sa loob!",
        ]
    },
    {
        'category': 'public_facilities',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Maganda ang bagong renovated basketball court {loc}, maraming salamat kapitan!",
            "Salamat po sa pag-ayos ng CR at covered court {loc}, maganda na ulit!",
            "Thank you sa bagong playground equipment {loc}, masaya na ang mga bata!",
            "Ang ganda ng new paint at repair ng barangay hall {loc}, professional tingnan.",
        ]
    },
    {
        'category': 'public_facilities',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Pwede po bang mag-request ng CCTV installation {loc}?",
            "May WiFi po ba ang covered court {loc} para sa mga student?",
            "Saan po pwede mag-reserve ng covered court {loc} para sa event?",
            "May plan po ba ang barangay na magtayo ng mini library {loc}?",
        ]
    },

    # ==================== 11. GENERAL INQUIRIES & SERVICES ====================
    {
        'category': 'general_inquiry',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Ano po ang mga kailangang dalhin para kumuha ng Barangay Clearance at Indigency certificate?",
            "Bukas po ba ang barangay hall bukas ng Sabado para sa pag-claim ng senior citizen pension?",
            "Magkano po ang bayad sa pagkuha ng barangay business permit para sa sari-sari store?",
            "Ano po ang contact number ng duty officer ngayong gabi kung sakaling may emergency?",
            "What are the requirements for getting a barangay clearance?",
            "Ano po ba ang office hours ng barangay hall?",
            "Paano po mag-register sa barangay para sa voter's ID?",
            "Saan po pwede mag-avail ng barangay health services?",
            "May schedule po ba ng free legal consultation sa barangay?",
            "Kailan po ang susunod na barangay assembly meeting?",
            "How do I file a complaint with the barangay?",
            "Ano po ang number ng CDRRMO hotline ng Calamba?",
            "Pwede po bang mag-request ng barangay certificate for employment?",
        ]
    },
    {
        'category': 'general_inquiry',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Napakabilis at napaka-accommodating ng mga staff kanina sa pag-issue ng aking clearance, thank you po!",
            "Salamat sa malinaw at maayos na orientation sa mga bagong residente ng barangay.",
            "Very helpful po ang staff sa barangay hall, mabilis ang process. Salamat!",
            "Thank you po sa efficient processing ng barangay clearance, less than 30 minutes lang!",
            "Kudos to the barangay staff for being so accommodating and friendly!",
        ]
    },
]


AUGMENTATION_FILLERS = ['po', 'naman', 'talaga', 'grabe', 'sobra', 'na', 'pa']
AUGMENTATION_TYPOS = {
    'ang': ['ang', 'ang', 'ang'],
    'po': ['po', 'p0', 'po'],
    'sa': ['sa', 'sa', 'sa'],
    'na': ['na', 'na', 'na'],
    'ng': ['ng', 'ng', 'ng'],
}


# Extra diverse templates (v3) to broaden real-world vocabulary coverage.
# These use natural phrasing + vocabulary seen in genuinely new Taglish reports
# (e.g. "pundido", "streetlight", "Maharlika", "potholes", "dumpsite").
EXTRA_TEMPLATES = [
    # WASTE (vocab: dumpsite, landfill, recycle, hauler, feste, basurahan)
    {'category': 'waste', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "May programa po ba kayo para sa pagre-recycle ng plastic dito sa barangay?",
        "Paano po mag-apply ng dagdag na basurahan para sa aming purok?",
        "Saan po itinatapon ang mga lumang gamit at appliances? May e-waste drive po ba?",
        "Ano po ang schedule ng hauler ng basura sa aming lugar?",
        "Magkano po ang bayad para sa koleksyon ng malalaking basura o furniture?",
    ]},
    {'category': 'waste', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "May nagsasagawa ng illegal dumpsite sa bakanteng lote, ang tagal na pong nag-ipon ng basura.",
        "Sinunog po ng kapitbahay ang tambak ng dahon at basura, makapal ang usok at mabaho sa paligid.",
        "Hindi dumadating ang basurero sa schedule, dalawang linggo na pong nakapila ang basura sa tapat ng bahay.",
        "Ang daming basura na nakakalat sa ilog at sapa, nakabara po at nagdudulot ng baha.",
        "May nagtapon ng malaking basura sa tabi ng daan, nakakaharang at pangit tingnan.",
    ]},
    {'category': 'waste', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Salamat po at napalitan na ang basurahan sa plaza, maayos at malinis na po.",
        "Ang galing ng cleanup drive kahapon, naalis lahat ng basura sa ilog at kalsada.",
        "Magaling po ang bagong schedule ng basura, on time na dumadating ang hauler.",
    ]},

    # ROAD (vocab: Maharlika, potholes, bangketa, speed bump, lubak, subdibisyon)
    {'category': 'road', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "Kailan po ba matatapos ang repair ng kalsada sa may subdibisyon? Mahaba na ang pila ng sasakyan.",
        "Pwede po bang mag-request ng speed bump malapit sa school dahil mabilis magpatakbo ang mga sasakyan?",
        "May schedule po ba ang LGU para sa re-block ng sira-sirang kalsada sa baryo?",
        "Magkano po ang bayad kung magpapagawa ng bangketa sa harap ng bahay?",
        "Sinong opisina po ang sumasagot sa reklamo tungkol sa lubak sa pangunahing daan?",
    ]},
    {'category': 'road', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "Malalim na pothole po sa may Maharlika Highway, bumubulusok ang mga sasakyan at delikado sa motorsiklo.",
        "Gumuhong kalsada po sa loob ng subdivision, hindi na madaan ng bisikleta at kotse.",
        "Sirang bangketa po sa harap ng paaralan, talagang madatnan at pwedeng matumba ang matatanda.",
        "Nawawala ang road sign at mga marker, tila gulo na po ang daloy ng trapiko doon.",
        "Ang daming cracks at bitak sa daan, pano na lang pag umulan, lalo pang gumanda ang lubak.",
        "May nagba-barikada sa kalsada ng hindi nagpapaalam dahil sa construction, mabilis po sana.",
    ]},
    {'category': 'road', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Salamat po at naayos na ang nahukay na daan, maayos na ulit ang daanan sa aming baryo.",
        "Ang ganda ng bagong aspalto at markings, ligtas na po ang mga nagtitinda sa bangketa.",
        "Na-repave na po ang access road sa amin, salamat at hindi na maputik tuwing umuulan.",
    ]},

    # WATER (vocab: CWD, gripo, presyon, interruption, tagas)
    {'category': 'water', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "May advisory po ba ang CWD tungkol sa water interruption sa aming lugar bukas?",
        "Saan po sumusuring magreklamo ng mataas na singil sa tubig? Sa opisina ng CWD po ba?",
        "Magkano po ang bayad sa bagong water connection para sa bagong bahay?",
        "Kailan po ang maintenance ng mga tubo dito sa amin? May nakaraan na pong anunsyo?",
    ]},
    {'category': 'water', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "Sayang po ang malakas na tagas sa tubo sa tapat ng bahay namin, umaagos araw at gabi.",
        "Mababa na naman po ang presyon ng tubig tuwing umaga, halos pumapatak na lang.",
        "Malagkit at madilaw po ang tubig na lumalabas sa gripo, ayaw ko pong inumin ng pamilya ko.",
        "May lasa po na kalawang ang tubig ngayon, nakakapagtaka kung safe pa bang inumin.",
        "Bigla pong nawalan ng supply ng tubig ngayon walang abiso, may kasamang toilet na hindi magamit.",
    ]},
    {'category': 'water', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Salamat po at agad na inayos ng CWD ang tagas, naibalik na ang malinaw na daloy ng tubig.",
        "Maayos na po muli ang daloy ng tubig ngayon, salamat at na-store namin ngayon para sa tag-araw.",
    ]},

    # LIGHTING (vocab: pundido, streetlight, ilaw, eskinita, kanto)
    {'category': 'lighting', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "Sino po ba ang maintenance ng mga streetlight? Meralco po ba o barangay?",
        "May plano po ba na maglagay ng bagong ilaw sa madilim na daanan papuntang palengke?",
        "Paano po makahingi ng bagong poste o ilaw sa aming eskinita?",
    ]},
    {'category': 'lighting', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "Pundido na naman po ang ilaw sa kanto ng aming looban, nakakatakot na umuwi ng gabi.",
        "Ang dilim sa daanan papuntang paaralan, takot pong maglakad ang mga bata at baka ma-aksidente.",
        "Kumikislap-kislap po ang poste ng ilaw sa may tindahan, tila maluwag ang koneksyon at delikado.",
        "Mahina at madilaw po ang liwanag ng bagong streetlight, parang walang silbi sa gabi.",
    ]},
    {'category': 'lighting', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Maliwanag na po ulit ang buong daan dahil sa bagong ilaw, mas ligtas na maglakad sa gabi.",
        "Nakakaengganyo pong lumabas ng bahay ngayon dahil maliwanag na ang kalsada, salamat.",
    ]},

    # PEACE & ORDER (vocab: videoke, tanod, lasing, patrulya, ingay)
    {'category': 'peace_order', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "Ano po ang curfew hours para sa mga menor de edad sa barangay natin?",
        "May patrulya po ba tuwing gabi sa aming lugar? Anong oras karaniwang dumadaan?",
        "Paano po mag-file ng tulong para sa magulong kapitbahay na paulit-ulit?",
    ]},
    {'category': 'peace_order', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "May nag-iinuman po at nag-iingay sa tapat ng bahay namin, may bumubulyaw pa sa mga dumadaan.",
        "Napakalakas po ng videoke ng kapitbahay kahit weeknight, nakakaistorbo sa pamilya ko.",
        "May lasing pong nagwawala sa kanto, paki-tingnan at pakiusapan na umuwi na.",
        "Mayaway-away po ang mga tambay dito tuwing gabi, natatakot na pong lumabas ang mga bata.",
    ]},
    {'category': 'peace_order', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Payapa na po ngayon ang aming lugar dahil sa masipag na mga tanod at patrulya.",
        "Salamat po sa mabilis na pagtugon ng tanod sa ingay na reklamo namin kagabi, tahimik na po.",
    ]},

    # TRAFFIC OBSTRUCTION (vocab: parking, vendor, truck, terminal, lane)
    {'category': 'traffic_obstruction', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "May designated parking po ba para sa mga truck at delivery van sa may palengke?",
        "Pwede po bang mag-request ng no parking sign sa harap ng gate ng subdivision?",
        "May traffic scheme po ba kapag may pista at maraming sasakyan ang pumupunta?",
    ]},
    {'category': 'traffic_obstruction', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "May naka-park po na malaking truck sa makitid na daan, hindi makadaan ang ibang sasakyan at jeep.",
        "Nakaharang po ang vendor sa pedestrian lane, napipilitan maglakad sa kalsada ang mga tao.",
        "Matinding traffic po dahil may na-stall na sasakyan sa gitna ng kanto, walang nagta-traffic.",
        "May nakaparadang sasakyan na lumampas sa linya, barado na po ang daanan papasok sa eskinita.",
    ]},
    {'category': 'traffic_obstruction', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Maayos na po ang daloy ng trapiko ngayon, salamat at inilipat ang mga vendor sa tamang lugar.",
        "Salamat sa traffic enforcer, mabilis na po dumaan ang mga sasakyan sa may crossing.",
    ]},

    # FLOOD / DRAINAGE (vocab: kanal, estero, baha, drainage, dredging)
    {'category': 'flood_drainage', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "May schedule po ba ng pagdredge sa kanal at estero dito sa baryo?",
        "Saan po mag-uulat ng baradong drainage na nagdudulot ng baha? Sa CENRO po ba?",
        "May flood-prone area po ba sa lugar natin na dapat bantayan tuwing bagyo?",
    ]},
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "Bumabaha po kahit bahagyang ulan sa may aming baryo, parang lumalala na taon-taon ang baha.",
        "Barado po ang kanal sa tapat ng bahay, umaapaw ang maruming tubig kapag maulan.",
        "Umapaw po ang estero dahil sa nakabara na basura, mabaho at hindi madaraanan.",
        "May stagnant water po sa may pinaggagawa ng drainage, pugad po ng lamok at sakit.",
    ]},
    {'category': 'flood_drainage', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Salamat at mabilis na humupa ang baha ngayon dahil sa bagong drainage na ginawa.",
        "Maayos na po ang daloy ng kanal ngayon, hindi na umaapaw ang maruming tubig dito.",
    ]},

    # HEALTH / SANITATION (vocab: lamok, paksiw, basura, alagang, disorder)
    {'category': 'health_sanitation', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "May libreng bakuna po ba ngayong linggo sa health center natin?",
        "Saan po magpapa-fogging para maiwasan ang dengue sa aming lugar?",
        "Paano po mag-report ng maruming establishment na maaaring kaagapay ng sakit?",
    ]},
    {'category': 'health_sanitation', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "Maraming lamok po dahil sa stagnant na tubig sa paligid, takot po kami sa dengue.",
        "Mabaho at maraming daga po sa palengke, tila hindi maayos ang sanitation doon.",
        "May nagsisiga po ng basura at plastik na nagdudulot ng makapal na usok at sakit sa baga.",
        "May patay na alagang nakaiwan po sa kalye na nabulok na, nakakatakot at nakakatay ng sakit.",
        "Ang daming stray na aso at pusa, may nakagat na bata at inaalala naming may rabies.",
    ]},
    {'category': 'health_sanitation', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Malinis at maayos na po ang health center ngayon, komportable pong pumila ang mga pasyente.",
        "Salamat po sa libreng medical mission, maraming kabataan at matanda ang natulungan.",
    ]},

    # ELECTRICAL HAZARD (vocab: wire, transformer, poste, spark, brownout)
    {'category': 'electrical_hazard', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "Paano po mag-report ng maluwag na wire sa poste sa Meralco?",
        "May schedule po ba ng tree trimming malapit sa linya ng kuryente dito?",
        "Kailan po ba maiinspeksyon ang mga lumang poste na wala nang silbi sa baryo?",
    ]},
    {'category': 'electrical_hazard', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "May nakalantad na wire po na sumasagi sa bubong, nakakatakot pong may ma-kuryente.",
        "Sumasabog-sparks po ang poste ng transformer sa may palengke, delikado po sa mga tao.",
        "Palaging may brownout po sa aming purok, nakakasira ng appliances at TV namin.",
        "May amoy sunog po galing sa poste malapit sa amin, tila may short circuit na nangyayari.",
    ]},
    {'category': 'electrical_hazard', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Salamat po at inayos ng Meralco ang nakasabit na wire, mukhang ligtas na po ulit.",
        "Na-replace na po ang sirang transformer, tuluy-tuloy na ang kuryente sa baryo namin.",
    ]},

    # PUBLIC FACILITIES (vocab: covered court, playground, palikuran, bench, fountain)
    {'category': 'public_facilities', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "Pwede po bang mag-reserve ng covered court para sa aming family reunion?",
        "May plan po ba na mag-refurbish ng playground at palikuran ng barangay?",
        "Sino po ang namamahala sa maintenance ng mga public facilities natin?",
    ]},
    {'category': 'public_facilities', 'sentiment': 'negative', 'urgency': 'moderate', 'texts': [
        "Sira po ang upuan at ilaw sa covered court, hindi maayos gamitin para sa mga event.",
        "Malapit nang matumba ang swing sa playground, delikado po para sa maliliit na bata.",
        "Marumi at sira na po ang palikuran sa palengke, walang tubig at kawawa ang mga tao.",
        "Di gumagana ang water fountain sa plaza, nasasayang po ang laman kaya walang mapainom ang mga bata.",
        "Vandalized po ang mga bench at sign, pangit tingnan at kailangan nang ayusin.",
    ]},
    {'category': 'public_facilities', 'sentiment': 'positive', 'urgency': 'low', 'texts': [
        "Salamat po at inayos na ang playgroud at parke, masaya na namang maglaro ang mga bata.",
        "Maganda at malinis na po ang bagong bahagi ng barangay hall, komportable na pumila.",
    ]},

    # GENERAL INQUIRY (vocab: clearance, certificate, opisa, ayuda, dokumento)
    {'category': 'general_inquiry', 'sentiment': 'neutral', 'urgency': 'low', 'texts': [
        "Anong araw at oras po bukas ang opisina ng barangay para sa pagkuha ng clearance?",
        "Magkano po ang makeup para sa certificate of residency o indigency?",
        "Ilang araw po bago makuha ang barangay clearance matapos magbayad?",
        "Paano po mag-apply para sa cash assistance o ayuda ng barangay?",
        "Ano pong dokumento ang kailangan para sa online na reklamo o katanungan?",
        "May process po ba para sa lost ID at replacement? Saan po ako pupunta?",
    ]},
]


def augment_text(text):
    words = text.split()
    if len(words) < 5:
        return text

    augmented = words[:]
    r = random.random()

    if r < 0.3:
        insert_pos = random.randint(1, len(augmented) - 1)
        filler = random.choice(AUGMENTATION_FILLERS)
        augmented.insert(insert_pos, filler)
    elif r < 0.5:
        if len(augmented) > 6:
            drop_pos = random.randint(1, len(augmented) - 2)
            if augmented[drop_pos].lower() not in ['ang', 'ng', 'sa', 'po']:
                augmented.pop(drop_pos)
    elif r < 0.65:
        swap_pos = random.randint(0, len(augmented) - 2)
        augmented[swap_pos], augmented[swap_pos + 1] = augmented[swap_pos + 1], augmented[swap_pos]

    return " ".join(augmented)


def generate_dataset(target_count=3000, output_file='dataset/citisense_civic_nlp.csv'):
    seed = int(os.environ.get('CITISENSE_NLP_SEED', '42'))
    random.seed(seed)
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    rows = []
    seen_texts = set()
    print(f"Generating diverse 11-category NLP dataset ({target_count} samples)...")

    attempts = 0
    max_attempts = target_count * 20

    all_templates = TEMPLATES + EXTRA_TEMPLATES

    while len(rows) < target_count and attempts < max_attempts:
        attempts += 1
        tpl_index = random.randrange(len(all_templates))
        tpl_group = all_templates[tpl_index]
        loc = random.choice(LOCATIONS)
        prefix = random.choice(PREFIXES)
        base_text = random.choice(tpl_group['texts']).format(loc=loc)

        full_text = f"{prefix} {base_text}".strip()
        full_text = " ".join(full_text.split())

        if random.random() < 0.4:
            full_text = augment_text(full_text)

        if full_text not in seen_texts:
            seen_texts.add(full_text)
            rows.append({
                'text': full_text,
                'source_id': f'template_{tpl_index}',
                'category': tpl_group['category'],
                'sentiment': tpl_group['sentiment'],
                'urgency': tpl_group['urgency']
            })

    random.shuffle(rows)

    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(
            f,
            fieldnames=['text', 'source_id', 'category', 'sentiment', 'urgency'],
            lineterminator='\n',
        )
        writer.writeheader()
        writer.writerows(rows)

    cat_counts = {}
    for r in rows:
        cat_counts[r['category']] = cat_counts.get(r['category'], 0) + 1

    print(f"\nSuccessfully generated {len(rows)} samples across {len(CATEGORIES)} civic categories.")
    print(f"Saved dataset to {output_file}")
    print("\nCategory distribution:")
    for cat in sorted(cat_counts.keys()):
        print(f"  {cat}: {cat_counts[cat]}")


if __name__ == '__main__':
    generate_dataset(target_count=25000)
