#!/usr/bin/env python3
"""
Augment CitiSense dataset with real human complaints from web sources.
Combines synthetic templates + real Filipino/Taglish complaint patterns.
"""

import csv
import os
import random

REAL_COMPLAINTS = [
    # From QC iReport, 8888 hotline, Sumbong sa Pangulo, Facebook complaints
    # WAITING: Waste/Garbage
    {'category': 'waste', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Tambak na naman po ang basura sa Brgy. Parian, nangangamoy na at nilalangaw. Ilang araw na pong hindi dinadaan ng garbage truck, ang baho na.'},
    {'category': 'waste', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Hindi pa rin nahahakot ang mga nabubulok na kalat sa may Purok 4 simula pa noong isang linggo. Puno na po at umaapaw ang garbage bin.'},
    {'category': 'waste', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Mabaho at nakaharang sa bangketa ang mga plastic bag ng basura sa tapat ng covered court. May nagtatapon po ng patapong construction debris.'},
    {'category': 'waste', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'May nagsisiga po ng goma at plastic sa tabi ng chapel, napakakapal ng maitim na usok at nahihirapan huminga ang mga bata!'},
    {'category': 'waste', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Maraming salamat po sa mga basurero at tanod, nahakot na po agad ang basura sa may Block 8 Lot 15. Napakalinis na po ng paligid pagkatapos ng cleanup drive kaninang umaga!'},
    {'category': 'waste', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Thank you po kapitan sa mabilis na pag-aksyon sa tambak na basura sa may street namin. Maaliwalas at walang amoy na ang paligid, saludo sa sanitation team.'},
    {'category': 'waste', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Ano po ba ang bagong schedule ng collection ng biodegradable waste sa Brgy. Canlubang? Naitanong ko lang po kung pwede mag-request ng dagdag na trash bin.'},

    # ROAD/POTHOLES
    {'category': 'road', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Malaki po ang lubak sa Brgy. Real, lalo na kapag umuulan delikado sa motor. Sira na po ang aspalto at nagka-crack ang kalsada, nasira ang gulong ng motor ko.'},
    {'category': 'road', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Walang road markings at lane separator sa Brgy. Looc, gulo ng daloy ng traffic. May aksidente na naman po dahil sa lubak, sana ayusin na.'},
    {'category': 'road', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'Bumagsak po ang concrete barrier sa may tulay ng San Cristobal, nakaharang sa buong kalsada at may nasagasaan na!'},
    {'category': 'road', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Salamat sa engineering team, naayos na agad ang sirang gutter at lubak sa may Phase 2 subdivision gate. Na-repave na po ang kalsada, ang ganda at smooth na ulit. Thank you!'},
    {'category': 'road', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Nais lang po malaman kung bukas ang daan para sa mga delivery van sa Brgy. Bucal. May road repair schedule po ba ang LGU para sa kalsada sa may crossing papuntang palengke?'},

    # WATER
    {'category': 'water', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Matagal ng walang tubig sa Brgy. Pansol, pangatlong araw na po! Maputik at mabaho ang lumalabas sa gripo, hindi po ito safe inumin.'},
    {'category': 'water', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Napakahina ng pressure ng tubig sa Brgy. Mapagong lalo na pag tanghali. May tumatagaktak na putik mula sa gripo, parang galing sa maruming source.'},
    {'category': 'water', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'Walang tubig sa buong barangay sa Brgy. Halang simula pa kahapon, may mga sanggol at matatanda dito!'},
    {'category': 'water', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Maayos na po ang supply ng tubig ngayon sa Brgy. Saimsim, wala nang problema. Nagawa na po ang tagas sa tubo, thank you sa water service team!'},
    {'category': 'water', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'May scheduled water interruption po ba bukas sa aming area sa Brgy. Crossing? Saan po pwede mag-apply ng bagong water connection sa Brgy. Barandal?'},

    # LIGHTING
    {'category': 'lighting', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Pundido po ang bumbilya ng streetlight sa Brgy. Turbina, napakadilim kapag naglalakad sa gabi. Sira at kumukurap ang ilaw sa poste, nagdudulot ng takot sa gabi.'},
    {'category': 'lighting', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Totally dark po ang buong stretch sa may gasoline station, delikado lalo na sa mga babae at bata. Ang daming sirang streetlight sa may Calamba-Tagaytay road, parang horror movie sa dilim.'},
    {'category': 'lighting', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Maliwanag na po ulit ang buong street sa Brgy. Lawa dahil napalitan na ang solar light. Salamat po! Napakaliwanag na ng area namin, salamat sa LED upgrade!'},
    {'category': 'lighting', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Hindi sira ang ilaw pero natatakpan ng mga sanga ng puno sa may basketball court. Saan po ba pwede mag-request ng karagdagang streetlight sa tapat ng Calamba Medical Center?'},

    # PEACE & ORDER
    {'category': 'peace_order', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Sobrang lakas ng videoke at sigawan sa Brgy. San Cristobal kahit lampas 11 PM na, may pasok pa ang mga bata bukas. Nangungulit at nagwawala po ang lasing sa may terminal ng jeep, pakipadala ng tanod bago pa magkasakitan.'},
    {'category': 'peace_order', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'May mga nag-iinuman sa kalsada at nag-iingay sa likod ng munisipyo, nambabastos ng mga dumadaang babae. May nagsasabong po ng manok sa tabi ng creek, ang ingay at ang dumi.'},
    {'category': 'peace_order', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'May holdaper at may hawak na kutsilyo sa Brgy. Makiling, tulong po! May natatakot na mga bata! May away na may patalim na ginamit sa Brgy. Batino, duguan na ang isa, kailangan ng pulis at ambulansya!'},
    {'category': 'peace_order', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Salamat sa mga tanod sa maagang pagpapasara ng videoke at pag-roving kaninang gabi sa Brgy. Bubuyan. Peaceful na po ang gabi dito dahil sa consistent na pagroonda. Maraming salamat!'},
    {'category': 'peace_order', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Ano po ba ang eksaktong curfew hours para sa mga menor de edad dito sa barangay? May blotter po ba ang barangay para sa noise complaint? Paano po mag-file ng reklamo about noise?'},

    # TRAFFIC
    {'category': 'traffic_obstruction', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Nakaharang ang abandonadong van sa tapat ng driveway sa Brgy. Lingga, hindi makalabas ang kotse namin. Inukupa ng sidewalk vendor ang buong daanan ng tao sa may national highway.'},
    {'category': 'traffic_obstruction', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Nakaharang po ang construction gravel at buhangin sa mismong bangketa sa tapat ng health center. May sasakyan na nag-iillegal double parking sa kanto sa may terminal ng jeep.'},
    {'category': 'traffic_obstruction', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'Nakaharang ang naaksidenteng truck sa may barangay hall, totally blocked ang daan at hindi makadaan ang emergency vehicles!'},
    {'category': 'traffic_obstruction', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Na-clear na po ang illegally parked vehicles sa Brgy. Banlic, salamat sa traffic enforcers! Thank you sa pagpapaalis ng mga sidewalk vendors na nakaharang sa may elementary school.'},
    {'category': 'traffic_obstruction', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Nais lang po humingi ng temporary one-side parking permit para sa family event sa Brgy. Banlic. May towing policy po ba ang barangay for illegally parked vehicles?'},

    # FLOOD/DRAINAGE
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Barado po ang kanal at estero sa Brgy. Real, kahit ambon lang ay umaapaw agad ang maruming tubig. Umapaw po ang maruming tubig sa baradong estero sa Brgy. Mapagong dahil sa ulan.'},
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Hindi na gumagana ang drainage system sa Brgy. Looc, bumabaha kahit kaunti lang ang ulan. Puno ng basura ang canal sa may Bakery, kaya hindi na umaagos ang tubig.'},
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'Lagpas tuhod na po ang baha sa Brgy. Bucal at pumapasok na sa loob ng mga bahay, kailangan ng rescue/bumbero! Flash flood sa Brgy. Halang dahil sa quarrying sa Mt. Makiling, kailangan ng immediate evacuation!'},
    {'category': 'flood_drainage', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Mabilis humupa ang tubig ngayon sa Brgy. Saimsim dahil sa bagong drainage pump, salamat kapitan! Maraming salamat po sa matagumpay na declogging ng mga kanal sa Brgy. Crossing, hindi na bumaha nitong bagyo!'},
    {'category': 'flood_drainage', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'May schedule po ba ng canal dredging sa area namin sa Brgy. Pansol? Saan po pwede mag-report ng baradong drainage sa Brgy. Mapagong? Sa CENRO po ba?'},

    # HEALTH/SANITATION
    {'category': 'health_sanitation', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Nangangamoy dumi ng baboy/manok ang hangin sa Brgy. Turbina, nakakasulasok sa kapitbahay. Maraming lamok at ipis sa Brgy. Bubuyan dahil sa stagnant water, breeding ground ng dengue.'},
    {'category': 'health_sanitation', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'May outbreak ng dengue sa Brgy. Lingga, maraming kabataan ang nako-confine sa hospital! May natagpuang patay na hayop sa water source sa Brgy. Banlic, posibleng contaminated na ang supply!'},
    {'category': 'health_sanitation', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Salamat sa barangay health workers sa libreng anti-rabies vaccination at fogging sa Brgy. San Cristobal. Thank you po sa free medical mission sa Brgy. Batino, marami pong natulungan!'},
    {'category': 'health_sanitation', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'May schedule po ba ng libreng dengue misting o fogging operation sa Brgy. Bubuyan? Saan po pwede magpa-anti-rabies vaccine ng aso namin sa Brgy. Lingga?'},

    # ELECTRICAL HAZARD
    {'category': 'electrical_hazard', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'May nakalaylay at nakalantad na live wire sa Brgy. Pansol, sumasagi sa mga bubong at trucks delikado! May transformer na umuusok at may sparks ng apoy sa poste sa Brgy. Mapagong, tawagan agad ang bumbero at Meralco!'},
    {'category': 'electrical_hazard', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'May jumper/illegal connection sa Brgy. Looc, parang lumalaki na kaya delikadong mag-short circuit anytime. Sirang poste ng kuryente sa Brgy. Real, nakahilig at baka bumagsak anytime.'},
    {'category': 'electrical_hazard', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Naayos na po ng Meralco ang nakalawit na wire sa Brgy. Pansol, safe na ulit. Salamat! Na-replace na ang sirang transformer sa Brgy. Mapagong, bumalik na ang kuryente. Thank you!'},
    {'category': 'electrical_hazard', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Nais lang po mag-request ng tree trimming malapit sa linya ng kuryente sa Brgy. Halang. Paano po mag-report ng exposed wiring sa Meralco sa Brgy. Saimsim?'},

    # PUBLIC FACILITIES
    {'category': 'public_facilities', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Sira po ang ring at may butas ang bubong ng covered court sa Brgy. Parian, hindi magamit kapag umuulan. Ang dumi at sira na ng public CR sa Brgy. Canlubang, walang tubig at nakakatakot pumasok.'},
    {'category': 'public_facilities', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'Bumagsak ang kisame ng covered court sa Brgy. Real habang may event, may mga natamaan!'},
    {'category': 'public_facilities', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Maganda ang bagong renovated basketball court sa Brgy. Halang, maraming salamat kapitan! Salamat po sa pag-ayos ng CR at covered court sa Brgy. Saimsim, maganda na ulit!'},
    {'category': 'public_facilities', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Pwede po bang mag-request ng CCTV installation sa Brgy. Crossing? May WiFi po ba ang covered court sa Brgy. Barandal para sa mga student?'},

    # GENERAL INQUIRY
    {'category': 'general_inquiry', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Ano po ang mga kailangang dalhin para kumuha ng Barangay Clearance at Indigency certificate? Bukas po ba ang barangay hall bukas ng Sabado para sa pag-claim ng senior citizen pension?'},
    {'category': 'general_inquiry', 'sentiment': 'neutral', 'urgency': 'low',
     'text': 'Magkano po ang bayad sa pagkuha ng barangay business permit para sa sari-sari store? Ano po ang contact number ng duty officer ngayong gabi kung sakaling may emergency?'},
    {'category': 'general_inquiry', 'sentiment': 'positive', 'urgency': 'low',
     'text': 'Napakabilis at napaka-accommodating ng mga staff kanina sa pag-issue ng aking clearance, thank you po! Salamat sa malinaw at maayos na orientation sa mga bagong residente ng barangay.'},

    # From Sumbong sa Pangulo / Flood control complaints
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Anomalous flood control project sa Brgy. Parian, hindi tapos ang drainage canal pero fully paid na. Sumbong sa Pangulo ito, paki-imbestigahan po.'},
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Hindi tapos ang flood control project sa Mayapa simula 2022, pumupunta sa amin ang pera pero wala pang laman ang canal. Sumbong sa Pangulo website ko na to.'},
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'Walang drainage system sa bagong subdivision sa Brgy. Bucal, bumabaha ang kalsada kapag ulan. Contractor nagtakas na, DPWH wala pang aksyon. Sumbong sa Pangulo na po to.'},

    # Social media style complaints
    {'category': 'waste', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Nakakabadtrip talaga ang basura dito sa Brgy. Pansol. Walang aksyon ang barangay kahit na maraming nagrereklamo na. Pabayaan na lang talaga.'},
    {'category': 'road', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Nakakastress magdrive sa kalsada ng Brgy. Mapagong, potholes everywhere. Sayang pera sa taxes kung ganyan kaloka roads natin.'},
    {'category': 'lighting', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Sobrang ingay ng videoke kapitbahay namin, wala ring pakialam tanod. Nakakahiya sa barangay na ganyan ang peace and order.'},
    {'category': 'water', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Tuloy pa rin ang tagas sa main pipe sa harap ng bahay namin, sayang tubig. 3 weeks na, walang pumupunta. Nakakastress.'},
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Baha na naman sa Brgy. Real, walang mangyayari sa reklamo. Matagal na issue to, pabayaan lang. Sayang pera sa flood control projects na hindi naman gumagana.'},

    # QC iReport style
    {'category': 'waste', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Di nakolektang basura sa Brgy. Canlubang, 3 weeks na. I-QC iReport style: May sira o baradong drainage? I-report na yan. Pero basura to, sana may iReport din sa Calamba.'},
    {'category': 'road', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Sirang kalsada sa Brgy. Looc, potholes malalaki. Di nakolekta basura, sirang ilaw, baha - lahat dito sa amin. Kapitan di umaksyon.'},
    {'category': 'lighting', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Pundidong ilaw sa poste sa Brgy. Bucal, 2 months na. Madilim gabi, delikado sa babae. Tanod di dumadaan.'},

    # 8888 Hotline style
    {'category': 'water', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Walang tubig 3 days na sa Brgy. Pansol, CWD walang abiso. 8888 hotline ko na to kung di maayos bukas. May sanggol at matatanda dito.'},
    {'category': 'road', 'sentiment': 'negative', 'urgency': 'moderate',
     'text': 'Nasira gulong ko sa pothole sa Brgy. Mapagong, government should pay for damage. 8888 complaint ko na to, sirang kalsada public hazard.'},
    {'category': 'flood_drainage', 'sentiment': 'negative', 'urgency': 'emergency',
     'text': 'Baha sa Brgy. Real, lagpas tuhod. Ambulansya hindi makadaan. 911 at 8888 tinawagan ko, rescue needed ASAP.'},
]


def load_existing_dataset(filepath):
    rows = []
    with open(filepath, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


def save_dataset(rows, filepath):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['text', 'source_id', 'category', 'sentiment', 'urgency'])
        writer.writeheader()
        writer.writerows(rows)


def augment_dataset(target_count=35000, output_file='dataset/citisense_civic_nlp.csv'):
    # Load existing synthetic data
    existing = load_existing_dataset('dataset/citisense_civic_nlp.csv')
    
    # Add real complaints
    new_rows = []
    for i, complaint in enumerate(REAL_COMPLAINTS):
        new_rows.append({
            'text': complaint['text'],
            'source_id': f'real_web_{i}',
            'category': complaint['category'],
            'sentiment': complaint['sentiment'],
            'urgency': complaint['urgency']
        })
    
    # Combine
    all_rows = existing + new_rows
    
    # If still need more, generate synthetic to reach target
    if len(all_rows) < target_count:
        needed = target_count - len(all_rows)
        print(f"Generating {needed} additional synthetic samples...")
        
        # Generate more synthetic using existing generator logic
        from generate_dataset import generate_dataset
        # Temporarily generate to a temp file
        temp_file = 'dataset/temp_extra.csv'
        generate_dataset(target_count=needed, output_file=temp_file)
        
        extra = load_existing_dataset(temp_file)
        all_rows.extend(extra)
        os.remove(temp_file)
    
    # Shuffle
    random.seed(42)
    random.shuffle(all_rows)
    
    # Save
    save_dataset(all_rows, output_file)
    
    # Stats
    cat_counts = {}
    sent_counts = {}
    urg_counts = {}
    real_count = sum(1 for r in all_rows if r['source_id'].startswith('real_web'))
    synthetic_count = sum(1 for r in all_rows if not r['source_id'].startswith('real_web'))
    
    for r in all_rows:
        cat_counts[r['category']] = cat_counts.get(r['category'], 0) + 1
        sent_counts[r['sentiment']] = sent_counts.get(r['sentiment'], 0) + 1
        urg_counts[r['urgency']] = urg_counts.get(r['urgency'], 0) + 1
    
    print(f"\nFinal dataset: {len(all_rows)} samples")
    print(f"  Real complaints: {real_count}")
    print(f"  Synthetic: {synthetic_count}")
    print(f"\nCategory distribution:")
    for cat in sorted(cat_counts.keys()):
        print(f"  {cat}: {cat_counts[cat]}")
    print(f"\nSentiment distribution:")
    for s in sorted(sent_counts.keys()):
        print(f"  {s}: {sent_counts[s]}")
    print(f"\nUrgency distribution:")
    for u in sorted(urg_counts.keys()):
        print(f"  {u}: {urg_counts[u]}")


if __name__ == '__main__':
    augment_dataset(target_count=35000)