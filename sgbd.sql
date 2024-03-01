CREATE OR REPLACE PACKAGE pachet_ex13 AS
    PROCEDURE ex6;
    PROCEDURE ex7;
    FUNCTION ex8 (tabel_specialitate TABLE_SPECIALITATE)
        RETURN VARCHAR;
    PROCEDURE ex9(v_nume_facultate FACULTATE.facultate_nume%TYPE);
END;
/


CREATE OR REPLACE PACKAGE BODY pachet_ex13 AS
 TYPE TABLE_SPECIALITATE IS TABLE OF VARCHAR(20);
--creati un tablou(imbricat) cu toate evenimentelele la care au participat mai mult de 3 studenti. creati un alt tablou(indexat) bidimensional care
--salveaza studentii care au participat la evenimentele din primul tablou si materiile si notele obtinute(vector)
PROCEDURE ex6 
IS
--DECLARE
    TYPE MATERIE_NOTA_TIP IS RECORD(
        materie VARCHAR(20),
        nota NUMBER(2));
    TYPE MATERIE_NOTA IS VARRAY(6) OF MATERIE_NOTA_TIP;
    TYPE STUDENT_NOTE IS TABLE OF MATERIE_NOTA INDEX BY PLS_INTEGER;
    TYPE EVENIMENTE_3 IS TABLE OF NUMBER;
    v_id_student student.id_student%TYPE;
    mat_not MATERIE_NOTA;
    v_id_materie MATERIE.materie_nume%TYPE;
    v_nota NOTA.nota%TYPE;
    v_id_eveniment EVENIMENT.id_eveniment%TYPE;
    tabel_student STUDENT_NOTE := STUDENT_NOTE();
    tabel_evenimente EVENIMENTE_3 := EVENIMENTE_3();
    i INTEGER;
    CURSOR cursor_materii IS
        SELECT materie_nume v_id_materie, nota v_nota
        FROM NOTA N
        JOIN MATERIE M ON n.id_materie = m.id_materie 
        WHERE id_student = v_id_student;
    CURSOR evenimente IS 
        SELECT id_eveniment
        FROM eveniment_student
        GROUP BY id_eveniment
        HAVING count(id_student)>=3;
BEGIN
    OPEN evenimente;
        FETCH evenimente BULK COLLECT INTO tabel_evenimente;
    CLOSE evenimente;
    for j in tabel_evenimente.first..tabel_evenimente.last loop
        for i in (Select id_student v_id_student
            from eveniment_student
            WHERE id_eveniment = tabel_evenimente(j)) LOOP
            IF NOT tabel_student.EXISTS(i.v_id_student) THEN
                mat_not := MATERIE_NOTA();
                v_id_student := i.v_id_student;
                OPEN cursor_materii;
                    FETCH cursor_materii BULK COLLECT INTO mat_not;
                CLOSE cursor_materii;
        
                tabel_student(v_id_student):=mat_not;
            END IF;
        END LOOP;
        --dbms_output.put_line(tabel_student(1211)(3).nota);
    END LOOP;
    i:=tabel_student.FIRST;
     WHILE i <= tabel_student.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(i);
        FOR j in 1..tabel_student(i).COUNT loop
            DBMS_OUTPUT.PUT_LINE('   '|| tabel_student(i)(j).materie || ' ' || tabel_student(i)(j).nota);
        end loop;
        i := tabel_student.NEXT(i);   
    END LOOP; 

END;

--afisati numele studentilor pentru grupele cu id 121 si 131
PROCEDURE ex7
IS
    v_id_grupa grupa.id_grupa%TYPE;
    v_grupa_numar grupa.grupa_numar%TYPE;
    v_st_nume student.st_nume%TYPE;
    Cursor cursor_grupa IS
        SELECT id_grupa, grupa_numar
        FROM Grupa
        WHERE ID_GRUPA IN (121, 131);
    CURSOR cursor_student IS
        SELECT st_nume v_st_nume
        FROM STUDENT
        WHERE id_grupa = v_id_grupa;
BEGIN
    OPEN cursor_grupa;
    LOOP
        FETCH cursor_grupa INTO v_id_grupa, v_grupa_numar;
        EXIT WHEN cursor_grupa%NOTFOUND;
        DBMS_OUTPUT.put_line('grupa '|| v_grupa_numar || ': ');
        FOR i in cursor_student LOOP
            DBMS_OUTPUT.put_line('  '||i.v_st_nume);
        END LOOP;   
    END LOOP;
    CLOSE cursor_grupa;
