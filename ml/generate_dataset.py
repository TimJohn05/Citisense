#!/usr/bin/env python3
"""
CitiSense NLP Synthetic Data Generator & Augmenter (10-Category Civic Taxonomy).
Generates realistic contextual Taglish civic complaints for sentiment,
10-category classification, and urgency scoring.
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
    'sa kanto ng Barandal',
    'sa may Purok 4',
    'sa tapat ng covered court',
    'sa tabi ng chapel',
    'sa may Bucal bypass road',
    'sa tapat ng elementary school',
    'sa Block 8 Lot 15',
    'sa may crossing papuntang palengke',
    'sa gilid ng barangay hall',
    'sa may tulay ng San Cristobal',
    'sa Purok 6 extension',
    'sa tabi ng bakery',
    'sa may Phase 2 subdivision gate',
    'sa tapat ng daycare center',
    'sa kahabaan ng main avenue'
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
    '',
]

# Comprehensive Templates for 10+ Civic Categories
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
            "May nagtatapon po ng patapong construction debris at sirang gamit {loc}."
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
            "Maaliwalas at walang amoy na ang paligid {loc}, saludo sa sanitation team."
        ]
    },
    {
        'category': 'waste',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Ano po ba ang bagong schedule ng collection ng biodegradable waste {loc}?",
            "Naitanong ko lang po kung pwede mag-request ng dagdag na trash bin {loc}.",
            "Hindi naman marumi pero sana maglagay ng sign na bawal magtapon {loc}."
        ]
    },

    # ==================== 2. ROAD & INFRASTRUCTURE ====================
    {
        'category': 'road',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "May malaking lubak sa kalsada {loc}, sumasabit ang ilalim ng mga sasakyan at motor.",
            "Sirang-sira na po ang semento {loc}, baku-bako at delikado kapag gabi.",
            "Masyadong madulas ang putik sa kalsada {loc} dahil sa mga truck na labas-pasok.",
            "Basag ang gilid ng gutter {loc} baka matapilok ang mga naglalakad.",
            "Kailangan po ng speed humps {loc}, mabilis magpatakbo ang mga tricycle at motor."
        ]
    },
    {
        'category': 'road',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "May malalim na sinkhole o bitak sa kalsada {loc}, delikadong mahulog ang sasakyan!",
            "Gumuho po ang maliit na riprap sa tabi ng kalsada {loc} dahil sa ulan kahapon."
        ]
    },
    {
        'category': 'road',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Naaspalto at napatag na po ang kalsada {loc}, maayos at smooth na ang biyahe!",
            "Salamat sa engineering team, naayos na agad ang sirang gutter at lubak {loc}.",
            "Maganda ang pagkakagawa ng humps {loc}, safe na tumawid ang mga bata."
        ]
    },
    {
        'category': 'road',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Kailan po kaya masisimulan ang road widening project {loc}?",
            "May road repair signage po ba na ilalagay habang ongoing ang construction {loc}?",
            "Nais lang po malaman kung bukas ang daan para sa mga delivery van {loc}."
        ]
    },

    # ==================== 3. WATER SUPPLY ====================
    {
        'category': 'water',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Napakalabo at kulay kalawang po ng lumalabas na tubig sa gripo {loc}.",
            "Mahina po ang tulo ng tubig tuwing umaga {loc}, hindi makaipon para sa pampaligo.",
            "Tatlong araw na pong putol-putol ang serbisyo ng tubig {loc}."
        ]
    },
    {
        'category': 'water',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "Pumutok po ang main water pipe {loc}, rumaragasa ang tubig sa kalsada at nawalan ng supply ang buong purok!",
            "Walang-wala pong tubig simula pa kahapon {loc}, kailangan na po ng emergency water delivery truck."
        ]
    },
    {
        'category': 'water',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Malinaw at malakas na po ulit ang tulo ng tubig {loc}, maraming salamat po sa agarang pagkukumpuni.",
            "Nagawa na po yung tagas sa tubo {loc}, thank you sa water service team!",
            "Maayos na po ang supply ng tubig ngayon, wala nang problema."
        ]
    },
    {
        'category': 'water',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "May scheduled water interruption po ba bukas sa aming area {loc}?",
            "Nais lang po magtanong kung paano mag-apply ng bagong metro ng tubig {loc}."
        ]
    },

    # ==================== 4. LIGHTING ====================
    {
        'category': 'lighting',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Pundido po ang bumbilya ng streetlight {loc}, napakadilim kapag naglalakad sa gabi.",
            "Kukurap-kurap ang ilaw sa poste {loc}, baka mapundi na rin anumang oras.",
            "Madilim na daanan {loc}, takot dumaan ang mga estudyante at trabahador kapag gabi."
        ]
    },
    {
        'category': 'lighting',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Maliwanag na po ulit ang buong street {loc} dahil napalitan na ang solar light. Salamat po!",
            "Bilis po ng aksyon ng barangay electrician, gumagana na ang ilaw sa poste {loc}.",
            "Thank you po at naiayos na ang street lights, safe na ulit maglakad sa gabi."
        ]
    },
    {
        'category': 'lighting',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Saan po ba pwede mag-request ng karagdagang streetlight {loc}?",
            "Hindi sira ang ilaw pero natatakpan ng mga sanga ng puno {loc}."
        ]
    },

    # ==================== 5. PEACE & ORDER (NOISE & DISTURBANCE) ====================
    {
        'category': 'peace_order',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Sobrang lakas ng videoke at sigawan {loc} kahit lampas 11 PM na, may pasok pa ang mga bata bukas.",
            "May mga nag-iinuman sa kalsada at nag-iingay {loc}, nambabastos ng mga dumadaang babae.",
            "Laging may nagpapatakbo ng motor na may open pipe muffler {loc} dis-oras ng gabi.",
            "Nangungulit at nagwawala po ang lasing {loc}, pakipadala ng tanod bago pa magkasakitan."
        ]
    },
    {
        'category': 'peace_order',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Salamat sa mga tanod sa maagang pagpapasara ng videoke at pag-roving kaninang gabi {loc}.",
            "Tahimik at payapa na po ang street namin simula nang mag-curfew check ang barangay.",
            "Thank you po sa pag-aksyon sa reklamo namin sa maingay na kapitbahay."
        ]
    },
    {
        'category': 'peace_order',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Ano po ba ang eksaktong curfew hours para sa mga menor de edad dito sa barangay?",
            "Pwede po ba magtanong kung hanggang anong oras ang allowable videoke policy sa residential area?"
        ]
    },

    # ==================== 6. TRAFFIC & OBSTRUCTIONS ====================
    {
        'category': 'traffic_obstruction',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "May mga sasakyan na nag-iillegal double parking {loc}, hindi na magkasya ang dalawang sasakyan.",
            "Nakaharang po ang construction gravel at buhangin sa mismong bangketa {loc}.",
            "Inukupa ng sidewalk vendor ang buong daanan ng tao {loc}, napipilitan maglakad sa kalsada.",
            "Nakaharang ang abandonadong van sa tapat ng driveway {loc}, hindi makalabas ang kotse namin."
        ]
    },
    {
        'category': 'traffic_obstruction',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Nalinis na po at maluwag na ang daan {loc} pagkatapos ng road clearing operation ng tanod.",
            "Salamat po sa pag-warning sa may-ari ng nakaharang na truck sa kanto.",
            "Maayos na po ang daloy ng trapiko {loc}, good job po!"
        ]
    },
    {
        'category': 'traffic_obstruction',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "May permit po ba ang delivery truck na magbaba ng materyales bukas ng hapon {loc}?",
            "Nais lang po humingi ng temporary one-side parking permit para sa family event {loc}."
        ]
    },

    # ==================== 7. FLOODING & DRAINAGE ====================
    {
        'category': 'flood_drainage',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Barado po ang kanal at estero {loc}, kahit ambon lang ay umaapaw agad ang maruming tubig.",
            "Nakalubog po sa baha ang kalsada {loc} dahil walang labasan ang tubig-ulan.",
            "Nawawala po ang bakal na takip ng manhole {loc}, delikadong may mahulog na bata o motor!"
        ]
    },
    {
        'category': 'flood_drainage',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "Lagpas tuhod na po ang baha {loc} at pumapasok na sa loob ng mga bahay, kailangan ng rescue/bumbero!",
            "Umapaw po ang creek at rumaragasa ang tubig sa mga kabahayan {loc}!"
        ]
    },
    {
        'category': 'flood_drainage',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Maraming salamat po sa matagumpay na declogging ng mga kanal {loc}, hindi na bumaha nitong bagyo!",
            "Nalagyan na po ng bagong takip ang manhole {loc}, safe na ulit ang daan.",
            "Mabilis humupa ang tubig ngayon dahil sa bagong drainage pump, salamat kapitan!"
        ]
    },
    {
        'category': 'flood_drainage',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Kailan po ang schedule ng quarterly canal declogging dito sa aming purok {loc}?",
            "Hindi pa naman barado pero maraming tuyong dahon sa ibabaw ng drainage {loc}."
        ]
    },

    # ==================== 8. PUBLIC HEALTH & SANITATION ====================
    {
        'category': 'health_sanitation',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "May mga pagala-galang aso na nanghahabol ng mga bata at nagkakalat ng dumi {loc}.",
            "May nangingitlog na lamok sa stagnant water {loc}, baka magka-dengue ang mga residente.",
            "Nangangamoy dumi ng baboy/manok ang hangin {loc}, nakakasulasok sa kapitbahay."
        ]
    },
    {
        'category': 'health_sanitation',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "May nagsisiga po ng mga goma at plastic {loc}, napakakapal ng maitim na usok at hindi na makahinga ang may hika!",
            "May rabid/nangangagat na stray dog {loc}, nakakagat na po ng dalawang residente pakihuli agad!"
        ]
    },
    {
        'category': 'health_sanitation',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Salamat sa barangay health workers sa libreng anti-rabies vaccination at fogging kanina {loc}.",
            "Na-warningan na po yung nagsisiga at tumigil na ang usok, thank you po!",
            "Nakuha na po ng dog pound yung mapanganib na aso, ligtas na ang mga naglalakad."
        ]
    },
    {
        'category': 'health_sanitation',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "May schedule po ba ng libreng dengue misting o fogging operation {loc}?",
            "Kailan po ang susunod na bakuna para sa mga alagang hayop sa purok namin?"
        ]
    },

    # ==================== 9. ELECTRICAL HAZARDS ====================
    {
        'category': 'electrical_hazard',
        'sentiment': 'negative',
        'urgency': 'emergency',
        'texts': [
            "May nakalaylay at nakalantad na live wire {loc}, sumasagi sa mga bubong at trucks delikado!",
            "May transformer na umuusok at may sparks ng apoy sa poste {loc}, tawagan agad ang bumbero at Meralco!",
            "Nakatabingi at mabubuwal na ang poste ng kuryente {loc} baka bumagsak sa mga bahay!"
        ]
    },
    {
        'category': 'electrical_hazard',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Naayos at naitaas na po ng Meralco at barangay yung nakalaylay na kable {loc}, salamat po!",
            "Napalitan na po ang sirang fuse sa transformer, safe na po ulit.",
            "Good job po sa mabilis na pag-cordon sa delikadong live wire kanina."
        ]
    },
    {
        'category': 'electrical_hazard',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Kaninong telco company po kaya yung mga nakabuhol-buhol na spaghetti wire {loc}?",
            "Nais lang po mag-request ng tree trimming malapit sa linya ng kuryente {loc}."
        ]
    },

    # ==================== 10. PUBLIC FACILITIES & PARKS ====================
    {
        'category': 'public_facilities',
        'sentiment': 'negative',
        'urgency': 'moderate',
        'texts': [
            "Sira po ang ring at may butas ang bubong ng covered court {loc}, hindi magamit kapag umuulan.",
            "Basag po ang duyan at sirang slide sa children's playground {loc}, delikado sa mga batang naglalaro.",
            "Sira po ang pinto at gripo sa public comfort room sa barangay plaza {loc}."
        ]
    },
    {
        'category': 'public_facilities',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Napakaganda na po ng bagong pintura at ilaw sa covered court {loc}, salamat sa barangay council!",
            "Naayos na po ang mga sirang laruan sa park, natutuwa ang mga bata.",
            "Malinis at kumpleto na ang kagamitan sa health center desk, salute po!"
        ]
    },
    {
        'category': 'public_facilities',
        'sentiment': 'neutral',
        'urgency': 'low',
        'texts': [
            "Paano po magpareserba ng covered court para sa inter-purok basketball tournament?",
            "Available po ba ang barangay multi-purpose hall sa darating na linggo para sa assembly?"
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
            "Ano po ang contact number ng duty officer ngayong gabi kung sakaling may emergency?"
        ]
    },
    {
        'category': 'general_inquiry',
        'sentiment': 'positive',
        'urgency': 'low',
        'texts': [
            "Napakabilis at napaka-accommodating ng mga staff kanina sa pag-issue ng aking clearance, thank you po!",
            "Salamat sa malinaw at maayos na orientation sa mga bagong residente ng barangay."
        ]
    }
]


def generate_dataset(target_count=1000, output_file='dataset/citisense_civic_nlp.csv'):
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    rows = []
    print(f"Generating rich 10-category NLP dataset...")

    generated = 0
    while len(rows) < target_count:
        tpl_group = random.choice(TEMPLATES)
        loc = random.choice(LOCATIONS)
        prefix = random.choice(PREFIXES)
        base_text = random.choice(tpl_group['texts']).format(loc=loc)
        
        full_text = f"{prefix} {base_text}".strip()
        full_text = " ".join(full_text.split())

        row = {
            'text': full_text,
            'category': tpl_group['category'],
            'sentiment': tpl_group['sentiment'],
            'urgency': tpl_group['urgency']
        }
        
        if not any(r['text'] == row['text'] for r in rows):
            rows.append(row)
            generated += 1

    random.shuffle(rows)

    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['text', 'category', 'sentiment', 'urgency'])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Successfully generated {len(rows)} samples across {len(CATEGORIES)} civic categories.")
    print(f"Saved dataset to {output_file}")


if __name__ == '__main__':
    generate_dataset(target_count=1000)
