/*
Zadania zrealizowano w PostgreSQL
*/

--struktura bazy danych pozwalająca na zapisanie wszystkich niezbędnych informacji: kandydatów, głosujących, kto na kogo głosował (rozlokowanie na tabele jest dowolne);

DROP SCHEMA IF EXISTS wybory CASCADE;

CREATE SCHEMA wybory;

CREATE TABLE wybory.osoby (
    osobaPESEL CHAR(11), -- Pesel jednoznacznie identyfikuje osobę
    imie VARCHAR(30) NOT NULL,
    drugieImie VARCHAR(30) NULL,
    nazwisko VARCHAR(40) NOT NULL,
    nazwaStanowiska VARCHAR(100) NOT NULL,
    dataUrodzenia DATE NOT NULL,
    PRIMARY KEY(osobaPESEL)
);

CREATE TABLE wybory.glosy (
    glosujacyPESEL CHAR(11) NOT NULL,
    kandydatPESEL CHAR(11) NULL,
    drugaTura BOOLEAN NOT NULL,
    PRIMARY KEY(glosujacyPESEL, drugaTura), -- Nie można zmieniać zdania po oddaniu głosu w ramach jednej tury
    FOREIGN KEY(glosujacyPESEL) REFERENCES wybory.osoby(osobaPESEL),
    FOREIGN KEY(kandydatPESEL) REFERENCES wybory.osoby(osobaPESEL)
);

CREATE TABLE wybory.kandydaci (
    kandydatPESEL CHAR(11),
    nazwisko VARCHAR(40) NOT NULL, /* powielane w tej tabeli żeby uprościć przyszłe zapytania, denormalizacja została przeprowadzona świadomie */
    drugaTura BOOLEAN NOT NULL,
    PRIMARY KEY(kandydatPESEL),
    FOREIGN KEY(kandydatPESEL) REFERENCES wybory.osoby(osobaPESEL)
);

/*dane testowe - osoby*/

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000001',
    'Mariusz',
    'Janusz',
    'Dariusz',
    'Scrum master',
    '1989-01-22'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000002',
    'Jan',
    NULL,
    'Kowalski',
    'Product owner',
    '1980-03-15'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000003',
    'Karol',
    NULL,
    'Walentyński',
    'Designer',
    '1985-02-14'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000004',
    'Maria',
    'Łucja',
    'Nowak',
    'Starszy programista',
    '1990-02-14'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000005',
    'John',
    NULL,
    'Smith',
    'Programista',
    '1990-05-07'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000006',
    'Amadeusz',
    NULL,
    'Wariusz',
    'Tester',
    '1995-01-07'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000007',
    'Miłosz',
    NULL,
    'Walentyński',
    'Stażysta',
    '2000-02-14'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000008',
    'Ola',
    NULL,
    'Walenciak',
    'Stażysta',
    '1999-05-22'
);

INSERT INTO wybory.osoby (
    osobaPESEL,
    imie,
    drugieImie,
    nazwisko,
    nazwaStanowiska,
    dataUrodzenia
) VALUES (
    '00000000009',
    'Miłosz',
    NULL,
    'Kalosz',
    'Stażysta',
    '2001-02-14'
);

-- zapytanie(-a) SQL pozwalające sprawdzić czy dana osoba może zostać kandydatem 

CREATE VIEW wybory.dzienWyborow AS (
    WITH dwaTygodnieTemu AS (
        SELECT CURRENT_DATE - 14 AS data
    ),
    /* dwa tygodnie poniewaz wybory zostały przeprowadzone w niedzielę i była też druga tura (innego dnia) */
    doNiedzieli AS (
        SELECT 7 - EXTRACT('dow' FROM data) :: INTEGER AS liczbaDni FROM dwaTygodnieTemu
        /* dow zwraca wartości od 0 (niedziela) do 6 (sobota) i na jego podstawie wyznaczam liczbę dni tygodnia do niedzieli
        zapytanie nie zadziała poprawnie przy wykonaniu w niedzielę (0), ale zakładam że wtedy nie będzie potrzebne
        bowiem kandydaci nie powinni zgłaszać swojej kandydatury w samym dniu wyborów */
    ),
    /* obliczam dokładny dzień wyborów żeby zapewnić też obsługę przypadków skrajnych, osób które miały urodziny w dniu wyborów */
    dzienWyborow AS (
        SELECT
            dwaTygodnieTemu.data + doNiedzieli.liczbaDni AS data
        FROM dwaTygodnieTemu
        JOIN doNiedzieli
            ON 1 = 1
    )
    SELECT dzienWyborow.data 
    FROM dzienWyborow
);