END;



--verificati daca pentru specialitatile Matematica si Informatica exista cel putin un student bursier si daca acesstia nu sunt restantieri
--TYPE TABLE_SPECIALITATE IS TABLE OF VARCHAR(20);

FUNCTION ex8 (tabel_specialitate TABLE_SPECIALITATE)
RETURN VARCHAR IS 
    v_nume_specialitate SPECIALITATE.specialitate_nume%TYPE;
    v_id_student STUDENT.id_student%TYPE;
    v_nota NOTA.nota%TYPE;
    v_bursier STUDENT.bursier%TYPE;
    specialitate_bursiera BOOLEAN;
    nr_note NUMBER(1);
    --tabel_grupe TABLE_GRUPE := TABLE_GRUPE(121, 131);
    exceptie_specialitate EXCEPTION;
    exceptie_student EXCEPTION;
    CURSOR studenti is
        SELECT id_student, bursier
        FROM STUDENT S
        JOIN GRUPA G ON S.id_grupa = g.id_grupa
        JOIN SPECIALITATE SP ON g.id_specialitate = sp.id_specialitate
        WHERE specialitate_nume = v_nume_specialitate;
BEGIN 
    FOR i in 1..tabel_specialitate.count loop
        v_nume_specialitate := tabel_specialitate(i);
        specialitate_bursiera := FALSE;
        OPEN studenti;
        LOOP
            FETCH studenti INTO v_id_student, v_bursier;
            EXIT WHEN studenti%NOTFOUND;
            IF v_bursier = 'DA' THEN
                specialitate_bursiera := TRUE;
                nr_note := 0;
                for j in (SELECT nota nota
                FROM NOTA
                WHERE id_student = v_id_student) loop
                    IF j.nota < 5 THEN 
                        RAISE exceptie_student;
                    END IF;
                end loop;
            END IF;
        END LOOP;
        CLOSE studenti;
        IF specialitate_bursiera = FALSE THEN
            RAISE exceptie_specialitate;
        END IF;
    end loop;
    RETURN 'respecta regulile';
EXCEPTION
    WHEN exceptie_specialitate THEN
        RAISE_APPLICATION_ERROR(-20999,'Exista specialitate fara student bursier');
    WHEN exceptie_student THEN
        RAISE_APPLICATION_ERROR(-20999,'Exista student bursier restantier');
END;


--pentru o facultate data afisati studentul cu media cea mai mare, daca sunt mai multi studenti cu media maxima egala afisati o eroare 
PROCEDURE ex9(v_nume_facultate FACULTATE.facultate_nume%TYPE)
IS 
    v_id_student STUDENT.st_nume%TYPE;
    v_medie FLOAT;
BEGIN 
    SELECT MAX(AVG(nota)) 
    INTO v_medie
    FROM NOTA N
    JOIN STUDENT S ON s.id_student = n.id_student
    JOIN GRUPA G ON S.id_grupa = g.id_grupa
    JOIN SPECIALITATE SP ON g.id_specialitate = sp.id_specialitate
    JOIN FACULTATE F ON f.id_facultate = sp.id_facultate
    WHERE f.facultate_nume = v_nume_facultate
    GROUP BY s.id_student;
    
    SELECT S.ST_NUME
    INTO v_ID_STUDENT
    FROM NOTA N
    JOIN STUDENT S ON s.id_student = n.id_student
    HAVING AVG(nota) = v_medie
    GROUP BY s.st_nume, n.ID_STUDENT;
    
    DBMS_OUTPUT.PUT_LINE(v_id_student);
    
EXCEPTION   
    WHEN NO_DATA_FOUND THEN 
        RAISE_APPLICATION_ERROR(-20001, 'nu exista inca inregistrari cu note pentru aceasta facultate');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20002, 'sunt mai multi studenti cu aceeasi medie');
END;

END pachet_ex13;
/








--creati un triger care nu permite adaugarea noilor studenti la un eveniment care depaseste 5 participanti deasemenea daca nu 
-- apartin facultatii care organizeaza acest eveniment
CREATE OR REPLACE TRIGGER ex11
BEFORE INSERT OR UPDATE ON EVENIMENT_STUDENT
FOR EACH ROW
DECLARE
    v_student_count NUMBER;
    v_event_facultate NUMBER;
    v_student_facultate NUMBER;
