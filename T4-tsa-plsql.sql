--*****PLEASE ENTER YOUR DETAILS BELOW*****
--T4-tsa-plsql.sql

--Student ID: 32638396
--Student Name: Rachit Bhatia
--Unit Code: FIT3171
--Applied Class No: Tutorial 1, Friday 12pm

/* Comments for your marker:
For task 4(a), the a random increment of 5 is used for the review pk. An additional check for rating value has been added in the procedure.
The prior and post states of the review table are shown for each test suite.

For task 4(b), COMMIT is not used after the UPDATE statement because it is assumed that after inserting the data, COMMIT will anyways be used. 
The checks done in in this task include checking if recommending member exists, if new member has same resort as recommending member, and if new member already exists.
NULL values are no longer accepted for member_id_recby due to the new business rule.
The prior and post states of the review table are shown for each test suite.
*/

SET SERVEROUTPUT ON

--4(a) 
-- Create a sequence for REVIEW PK
DROP SEQUENCE review_seq;
CREATE SEQUENCE review_seq START WITH 50 INCREMENT BY 5;

-- Complete the procedure below
CREATE OR REPLACE PROCEDURE prc_insert_review (
    p_member_id      IN NUMBER,
    p_poi_id         IN NUMBER,
    p_review_comment IN VARCHAR2,
    p_review_rating  IN NUMBER,
    p_output         OUT VARCHAR2
) AS
    var_member_id_existing NUMBER;
    var_poi_id_existing NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO var_member_id_existing
    FROM member
    WHERE member_id = p_member_id;

    SELECT COUNT(*)
    INTO var_poi_id_existing
    FROM point_of_interest
    WHERE poi_id = p_poi_id;

    IF (var_member_id_existing = 0) THEN
        p_output := 'Invalid Member ID entered. Entered Member ID does not exist';
    ELSE
        IF (var_poi_id_existing = 0) THEN
            p_output := 'Invalid POI ID entered. Entered Point of Interest does not exist';
        ELSE
            IF (p_review_rating < 1 or p_review_rating > 5) THEN
                 p_output := 'Invalid rating value entered. Rating should be between 1 to 5';
            ELSE     
                INSERT INTO review VALUES (
                    review_seq.NEXTVAL,
                    p_member_id,
                    (SELECT sysdate FROM dual),
                    p_review_comment,
                    p_review_rating,
                    p_poi_id
                );
        
                p_output := 'The review for member with id ' || p_member_id
                            || ' and point of interest with id ' || p_poi_id
                            || ' has successfully been created';
            END IF;                 
        END IF;
    END IF;   
END;
/

-- Write Test Harness for 4(a)

--test 1
--prior state
SELECT * FROM REVIEW;

--executing the procedure
--trying to add review for invalid member id but valid poi id
--result: fail - nothing gets inserted into review table
DECLARE output VARCHAR2 (200);
BEGIN
    prc_insert_review(7, 3, 'Excellent service by the staff', 5, output);
    dbms_output.put_line(output);
END;    
/

--executing the procedure
--trying to add review for valid member id but invalid poi id
--result: fail - nothing gets inserted into review table
DECLARE output VARCHAR2 (200);
BEGIN
    prc_insert_review(2, 10, 'Excellent service by the staff', 5, output);
    dbms_output.put_line(output);
END;    
/

--executing the procedure
--trying to add review for invalid member id and invalid poi id
--result: fail - nothing gets inserted into review table
DECLARE output VARCHAR2 (200);
BEGIN
    prc_insert_review(9, 12, 'Slightly overpriced, but overall satisfcatory', 3, output);
    dbms_output.put_line(output);
END;    
/

--executing the procedure
--trying to add review for valid member id and valid poi id but invalid rating value
--result: fail - nothing gets inserted into review table
DECLARE output VARCHAR2 (200);
BEGIN
    prc_insert_review(2, 3, 'Very unclean environment', 0, output);
    dbms_output.put_line(output);
END;    
/

--post state
--exactly the same as prior state because no insertions were made in this test
SELECT * FROM REVIEW;


--test 2
--prior state
SELECT * FROM REVIEW;

--executing the procedure
--trying to add review for valid member id and valid poi id with valid rating value
--result: pass - new review gets inserted into the table
DECLARE output VARCHAR2 (200);
BEGIN
    prc_insert_review(2, 3, 'Very rude management staff', 1, output);
    dbms_output.put_line(output);
END;    
/

--post state
--review table now consists of new additional entry
SELECT * FROM REVIEW;


--test 3
--prior state
SELECT * FROM REVIEW;

--executing the procedure
--trying to add review for valid member id and valid poi id with valid rating value
--result: pass - new review gets inserted into the table
DECLARE output VARCHAR2 (200);
BEGIN
    prc_insert_review(4, 3, 'Great Serives provided with complimentary snacks', 4, output);
    dbms_output.put_line(output);
END;    
/

--post state
--review table now consists of new additional entry
SELECT * FROM review;

ROLLBACK;


--4(b) 
--Write your trigger statement, 
--finish it with a slash(/) followed by a blank line
CREATE OR REPLACE TRIGGER check_new_member BEFORE
INSERT ON member
FOR EACH ROW
DECLARE
    cur_resort_id NUMBER;
    count_member_id NUMBER;
    count_rec_member_id NUMBER;
    count_member_no NUMBER;
