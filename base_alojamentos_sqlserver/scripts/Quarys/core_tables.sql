
/* ===============================
   core_tables.sql — tabelas principais e constraints
   =============================== */
USE AluguerHab;
GO

-- TABELAS DE UTILIZADORES/PAPÉIS
CREATE TABLE core.Utilizador (
    UtilizadorId INT IDENTITY(1,1) CONSTRAINT PK_Utilizador PRIMARY KEY,
    Email NVARCHAR(256) NOT NULL UNIQUE,
    HashSenha VARBINARY(256) NOT NULL,
    Nome NVARCHAR(120) NOT NULL,
    DataRegisto DATETIME2 NOT NULL CONSTRAINT DF_Utilizador_DataRegisto DEFAULT SYSUTCDATETIME(),
    Ativo BIT NOT NULL CONSTRAINT DF_Utilizador_Ativo DEFAULT 1
) ON FG_DATA;

CREATE TABLE core.Papel (
    PapelId INT IDENTITY(1,1) CONSTRAINT PK_Papel PRIMARY KEY,
    Nome NVARCHAR(50) NOT NULL UNIQUE
) ON FG_DATA;

CREATE TABLE core.UtilizadorPapel (
    UtilizadorId INT NOT NULL,
    PapelId INT NOT NULL,
    CONSTRAINT PK_UtilizadorPapel PRIMARY KEY (UtilizadorId, PapelId),
    CONSTRAINT FK_UtilizadorPapel_Utilizador FOREIGN KEY (UtilizadorId) REFERENCES core.Utilizador(UtilizadorId),
    CONSTRAINT FK_UtilizadorPapel_Papel FOREIGN KEY (PapelId) REFERENCES core.Papel(PapelId)
) ON FG_DATA;

-- ENTIDADES DE NEGÓCIO
CREATE TABLE core.Anfitriao (
    AnfitriaoId INT IDENTITY(1,1) CONSTRAINT PK_Anfitriao PRIMARY KEY,
    UtilizadorId INT NOT NULL UNIQUE,
    IBAN NVARCHAR(34) NULL,
    CONSTRAINT FK_Anfitriao_Utilizador FOREIGN KEY (UtilizadorId) REFERENCES core.Utilizador(UtilizadorId)
) ON FG_DATA;

CREATE TABLE core.Cliente (
    ClienteId INT IDENTITY(1,1) CONSTRAINT PK_Cliente PRIMARY KEY,
    UtilizadorId INT NOT NULL UNIQUE,
    DataNascimento DATE NULL,
    Pais NVARCHAR(100) NULL,
    CONSTRAINT FK_Cliente_Utilizador FOREIGN KEY (UtilizadorId) REFERENCES core.Utilizador(UtilizadorId)
) ON FG_DATA;

CREATE TABLE core.Localizacao (
    LocalizacaoId INT IDENTITY(1,1) CONSTRAINT PK_Localizacao PRIMARY KEY,
    Pais NVARCHAR(100) NOT NULL,
    Cidade NVARCHAR(100) NOT NULL,
    Morada NVARCHAR(200) NULL,
    Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL
) ON FG_DATA;

CREATE TABLE core.Propriedade (
    PropriedadeId INT IDENTITY(1,1) CONSTRAINT PK_Propriedade PRIMARY KEY,
    AnfitriaoId INT NOT NULL,
    LocalizacaoId INT NOT NULL,
    Titulo NVARCHAR(200) NOT NULL,
    Descricao NVARCHAR(MAX) NULL,
    Capacidade INT NOT NULL,
    DataCriacao DATETIME2 NOT NULL CONSTRAINT DF_Propriedade_DataCriacao DEFAULT SYSUTCDATETIME(),
    RatingMedio DECIMAL(3,2) NOT NULL CONSTRAINT DF_Propriedade_Rating DEFAULT 0,
    CONSTRAINT FK_Propriedade_Anfitriao FOREIGN KEY (AnfitriaoId) REFERENCES core.Anfitriao(AnfitriaoId),
    CONSTRAINT FK_Propriedade_Localizacao FOREIGN KEY (LocalizacaoId) REFERENCES core.Localizacao(LocalizacaoId)
) ON FG_DATA;

CREATE TABLE core.Comodidade (
    ComodidadeId INT IDENTITY(1,1) CONSTRAINT PK_Comodidade PRIMARY KEY,
    Nome NVARCHAR(100) NOT NULL UNIQUE
) ON FG_DATA;

CREATE TABLE core.PropriedadeComodidade (
    PropriedadeId INT NOT NULL,
    ComodidadeId INT NOT NULL,
    CONSTRAINT PK_PropriedadeComodidade PRIMARY KEY (PropriedadeId, ComodidadeId),
    CONSTRAINT FK_PC_P FOREIGN KEY (PropriedadeId) REFERENCES core.Propriedade(PropriedadeId),
    CONSTRAINT FK_PC_C FOREIGN KEY (ComodidadeId) REFERENCES core.Comodidade(ComodidadeId)
) ON FG_DATA;