BEGIN
    BEGIN
        SELECT COUNT(*)
        INTO v_student_count
        FROM EVENIMENT_STUDENT
        WHERE ID_EVENIMENT = :NEW.ID_EVENIMENT
        GROUP BY id_eveniment;
        
        IF v_student_count >= 5 THEN
            RAISE_APPLICATION_ERROR(-20001, 'A fost depasita limita de persoane in acest eveniment');
        END IF;
        
    EXCEPTION   
        WHEN NO_DATA_FOUND THEN v_student_count := 0; 
    END;
    BEGIN 
        SELECT id_facultate
        INTO v_event_facultate
        FROM EVENIMENT 
        WHERE ID_EVENIMENT = :NEW.ID_EVENIMENT;
        
        
        SELECT ID_FACULTATE
        INTO v_student_facultate
        FROM STUDENT S
        JOIN GRUPA G ON g.id_grupa = s.id_grupa
        JOIN SPECIALITATE SP ON g.id_specialitate = sp.id_specialitate
        WHERE ID_STUDENT = :NEW.ID_STUDENT;
    
        IF v_event_facultate <> v_student_facultate THEN
            RAISE_APPLICATION_ERROR(-20002, 'Studentii din alte facultati nu au dreptul sa se inscrie la acest eveniment');
        END IF;
    END;
END;
/

INSERT INTO EVENIMENT_STUDENT VALUES(101, 1231, 'participant');
INSERT INTO EVENIMENT_STUDENT VALUES(201, 1313, 'participant');
ROLLBACK;
/

--creati un triger care dupa modificarea tabelului NOTA modifica coloana bursier din tabelul STUDENT 
-- daca studentul are cel putin o restanta nu e bursier, iar daca nu are restante atunci este bursier
CREATE OR REPLACE TRIGGER ex10
AFTER INSERT OR UPDATE or DELETE ON nota
DECLARE
    v_avg_nota NUMBER;
BEGIN
    FOR rec IN (SELECT DISTINCT id_student FROM nota)
    LOOP
        SELECT AVG(nota)
        INTO v_avg_nota
        FROM nota
        WHERE id_student = rec.id_student;

        UPDATE student
        SET bursier = CASE WHEN v_avg_nota >= 5 THEN 'DA' ELSE 'NU' END
        WHERE id_student = rec.id_student;
    END LOOP;
END;
/

INSERT INTO NOTA VALUES(1314, 111, 2);
rollback;



-- creati o tabela in care veti introduce cu ajutorul unui triger modificarile facute asupra tabelelor, view, procedurilor si functiilor
CREATE TABLE schema_modif (
    change_id       NUMBER,
    change_type     VARCHAR2(20),
    object_type     VARCHAR2(30),
    object_name     VARCHAR2(100),
    schema_user     VARCHAR2(30),
    session_user    VARCHAR2(30),
    ip_address      VARCHAR2(15),
    moment TIMESTAMP
);

CREATE SEQUENCE seq_id
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE OR REPLACE TRIGGER ex12
AFTER CREATE OR ALTER OR DROP ON SCHEMA
DECLARE
    v_session_user  VARCHAR2(30);
    v_ip_address    VARCHAR2(15);
BEGIN
    v_session_user := sys_context('USERENV', 'SESSION_USER');
    v_ip_address := SYS_CONTEXT('USERENV', 'IP_ADDRESS');

    IF ora_dict_obj_type IN ('TABLE', 'VIEW', 'PROCEDURE', 'FUNCTION') THEN
        INSERT INTO schema_modif VALUES (
            seq_id.NEXTVAL,
            ora_sysevent,
            ora_dict_obj_type,
            ora_dict_obj_name,
            ora_dict_obj_owner,
            v_session_user,
            v_ip_address,
            CURRENT_TIMESTAMP
        );
    END IF;
END;
/

CREATE TABLE a (id NUMBER(2));
ALTER TABLE a RENAME TO AA;
DROP PROCEDURE ex6;



SELECT pachet_ex13.ex8(TABLE_SPECIALITATE('GEOGRAFIE', 'MATEMATICA', 'INFORMATICA')) FROM DUAL;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(pachet_ex13.ex8(TABLE_SPECIALITATE('GEOGRAFIE', 'MATEMATICA', 'INFORMATICA')));
END;
/

EXECUTE pachet_ex13.ex6;