ALTER TABLE wybory.osoby ADD COLUMN wiek INTEGER NULL;

UPDATE wybory.osoby SET wiek = DATE_PART('year', AGE((SELECT data FROM wybory.dzienWyborow), osoby.dataUrodzenia));

ALTER TABLE wybory.osoby ALTER COLUMN wiek SET NOT NULL;

CREATE VIEW wybory.mozliwiKandydaci AS (
    SELECT
        osoby.osobaPESEL,
        osoby.nazwisko
    FROM wybory.osoby
    -- Każda osoba posiadająca co najmniej 30, i nie więcej niż 100 lat, może zostać kandydatem
    WHERE osoby.wiek BETWEEN 30 AND 100
);

SELECT mozliwiKandydaci.osobaPESEL
FROM wybory.mozliwiKandydaci
WHERE mozliwiKandydaci.osobaPESEL = '00000000003';

/* dane testowe - uzupełnienie tabeli kandydatów o osoby które zgłosiły się do Marszałka (i mogły zostać kandydatami) */

INSERT INTO wybory.kandydaci (
    kandydatPESEL,
    nazwisko,
    drugaTura
) 
SELECT
    mozliwiKandydaci.osobaPESEL,
    mozliwiKandydaci.nazwisko,
    FALSE AS drugaTura
FROM wybory.mozliwiKandydaci
WHERE mozliwiKandydaci.osobaPESEL IN (
    '00000000001',
    '00000000002',
    '00000000003',
    '00000000004',
    '00000000006'
);

--zapytanie(-a) SQL pozwalające pobrać listę kandydatów;
SELECT kandydaci.kandydatPESEL
FROM wybory.kandydaci
WHERE drugaTura = FALSE;

--zapytanie(-a) SQL pozwalające oddać głos;
/* dane testowe - uzupełnienie danych testowych dla pierwszej i drugiej tury wyborów */

/* przyjmuję że głosujący zidentyfikuje się swoim PESELem i wprowadzi nazwisko osoby na którą głosuje
w testowych danych nazwisko pozwala na unikalne zidentyfikowanie kandydata 
i jest ono wygodnym sposobem na wybór kandydata przez użytkownika systemu */


INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
) 
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    FALSE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Dariusz'
WHERE glosujacy.osobaPESEL = '00000000001';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
) 
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    FALSE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
WHERE glosujacy.osobaPESEL = '00000000002';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
) 
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    FALSE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'nieważny głos'
WHERE glosujacy.osobaPESEL = '00000000003';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
) 
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    FALSE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Kowalski'
WHERE glosujacy.osobaPESEL = '00000000004';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
) 
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    FALSE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Dariusz'
WHERE glosujacy.osobaPESEL = '00000000005';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
) 
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    FALSE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
WHERE glosujacy.osobaPESEL = '00000000007';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
) 
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    FALSE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
WHERE glosujacy.osobaPESEL = '00000000008';

-- zapytanie(-a) SQL pozwalające pokazać listę wyborców najpopularniejszego kandydata;

CREATE VIEW wybory.statystykiGlosow AS (
    SELECT
        COALESCE(kandydatPESEL, 'Nieważny') AS kandydat,
        COUNT(*) AS liczbaGlosow,
        drugaTura
    FROM wybory.glosy
    GROUP BY kandydatPESEL, drugaTura
);

SELECT
    glosujacyPESEL