CREATE TABLE core.Foto (
    FotoId INT IDENTITY(1,1) CONSTRAINT PK_Foto PRIMARY KEY,
    PropriedadeId INT NOT NULL,
    Url NVARCHAR(400) NOT NULL,
    Ordem INT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Foto_Propriedade FOREIGN KEY (PropriedadeId) REFERENCES core.Propriedade(PropriedadeId)
) ON FG_DATA;

CREATE TABLE core.Epoca (
    EpocaId INT IDENTITY(1,1) CONSTRAINT PK_Epoca PRIMARY KEY,
    Nome NVARCHAR(80) NOT NULL,
    DataInicio DATE NOT NULL,
    DataFim DATE NOT NULL,
    CONSTRAINT CK_Epoca_Range CHECK (DataInicio <= DataFim)
) ON FG_DATA;

CREATE TABLE core.PrecoEpoca (
    PrecoEpocaId INT IDENTITY(1,1) CONSTRAINT PK_PrecoEpoca PRIMARY KEY,
    PropriedadeId INT NOT NULL,
    EpocaId INT NOT NULL,
    PrecoNoite DECIMAL(10,2) NOT NULL,
    Moeda CHAR(3) NOT NULL DEFAULT 'EUR',
    CONSTRAINT UQ_Preco UNIQUE (PropriedadeId, EpocaId),
    CONSTRAINT FK_Preco_P FOREIGN KEY (PropriedadeId) REFERENCES core.Propriedade(PropriedadeId),
    CONSTRAINT FK_Preco_E FOREIGN KEY (EpocaId) REFERENCES core.Epoca(EpocaId)
) ON FG_DATA;

CREATE TABLE core.CalendarioDisponibilidade (
    CalendarioId BIGINT IDENTITY(1,1) CONSTRAINT PK_Calendario PRIMARY KEY,
    PropriedadeId INT NOT NULL,
    Dia DATE NOT NULL,
    Ocupado BIT NOT NULL DEFAULT 0,
    CONSTRAINT UQ_Calendario UNIQUE (PropriedadeId, Dia),
    CONSTRAINT FK_Calendario_P FOREIGN KEY (PropriedadeId) REFERENCES core.Propriedade(PropriedadeId)
) ON FG_DATA;

CREATE TABLE core.Reserva (
    ReservaId BIGINT IDENTITY(1,1) CONSTRAINT PK_Reserva PRIMARY KEY,
    PropriedadeId INT NOT NULL,
    ClienteId INT NOT NULL,
    DataCheckIn DATE NOT NULL,
    DataCheckOut DATE NOT NULL,
    Estado NVARCHAR(30) NOT NULL DEFAULT 'PENDENTE', -- PENDENTE | CONFIRMADA | CANCELADA
    Total DECIMAL(12,2) NOT NULL DEFAULT 0,
    CriadaEm DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Reserva_Range CHECK (DataCheckIn < DataCheckOut),
    CONSTRAINT FK_Reserva_P FOREIGN KEY (PropriedadeId) REFERENCES core.Propriedade(PropriedadeId),
    CONSTRAINT FK_Reserva_C FOREIGN KEY (ClienteId) REFERENCES core.Cliente(ClienteId)
) ON FG_DATA;

CREATE TABLE core.Pagamento (
    PagamentoId BIGINT IDENTITY(1,1) CONSTRAINT PK_Pagamento PRIMARY KEY,
    ReservaId BIGINT NOT NULL UNIQUE,
    Metodo NVARCHAR(50) NOT NULL,
    Valor DECIMAL(12,2) NOT NULL,
    Moeda CHAR(3) NOT NULL DEFAULT 'EUR',
    TransacaoRef NVARCHAR(100) NOT NULL,
    PagoEm DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Pagamento_Reserva FOREIGN KEY (ReservaId) REFERENCES core.Reserva(ReservaId)
) ON FG_DATA;

CREATE TABLE core.Avaliacao (
    AvaliacaoId BIGINT IDENTITY(1,1) CONSTRAINT PK_Avaliacao PRIMARY KEY,
    PropriedadeId INT NOT NULL,
    ClienteId INT NOT NULL,
    ReservaId BIGINT NOT NULL,
    Rating TINYINT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comentario NVARCHAR(1000) NULL,
    CriadaEm DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Aval_P FOREIGN KEY (PropriedadeId) REFERENCES core.Propriedade(PropriedadeId),
    CONSTRAINT FK_Aval_C FOREIGN KEY (ClienteId) REFERENCES core.Cliente(ClienteId),
    CONSTRAINT FK_Aval_R FOREIGN KEY (ReservaId) REFERENCES core.Reserva(ReservaId)
) ON FG_DATA;

-- ÍNDICES ESSENCIAIS
CREATE INDEX IX_Reserva_P_Data ON core.Reserva (PropriedadeId, DataCheckIn, DataCheckOut) ON FG_INDEX;
CREATE INDEX IX_Calendario_P_Dia ON core.CalendarioDisponibilidade (PropriedadeId, Dia) ON FG_INDEX;
CREATE INDEX IX_Propriedade_Local ON core.Propriedade (LocalizacaoId, Capacidade) ON FG_INDEX;
