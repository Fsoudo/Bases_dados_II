import csv
import os

# Configuração de caminhos baseados na estrutura atual
# base_alojamentos_sqlserver/scripts/process_datasets.py -> ../../datasets/
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "..", "..", "datasets", "datasets_completos")
OUT_DIR = os.path.join(BASE_DIR, "..", "..", "datasets", "datasets_limpos")

def process_names(raw_file, out_file, name_col, count_limit=1000):
    print(f"Processando {raw_file}...")
    in_path = os.path.join(RAW_DIR, raw_file)
    out_path = os.path.join(OUT_DIR, out_file)
    
    encoded_encodings = ['utf-8', 'latin-1', 'cp1252']
    
    data = []
    
    for enc in encoded_encodings:
        try:
            with open(in_path, 'r', encoding=enc) as f:
                reader = csv.DictReader(f)
                count = 0
                for row in reader:
                    name = row.get(name_col)
                    if name and len(name) > 2 and name.isalpha():
                        data.append(name)
                        count += 1
                        if count >= count_limit:
                            break
            print(f"  -> Sucesso com encoding {enc}")
            break
        except Exception as e:
            continue
            
    # Remove duplicados e grava
    data = list(set(data))
    with open(out_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Name'])
        for n in data:
            writer.writerow([n])
    print(f"  -> Gerados {len(data)} registos em {out_file}")

def process_cities():
    print("Processando worldcities.csv...")
    in_path = os.path.join(RAW_DIR, "worldcities.csv")
    out_path = os.path.join(OUT_DIR, "clean_cities.csv")
    
    with open(in_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        with open(out_path, 'w', encoding='utf-8', newline='') as out:
            writer = csv.writer(out)
            writer.writerow(['City', 'Country', 'Lat', 'Lng'])
            
            count = 0
            for row in reader:
                # Filtrar apenas principais (ex: Portugal ou capitais?)
                # Para demo, vamos pegar tudo mas limitar ou focar em Portugal + Mundo
                if row['country'] == 'Portugal' or (row['population'] and float(row['population']) > 500000):
                     writer.writerow([row['city_ascii'], row['country'], row['lat'], row['lng']])
                     count += 1
    print(f"  -> Geradas {count} cidades.")

def process_listings():
    print("Processando listings.csv (Airbnb)...")
    in_path = os.path.join(RAW_DIR, "listings.csv")
    out_path = os.path.join(OUT_DIR, "clean_listings.csv")
    
    # Listings tem colunas variaveis, vamos tentar detetar id, name, room_type, price
    # Header detetado: id, name, host_id, host_name, neighbourhoood_group, neighbourhood, latitude, longitude, room_type, price...
    
    with open(in_path, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        with open(out_path, 'w', encoding='utf-8', newline='') as out:
            writer = csv.writer(out)
            writer.writerow(['Title', 'Type', 'Price'])
            
            count = 0
            for row in reader:
                title = row.get('name', 'Alojamento')
                rtype = row.get('room_type', 'Apartment')
                price = row.get('price', '100')
                
                if title:
                    writer.writerow([title, rtype, price])
                    count += 1
                    if count > 5000: break # Limite para não ficar gigante
    print(f"  -> Geradas {count} listings.")

if __name__ == "__main__":
    if not os.path.exists(OUT_DIR):
        os.makedirs(OUT_DIR)
        
    process_names('forenames.csv', 'clean_forenames.csv', 'forename', 3000)
    process_names('surnames.csv', 'clean_surnames.csv', 'surname', 3000)
    process_cities()
    process_listings()