FROM wybory.glosy
WHERE glosy.drugaTura = FALSE
    AND kandydatPESEL = (
        SELECT
            kandydat
        FROM wybory.statystykiGlosow
        WHERE drugaTura = FALSE
        ORDER BY liczbaGlosow DESC
        LIMIT 1
    );

-- zapytanie(-a) SQL pozwalające pokazać listę wyborców kandydata, który otrzymał drugie miejsce;

SELECT
    glosujacyPESEL
FROM wybory.glosy
JOIN (
    SELECT
        kandydat
    FROM wybory.statystykiGlosow
    WHERE drugaTura = FALSE
    ORDER BY liczbaGlosow DESC
    LIMIT 1 OFFSET 1
) drugiCoDoPopularnosci
    ON drugiCoDoPopularnosci.kandydat = glosy.kandydatPESEL
WHERE glosy.drugaTura = FALSE;

-- zapytanie(-a) SQL pozwalające pokazać procentowe wyniki kandydatów;

SELECT
    temp.kandydat,
    (liczbaGlosow / wszystkieGlosyLiczba ) * 100 AS procent
FROM (
    SELECT
        statystykiGlosow.kandydat,
        statystykiGlosow.liczbaGlosow,
        (SELECT COUNT(*) FROM wybory.glosy WHERE glosy.drugaTura = FALSE) :: REAL AS wszystkieGlosyLiczba
    FROM wybory.statystykiGlosow
) temp;

-- zapytanie(-a) SQL pozwalające pokazać procentowe wyniki kandydatów z uwzględnieniem jedynie głosów kandydatów (na kogo sami kandydujący głosowali);

WITH glosyKandydatow AS (
    SELECT
        COALESCE(glosy.kandydatPESEL, 'Nieważny') AS kandydat, 
        glosy.*
    FROM wybory.glosy
    JOIN wybory.kandydaci
        ON kandydaci.kandydatPESEL = glosy.glosujacyPESEL
    WHERE glosy.drugaTura = FALSE
)
SELECT
    liczbaGlosowKandydaci.kandydat,
    (liczbaGlosowKandydaci.liczba / kompletnaLiczbaGlosowKandydaci.liczba ) * 100 AS procent
FROM (
    SELECT
        kandydat,
        COUNT(*) AS liczba
    FROM glosyKandydatow
    GROUP BY glosyKandydatow.kandydat
) AS liczbaGlosowKandydaci
JOIN (
    SELECT COUNT(*) :: REAL AS liczba
    FROM glosyKandydatow
) AS kompletnaLiczbaGlosowKandydaci
ON TRUE;

-- pokanie frekwencję (ile oddanych głosów, ile nieważnych, ile ważnych).

SELECT
    temp.ileOddanych,
    (temp.ileOddanych - temp.ileWaznych) AS ileNiewaznych,
    temp.ileWaznych 
FROM (
    SELECT
        CAST(SUM(statystykiGlosow.liczbaGlosow) AS INTEGER) AS ileOddanych,
        (SELECT COUNT(glosy.kandydatPESEL) FROM wybory.glosy WHERE glosy.drugaTura = FALSE) AS ileWaznych
        /* jeśli głos nie był ważny to pole kandydatPESEL jest ustawione na NULL i funkcja COUNT je pominie */
    FROM wybory.statystykiGlosow
    WHERE statystykiGlosow.drugaTura = FALSE
) temp;

-- Zadania zaawansowane (II tura wyborów)

-- pobranie listę kandydatów na 2 turę (dla marszałka systemu);

UPDATE wybory.kandydaci
    SET drugaTura = TRUE
FROM (
    SELECT
        statystykiGlosow.kandydat
    FROM wybory.statystykiGlosow
    WHERE statystykiGlosow.drugaTura = FALSE
    ORDER BY statystykiGlosow.liczbaGlosow DESC
    LIMIT 2
) AS dwochNajwiększaLiczbaGlosow 
WHERE dwochNajwiększaLiczbaGlosow.kandydat = kandydaci.kandydatPESEL;

