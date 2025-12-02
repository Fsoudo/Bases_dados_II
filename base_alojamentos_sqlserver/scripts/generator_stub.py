"""
Gerador de dados (stub) — preencher a BD AluguerHab com >=10k registos
- Usa datasets públicos (ficheiros CSV locais) para nomes, cidades, comodidades, etc.
- NÃO usa LLMs como fonte de dados.
- Ajusta a connection string e caminhos para os CSVs antes de correr.
"""
import os
import csv
import random
import datetime
import uuid
import pyodbc

# Conexão: ajustar conforme o teu ambiente
SQL_SERVER = os.getenv("SQL_SERVER", ".")  # ex.: ".\SQLEXPRESS"
SQL_DB = os.getenv("SQL_DB", "AluguerHab")
SQL_USER = os.getenv("SQL_USER")  # se usares SQL Auth
SQL_PWD = os.getenv("SQL_PWD")

# Exemplo de connection string (Windows Auth se USER/PWD não definidos)
if SQL_USER and SQL_PWD:
    CONN_STR = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DB};UID={SQL_USER};PWD={SQL_PWD};TrustServerCertificate=yes"
else:
    CONN_STR = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DB};Trusted_Connection=yes;TrustServerCertificate=yes"

def get_conn():
    return pyodbc.connect(CONN_STR)

def seed_ref_data(conn):
    """
    Insere dados de referência a partir de CSVs públicos previamente descarregados.
    Espera ficheiros como:
      ./data/amenities.csv (Nome)
      ./data/cities.csv (Pais,Cidade,Latitude,Longitude)
      ./data/names.csv (Nome)
    """
    cur = conn.cursor()

    # Comodidades
    amenities_path = "./data/amenities.csv"
    if os.path.exists(amenities_path):
        with open(amenities_path, newline="", encoding="utf-8") as f:
            rdr = csv.DictReader(f)
            for row in rdr:
                cur.execute("INSERT INTO core.Comodidade(Nome) VALUES (?)", row["Nome"])
        conn.commit()

    # Localizações (limit example)
    cities_path = "./data/cities.csv"
    if os.path.exists(cities_path):
        with open(cities_path, newline="", encoding="utf-8") as f:
            rdr = csv.DictReader(f)
            for i, row in enumerate(rdr):
                if i >= 20000:
                    break
                cur.execute("""
                    INSERT INTO core.Localizacao(Pais, Cidade, Morada, Latitude, Longitude)
                    VALUES (?, ?, NULL, ?, ?)
                """, row["Pais"], row["Cidade"], row.get("Latitude", None), row.get("Longitude", None))
        conn.commit()

    # Papéis
    for role in ["CLIENTE", "ANFITRIAO", "ADMIN"]:
        cur.execute("IF NOT EXISTS (SELECT 1 FROM core.Papel WHERE Nome=?) INSERT INTO core.Papel(Nome) VALUES (?)", role, role)
    conn.commit()

def random_user(cur, name, email):
    cur.execute("""
        INSERT INTO core.Utilizador(Email, HashSenha, Nome)
        VALUES (?, HASHBYTES('SHA2_256', CONVERT(varbinary(256), ?)), ?)
    """, email, "ChangeMe123!", name)
    return cur.execute("SELECT SCOPE_IDENTITY()").fetchval()

def seed_users_hosts_clients(conn, n_hosts=2000, n_clients=8000):
    cur = conn.cursor()
    # Simples gerador de nomes/emails (substituir por CSVs públicos para realismo)
    def fake_name(i): return f"User{i}"
    def fake_mail(i): return f"user{i}@example.com"

    # Anfitriões
    for i in range(1, n_hosts+1):
        uid = random_user(cur, fake_name(i), fake_mail(i))
        cur.execute("INSERT INTO core.Anfitriao(UtilizadorId, IBAN) VALUES (?, ?)", uid, f"PT50{random.randint(10**19, 10**20-1)}")
    conn.commit()

    # Clientes
    for i in range(1, n_clients+1):
        idx = i + n_hosts
        uid = random_user(cur, fake_name(idx), fake_mail(idx))
        dob = datetime.date(1970,1,1) + datetime.timedelta(days=random.randint(0, 18000))
        cur.execute("INSERT INTO core.Cliente(UtilizadorId, DataNascimento, Pais) VALUES (?, ?, ?)", uid, dob, "Portugal")
    conn.commit()

def seed_properties(conn, per_host=3):
    cur = conn.cursor()
    hosts = [row[0] for row in cur.execute("SELECT AnfitriaoId FROM core.Anfitriao").fetchall()]
    locs = [row[0] for row in cur.execute("SELECT LocalizacaoId FROM core.Localizacao").fetchall()]
    if not locs:
        # fallback mínimo
        cur.execute("INSERT INTO core.Localizacao(Pais, Cidade) VALUES (N'Portugal', N'Lisboa')")
        conn.commit()
        locs = [row[0] for row in cur.execute("SELECT LocalizacaoId FROM core.Localizacao").fetchall()]

    for h in hosts:
        for _ in range(per_host):
            loc = random.choice(locs)
            cap = random.randint(1, 8)
            cur.execute("""
                INSERT INTO core.Propriedade(AnfitriaoId, LocalizacaoId, Titulo, Descricao, Capacidade)
                VALUES (?, ?, ?, ?, ?)
            """, h, loc, f"Alojamento {uuid.uuid4().hex[:8]}", "Descrição breve.", cap)
    conn.commit()

def seed_pricing_calendar(conn):
    cur = conn.cursor()
    # Épocas simples
    seasons = [
        ("Baixa", "2025-01-01", "2025-03-31"),
        ("Média", "2025-04-01", "2025-06-30"),
        ("Alta", "2025-07-01", "2025-08-31"),
        ("Média", "2025-09-01", "2025-10-31"),
        ("Baixa", "2025-11-01", "2025-12-31"),
    ]
    for n, di, df in seasons:
        cur.execute("INSERT INTO core.Epoca(Nome, DataInicio, DataFim) VALUES (?, ?, ?)", n, di, df)
    conn.commit()

    props = [row[0] for row in cur.execute("SELECT PropriedadeId FROM core.Propriedade").fetchall()]
    epocas = [row[0] for row in cur.execute("SELECT EpocaId FROM core.Epoca").fetchall()]
    for p in props:
        for e in epocas:
            price = random.randint(40, 300)
            try:
                cur.execute("""
                    INSERT INTO core.PrecoEpoca(PropriedadeId, EpocaId, PrecoNoite) VALUES (?, ?, ?)
                """, p, e, price)
            except pyodbc.Error:
                pass
    conn.commit()

    # Calendário dos próximos 365 dias
    today = datetime.date.today()
    for p in props:
        rows = [(p, (today + datetime.timedelta(days=d))) for d in range(0, 365)]
        # bulk insert (simples loop)
        for chunk in [rows[i:i+500] for i in range(0, len(rows), 500)]:
            cur.fast_executemany = True
            cur.executemany("INSERT INTO core.CalendarioDisponibilidade(PropriedadeId, Dia, Ocupado) VALUES (?, ?, 0)", chunk)
            conn.commit()

def main():
    with get_conn() as conn:
        seed_ref_data(conn)
        seed_users_hosts_clients(conn, n_hosts=2000, n_clients=8000)  # total >= 10k utilizadores
        seed_properties(conn, per_host=3)  # ~6k propriedades
        seed_pricing_calendar(conn)
    print("Seeds concluídos.")

if __name__ == "__main__":
    main()
"""
