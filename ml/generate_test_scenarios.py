#!/usr/bin/env python3
"""
Generate 100 test scenarios for CitiSense NLP model testing.

Output: tests/test_scenarios.csv
Columns: text,category,sentiment,urgency

These are hand-written Taglish civic scenarios (not used for training) covering
all 11 categories, all sentiments, and all urgencies. They are fed to the
trained Keras models by test_nlp.py to measure prediction accuracy.
"""

import csv
import os

OUT_PATH = os.path.join(os.path.dirname(__file__), 'test_scenarios.csv')

# (text, category, sentiment, urgency)
SCENARIOS = [
    # --- waste ---
    ("Ilang araw na pong hindi dinadaan ng garbage truck dito sa Barangay Mapagong, sobrang baho na ng basura.", "waste", "negative", "moderate"),
    ("May nagtatapon ng basura sa vacant lot malapit sa amin, nakaka-amoy po ng masangsang.", "waste", "negative", "moderate"),
    ("Salamat po, na-ayos na ang koleksyon ng basura dito sa aming lugar, malinis na po.", "waste", "positive", "low"),
    ("Nasusunog po ang tambak ng basura sa Canlubang, matindi po ang usok!", "waste", "negative", "emergency"),
    ("Sana po dumalaw ang garbage truck ngayong linggo para sa mga naiwang basura.", "waste", "neutral", "low"),
    ("May illegal na dumpsite po ba na dapat ireport dito sa Halang?", "waste", "neutral", "low"),
    ("Ang dami po ng basurang nakakalat sa kalsada dahil sa bagyo kagabi.", "waste", "negative", "moderate"),
    ("Paki-tingnan po ang barangay landfill, tila puno na po at umaapaw na.", "waste", "negative", "moderate"),
    ("Maganda po ang bagong basurahan na nilagay sa plaza, salamat po!", "waste", "positive", "low"),

    # --- road ---
    ("May malaking lubak po sa Maharlika Highway papuntang Real, delikado po sa mga motorsiklo.", "road", "negative", "moderate"),
    ("Salamat po at naayos na ang nasirang kalsada dito sa may crossing, ligtas na po.", "road", "positive", "low"),
    ("Kailan po ba ipapaayos ang nasirang aspalto sa Purok 3? Matagal na pong sira.", "road", "neutral", "low"),
    ("Nasira po ang kalsada dahil sa malakas na ulan, hindi na po ito madaraanan.", "road", "negative", "emergency"),
    ("May ginagawang kalsada po dito, paki-siguraduhan na ligtas para sa mga dumadaan.", "road", "neutral", "low"),
    ("Napakalakas po ng ingay mula sa construction ng kalsada kahit gabi na.", "road", "negative", "low"),
    ("Pakilibre po ang drainage sa kalsada dahil bumabaha na po tuwing umuulan.", "road", "negative", "moderate"),
    ("Maayos po ang bagong kalsada sa Barangay Bucal, masarap na po maglakad.", "road", "positive", "low"),

    # --- water ---
    ("Ilang araw na po kaming walang tubig dito sa may elevated na purok, paki-aksyunan naman po.", "water", "negative", "moderate"),
    ("May tulo po ang main water pipe sa tapat ng bahay namin, sayang po ang tubig.", "water", "negative", "moderate"),
    ("Salamat po at naibalik na ang supply ng tubig dito sa Barangay Barandal.", "water", "positive", "low"),
    ("Bukas na po ba ang opisina ng CWD para sa reklamo sa mataas na singil sa tubig?", "water", "neutral", "low"),
    ("Turbid po ang tubig na lumalabas sa gripo, madilaw at maalat po ang lasa.", "water", "negative", "moderate"),
    ("Walang anunsyo po na magkakaroon ng water interruption ngayong araw.", "water", "negative", "low"),
    ("Mababa po ang presyon ng tubig sa aming purok tuwing umaga, mabagal po ang daloy.", "water", "negative", "low"),
    ("Malinis na po ba at ligtas inumin ang tubig dito pagkatapos ng linya maintenance?", "water", "neutral", "low"),

    # --- lighting ---
    ("Pundido po ang ilaw sa kalye dito sa eskinita, madilim at delikado po para sa mga bata.", "lighting", "negative", "moderate"),
    ("Salamat po at inayos na ang sira na poste ng ilaw sa kanto ng Purok 2.", "lighting", "positive", "low"),
    ("Paki-replace po ang pundidong solar streetlight sa may bypass road para sa kaligtasan.", "lighting", "negative", "moderate"),
    ("Ligtas na po ba ang bagong ilaw na nilagay sa pedestrian lane sa gabi?", "lighting", "neutral", "low"),
    ("Madilim po sa daanan papuntang paaralan, takot po ang mga estudyante at baka ma-akidente.", "lighting", "negative", "emergency"),
    ("May kumikislap po na ilaw sa poste sa harap ng tindahan namin, tila maluwag ang koneksyon.", "lighting", "negative", "low"),
    ("Maaliwalas na po ang daan ngayon dahil sa bagong ilaw, salamat po sa barangay.", "lighting", "positive", "low"),

    # --- peace_order ---
    ("Sobrang lakas ng videoke at sigawan kahit lampas 11 PM na po, hindi na po kami makatulog.", "peace_order", "negative", "moderate"),
    ("Salamat po at agad na umaksyon ang barangay tanod sa ingay na reklamo namin kagabi.", "peace_order", "positive", "low"),
    ("May suntukan po na nangyayari sa harap ng aming bahay, paki-tawag po agad ng tanod!", "peace_order", "negative", "emergency"),
    ("May malakas na tambutso po ang mga motor dito kada gabi, nakakaistorbo po sa mga residente.", "peace_order", "negative", "moderate"),
    ("Payapa na po ang looban namin ngayon, salamat at naaksyunan ang gulo noong nakaraang linggo.", "peace_order", "positive", "low"),
    ("May kawatan po ba na iniulat sa lugar na ito noong nakaraang buwan?", "peace_order", "neutral", "low"),

    # --- traffic_obstruction ---
    ("May illegal double parking po sa kanto, nakaharang po sa mga dumadaan na sasakyan.", "traffic_obstruction", "negative", "moderate"),
    ("Salamat po at inilipat na ang mga vendor na nakaokupa sa pedestrian lane.", "traffic_obstruction", "positive", "low"),
    ("Magandang araw po, nakaharang po ang isang truck sa malapit sa jeepney terminal, nagkabuhol-buhol ang trapiko.", "traffic_obstruction", "negative", "moderate"),
    ("May mga sasakyan po bang pwedeng i-impound dahil sa harang sa daan papuntang palengke?", "traffic_obstruction", "neutral", "low"),
    ("Naayos na po ba ang pagsasara ng kalsada dahil sa road repair? Mahaba na po ang pila sa trapiko.", "traffic_obstruction", "negative", "moderate"),
    ("Maayos na po ang daloy ng sasakyan ngayon, salamat dahil nilinis ang daan.", "traffic_obstruction", "positive", "low"),

    # --- flood_drainage ---
    ("Bumabaha po sa Mayapa at hindi po makadaan ang mga sasakyan at motorsiklo, malalim po ang tubig.", "flood_drainage", "negative", "emergency"),
    ("Salamat po at nalinis ang kanal dito sa may estero kaya hindi na po bumaha.", "flood_drainage", "positive", "low"),
    ("Paki-check po ang nakatakip na sewage line na nagdudulot ng baha sa bawat malakas na ulan.", "flood_drainage", "negative", "moderate"),
    ("Mabuhay po, may tumagos pong putik ang tubig-baha sa bahay namin sa Pansol kagabi dahil sa pagbaha.", "flood_drainage", "negative", "moderate"),
    ("Aksyunan po agad ang pagbaha sa pangunahing daan, hindi na po makadaan ang ambulansya!", "flood_drainage", "negative", "emergency"),
    ("May nakaipon pong basura sa drainage na nagdudulot ng baradong agos ng tubig.", "flood_drainage", "negative", "moderate"),
    ("Malinaw na po ba ang daluyan ng tubig dito pagkatapos ng dredging noong nakaraang linggo?", "flood_drainage", "neutral", "low"),

    # --- health_sanitation ---
    ("May tambak po ng dumi na iniiwan ng mga aso at pusa dito sa kanto, nakaka-amoy po at delikado sa kalusugan.", "health_sanitation", "negative", "moderate"),
    ("Salamat po sa libreng medical mission sa Barangay Pansol, marami po kaming natulungan!", "health_sanitation", "positive", "low"),
    ("May stagnant na tubig po na pugad ng lamok, paki-spray na po ng dengue prevention.", "health_sanitation", "negative", "moderate"),
    ("Bukas po ba ang health center ngayong linggo para sa libreng bakuna ng mga bata?", "health_sanitation", "neutral", "low"),
    ("May burot na basura po sa kalsada na posibleng pagmulan ng sakit, paki-aksyunan na po.", "health_sanitation", "negative", "moderate"),
    ("Salamat po at may nag-inspeksyon ng food sanitation sa mga karinderya, mas ligtas na po kumain.", "health_sanitation", "positive", "low"),
    ("Kailan po ang susunod na deworming para sa mga bata sa aming barangay?", "health_sanitation", "neutral", "low"),

    # --- electrical_hazard ---
    ("May live wire po na nakalantad at sumasabog na transformer sa may poste, paki-tawag po agad ng Meralco!", "electrical_hazard", "negative", "emergency"),
    ("Salamat po at inayos ng Meralco ang nakasabit na mga wire dito sa looban.", "electrical_hazard", "positive", "low"),
    ("May mababang nakasabit na wire na nasa tapat ng school gate, delikado po sa mga estudyante.", "electrical_hazard", "negative", "moderate"),
    ("Paki-reach out po sa Meralco para sa nakalantad na poste na walang takip sa may palengke.", "electrical_hazard", "negative", "moderate"),
    ("May amoy sunog po sa aming poste kagabi, tila may short circuit, delikado po!", "electrical_hazard", "negative", "emergency"),
    ("Kailan po nila mababaklas ang lumang poste na wala nang gamit sa tabi ng daan?", "electrical_hazard", "neutral", "low"),
    ("Na-resolve na po ba ang palaging brownout dito sa aming purok? Nakakasira po sa appliances.", "electrical_hazard", "negative", "moderate"),

    # --- public_facilities ---
    ("Sira po ang ilaw at upuan sa covered court namin, paki-ayos naman po para sa mga bata.", "public_facilities", "negative", "moderate"),
    ("Salamat po at inayos ang playground ng mga bata dito sa parke ng barangay.", "public_facilities", "positive", "low"),
    ("Wala po bang nagtatrabaho sa barangay hall ngayong hapon? Mahaba po ang pila ng mga nagrereklamo.", "public_facilities", "neutral", "low"),
    ("May sira pong water fountain sa plaza na sayang na tumutuloy ang tubig.", "public_facilities", "negative", "low"),
    ("Bukas po ba ang barangay library tuwing weekend para sa mga estudyante?", "public_facilities", "neutral", "low"),
    ("Malinis at maayos na po ang bagong palikuran sa palengke, salamat po!", "public_facilities", "positive", "low"),
    ("Sirang-pinto po ang CR ng Health Center, hindi po magamit ng mga pasyente.", "public_facilities", "negative", "moderate"),

    # --- general_inquiry ---
    ("Ano po ang requirements para sa pagkuha ng barangay clearance bukas?", "general_inquiry", "neutral", "low"),
    ("Saan po pwede mag-apply para sa cash assistance ng barangay?", "general_inquiry", "neutral", "low"),
    ("Salamat po sa mabilis na tugon ng opisina sa aking katanungan tungkol sa ayuda.", "general_inquiry", "positive", "low"),
    ("Magkano po ba ang bayad para sa certificate of residency?", "general_inquiry", "neutral", "low"),
    ("Anong oras po ang closing ng opisina ng barangay sa Biyernes?", "general_inquiry", "neutral", "low"),
    ("Ilang araw po bago makuha ang barangay clearance pagkatapos magbayad?", "general_inquiry", "neutral", "low"),
    ("Paano po magreport ng lost ID sa barangay hall?", "general_inquiry", "neutral", "low"),
    ("Nakakatanggap po ba kayo ng online na reklamo o chat lang po?", "general_inquiry", "neutral", "low"),

    # --- extra to reach 100 scenarios ---
    ("May basura po na itinapon sa ilog malapit sa subdivision, nakabara po at mabaho na ang tubig.", "waste", "negative", "moderate"),
    ("Paano po ba makapag-recycle ng plastic dito sa barangay natin? May programa po ba?", "waste", "neutral", "low"),
    ("Napakalinis na po ng kalsada dahil sa araw-araw na pagwawalis ng mga tanod, magaling!", "waste", "positive", "low"),
    ("May gapang po na bangketa, hindi po madadaan ng bata at matatanda, pakiayos nga po.", "road", "negative", "moderate"),
    ("Salamat po sa paglalagay ng mga anggulo ng daan para hindi maaksidente ang mga nagmamaneho.", "road", "positive", "low"),
    ("Kailan po ang imbestigasyon sa gumuhong kalsada sa may subdibisyon, delikado po ito.", "road", "negative", "emergency"),
    ("Reliable na po ba ang schedule ng water delivery dito sa mataas na lugar?", "water", "neutral", "low"),
    ("May tagas po sa mga lumang tubo ng CWD na sayang po ang inumin na tubig.", "water", "negative", "moderate"),
    ("Napakasayang po at naayos na agad ang sirang balsa ng tubig sa aming purok.", "water", "positive", "low"),
    ("Madilim na madilim po sa may basketball court pagdating ng gabi, maganda pong lagyan ng ilaw.", "lighting", "positive", "low"),
    ("Sira po ang ilaw sa tawiran ng kindergarten, hindi makita ang mga bata sa gabi.", "lighting", "negative", "moderate"),
    ("May gulo po ngayon sa kanto, may nag-aaway, paki-samahan na po ng tanod!", "peace_order", "negative", "emergency"),
    ("Ayos na po ang sistema ng barangay tanod dito at may patrulya po tuwing gabi, ligtas kami.", "peace_order", "positive", "low"),
    ("Bakit po ba masikip masyado ang kalsada malapit sa simbahan pagdating ng Linggo?", "traffic_obstruction", "neutral", "low"),
    ("Maliwanag na po ang daan ngayon at malinis, mas masaya na pong dumaan dito.", "traffic_obstruction", "positive", "low"),
    ("Bumaha po sa may aming barangay kahit bahagyang ulan lang, hindi na po namin kaya.", "flood_drainage", "negative", "emergency"),
    ("Naku, parang mas malala na po ang baha dito taon-taon, paki-investigate po.", "flood_drainage", "negative", "moderate"),
    ("Magaling po ang ginawang drainage ng barangay, wala na pong tumigas na baha ngayon.", "flood_drainage", "positive", "low"),
    ("May nakahambalang bang nagkasakit dito dahil sa maruming simbahan? Paki check po.", "health_sanitation", "neutral", "low"),
    ("Nakababahala po ang dami ng langaw at daga dito sa palengke, paki-linisin naman po agad.", "health_sanitation", "negative", "moderate"),
]

def main():
    with open(OUT_PATH, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        writer.writerow(['text', 'category', 'sentiment', 'urgency'])
        writer.writerows(SCENARIOS)
    print(f"Wrote {len(SCENARIOS)} test scenarios to {OUT_PATH}")

if __name__ == '__main__':
    main()