SELECT kandydaci.kandydatPESEL
FROM wybory.kandydaci
WHERE kandydaci.drugaTura = TRUE;

/* uzupełnienie danych testowych - głosy druga tura */

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Dariusz'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000001';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000002';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'kolejny nieważny głos'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000003';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Dariusz'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000004';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000005';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000006';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000007';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Dariusz'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000008';

INSERT INTO wybory.glosy (
    glosujacyPESEL,
    kandydatPESEL,
    drugaTura
)
SELECT
    glosujacy.osobaPESEL,
    kandydat.kandydatPESEL,
    TRUE
FROM wybory.osoby AS glosujacy
LEFT JOIN wybory.kandydaci AS kandydat
    ON kandydat.nazwisko = 'Nowak'
    AND kandydat.drugaTura = TRUE
WHERE glosujacy.osobaPESEL = '00000000009';

-- pobranie listę osób, które w pierwszej turze głosowały na kandydata, który nie dostał się do drugiej tury;
/* celowo pomija glosy niewazne */

SELECT glosujacyPESEL
FROM wybory.glosy
JOIN wybory.kandydaci
    ON kandydaci.kandydatPESEL = glosy.kandydatPESEL
    AND kandydaci.drugaTura = FALSE
WHERE glosy.drugaTura = FALSE;

-- czy istniały osoby, które w pierwszej turze zagłosowały na zwycięzcę całych wyborów, ale nie zagłosowały na niego w II turze (zdrajcy)? -- Lista do pobrania;

WITH zwyciezca AS (
    SELECT statystykiGlosow.kandydat
    FROM wybory.statystykiGlosow
    WHERE drugaTura = TRUE
    ORDER BY liczbaGlosow DESC
    LIMIT 1
)
SELECT zdrajcyDruga.glosujacyPESEL
FROM zwyciezca
JOIN wybory.glosy AS osobyKtoreZaglosowalyPierwsza
    ON osobyKtoreZaglosowalyPierwsza.kandydatPESEL = zwyciezca.kandydat
    AND osobyKtoreZaglosowalyPierwsza.drugaTura = FALSE
JOIN wybory.glosy AS zdrajcyDruga
    ON zdrajcyDruga.glosujacyPESEL = osobyKtoreZaglosowalyPierwsza.glosujacyPESEL
    AND zdrajcyDruga.kandydatPESEL != zwyciezca.kandydat
    AND zdrajcyDruga.drugaTura = TRUE;

-- pokazanie średniego wieku wyborców dla najmłodszego kandydata;

SELECT 
    glosy.DrugaTura,
    AVG(osoby.wiek) :: REAL
FROM wybory.osoby
JOIN wybory.glosy
    ON glosy.glosujacyPESEL = osoby.osobaPESEL
WHERE glosy.kandydatPESEL IN (
    SELECT kandydaci.kandydatPESEL
    FROM wybory.osoby
    JOIN wybory.kandydaci
        ON kandydaci.kandydatPESEL = osoby.osobaPESEL
    ORDER BY osoby.wiek ASC
    LIMIT 1
)
GROUP BY glosy.DrugaTura;

-- pokazanie sumarycznej liczby głosów dla każdego z kandydatów (wliczając głosy w I i II tury);

SELECT 
    statystykiGlosow.kandydat,
    SUM(liczbaGlosow) :: INTEGER
FROM wybory.statystykiGlosow
GROUP BY statystykiGlosow.kandydat;

-- pokazanie listy osób, które oddały nieważny głos w obu turach.

SELECT pierwszaTura.glosujacyPESEL
FROM wybory.glosy pierwszaTura
JOIN wybory.glosy drugaTura
    ON drugaTura.glosujacyPESEL = pierwszaTura.glosujacyPESEL
    AND drugaTura.kandydatPESEL IS NULL    
    AND drugaTura.drugaTura = TRUE
WHERE pierwszaTura.kandydatPESEL IS NULL
    AND pierwszaTura.drugaTura = FALSE;