BEGIN

    /*checking if recommending member exists in the system*/
    SELECT COUNT(member_id)
    INTO count_rec_member_id
    FROM member
    WHERE member_id = :NEW.member_id_recby;
    
    IF (count_rec_member_id = 0) THEN
        raise_application_error(-20000, 'Invalid recommeding member ID! Recommending member is not a valid existing member');
    ELSE
        
        /*checking if new member and recommending member belong to same home resort*/
        SELECT resort_id
        INTO cur_resort_id
        FROM member
        WHERE member_id = :NEW.member_id_recby;

        IF :NEW.resort_id != cur_resort_id THEN
            raise_application_error(-20000, 'Invalid resort ID! New Member does not have the same home resort as the recommending member');
        ELSE
            /*checking if member with same number already exists in the resort*/
            SELECT COUNT (resort_id)
            INTO count_member_no
            FROM member
            WHERE resort_id = :NEW.resort_id 
                  AND member_no = :NEW.member_no;
            
            /*checking if member with same id already exists in the system*/
            SELECT COUNT (member_id)
            INTO count_member_id
            FROM member
            WHERE member_id = :NEW.member_id;
                  
            IF (count_member_no > 0) or (count_member_id > 0) THEN
                raise_application_error(-20000, 'Member already exists! Entered member already exists in the resort system');
            ELSE
                UPDATE member
                SET
                    member_points = member_points + 10
                WHERE
                    member_id = :NEW.member_id_recby;
                    
                dbms_output.put_line('New member with id ' || :new.member_id || ' added to resort with id ' || :new.resort_id || ' recommended by another member with id ' || :new.member_id_recby);
            END IF;
        END IF;
    END IF;
END;
/


-- Write Test Harness for 4(b)
--test 1
--prior state
SELECT * FROM member;

--trigger testing
--adding new member but with invalid non-existent recommended member id 
--result: fail (raises application error)
INSERT INTO member VALUES (
    5,
    2,
    3,
    'Chris',
    'Hapmton',
    '5172 Alila Estate, Oakleigh, VIC',
    'mpt@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    8
);

--trigger testing
--adding new member but with no recommendation (null recommedning member id)
--result: fail (raises application error)
INSERT INTO member VALUES (
    5,
    2,
    3,
    'Chris',
    'Hapmton',
    '5172 Alila Estate, Oakleigh, VIC',
    'mpt@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    null
);

--trigger testing
--adding new member with valid existent recommended member id but resort id of recommending member and new member do not match
--result: fail (raises application error)
INSERT INTO member VALUES (
    6,
    1,
    3,
    'Samuel',
    'Specter',
    '5172 Alila Estate, Oakleigh, VIC',
    'mpt@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    2
);

--trigger testing
--adding new member with already existing member_no in the same resort but unique member_id
--result: fail (raises application error)
INSERT INTO member VALUES (
    6,
    1,
    2,
    'Samuel',
    'Specter',
    '5172 Alila Estate, Oakleigh, VIC',
    'mpt@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    1
);

--trigger testing
--adding new member with already existing member_id but unique combination of member_no and resort_id
--result: fail (raises application error)
INSERT INTO member VALUES (
    1,
    1,
    3,
    'Mike',
    'Lawson',
    '4390 Alila Estate, Oakleigh, VIC',
    'lkp@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    4
);

--trigger testing
--adding new member with unmatching resort ids and already existing combination of resort_id and member_no
--result: fail (raises application error)
INSERT INTO member VALUES (
    1,
    1,
    1,
    'Vanilla',
    'Debby',
    '4390 Alila Estate, Oakleigh, VIC',
    'lkp@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    2
);

--trigger testing
--adding new member with valid resort id but unmatching resort id with recommending member
--result: fail (raises application error)
INSERT INTO member VALUES (
    9,
    1,
    3,
    'Stacy',
    'Croul',
    '1091 Gold Street, Oakleigh, VIC',
    'scp@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    2
);

--post state
--exactly the same as prior state becuase there were no successful insertions in this suite
SELECT * FROM member;


--test 2
--prior state
SELECT * FROM member;

--trigger testing
--adding new member with unique member_id and unique combination of resort_id & member_no and valid existing recommending member and same resort id as rec member id
--result: pass (no error produced)
INSERT INTO member VALUES (
    5,
    1,
    3,
    'Vanilla',
    'Debby',
    '4390 Alila Estate, Oakleigh, VIC',
    'lkp@mymail.com',
    '0567129174',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    4
);

--post state
--member with id 5 and resort id 1 added
SELECT * FROM member;

--test 3
--prior state
SELECT * FROM member;

--trigger testing
--adding new member with unique member_id and unique combination of resort_id & member_no and valid existing recommending member and same resort id as rec member id
--result: pass (no error produced)
INSERT INTO member VALUES (
    15,
    2,
    5,
    'John',
    'Slammoth',
    '1010 Grule Estate, Clayton, VIC',
    'jsl@mymail.com',
    '0931898633',
    TO_DATE((
        SELECT
            sysdate
        FROM
            dual
    ), 'dd/mm/yyyy'),
    1000,
    3
);

--post state
--member with id 15 and resort id 2 added
SELECT * FROM member;


ROLLBACK;













