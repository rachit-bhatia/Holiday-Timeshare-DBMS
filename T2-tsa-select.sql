--*****PLEASE ENTER YOUR DETAILS BELOW*****
--T2-tsa-select.sql

--Student ID: 32638396
--Student Name: Rachit Bhatia
--Unit Code: FIT3171
--Applied Class No: Tutorial 1, Friday 12pm

/* Comments for your marker:
For task 2(b), the member table has been joined with the column containing member_id_recby so that the values where member id matches member_id_recby can be
obtained. This matching is then counted to find the number of recommendations by each member. MAX is used in the HAVING clause to display only those members who 
have made the 'highest' number of recommendations.

For task 2(c) a left outer join has been used so that the poi_ids with no reviews also get copied into the join. LPAD has been used to ensure all MAX and MIN rating
values are displayed with 1 leading spacing as shown in the expected form. Then RPAD is used to increase the column width so that the whole column header can be 
displayed in the script output (eg: to fully show MAX_RATING instead of just MA in the script output).

For task 2(d) a left outer join has been used to ensure poi with no reviews are also selected. Case statement is used to display 'No reviews completed' for poi with
no reviews. The total number of reviews has been retrieved using select statement to count all review ids in the REVIEW table.

For task 2(e) self join has been used to retrieve the name of the recommending member. A CASE statement has been used to format the names with no given name 
without a leading space. The conditions in the WHERE clause ensure the town of the member is not Byron Bay, NSW and member_id_recby is not null, while the HAVING 
clause ensures the sum of charges of the member is lesser than the average charges of that resort. When run script is used for task 2e, the right alignment of the 
TOTAL_CHARGES column is displayed.

For task 2(f), theta join has been used to first join resort and town on town_id, and then join with point_of_interest on the condition where the geodistance <= 100.
The exact formatting is displayed when ru script is used on the query (for example, distance values get right-aligned). RPAD has been used POI_STATE and POI_OPENING_TIME
to display the whole column header title when run script is used.

*/

/*2(a)*/
-- PLEASE PLACE REQUIRED SQL STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer
SELECT
    town_id,
    town_name,
    poi_type_id,
    poi_type_descr,
    COUNT(poi_type_id) AS poi_count
FROM
    tsa.town
    NATURAL JOIN tsa.point_of_interest
    NATURAL JOIN tsa.poi_type
GROUP BY
    town_id,
    town_name,
    poi_type_id,
    poi_type_descr
HAVING
    COUNT(poi_type_id) > 1
ORDER BY
    town_id,
    poi_type_descr;


/*2(b)*/
-- PLEASE PLACE REQUIRED SQL STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer
SELECT
    member_id,
    member_gname || ' ' || member_fname AS member_name,
    m.resort_id,
    resort_name,
    COUNT(rec.member_id_recby) AS number_of_recommendations
FROM
    tsa.member m
    JOIN tsa.resort r 
    ON m.resort_id = r.resort_id
    JOIN (SELECT member_id_recby FROM tsa.member) rec
    ON m.member_id = rec.member_id_recby
GROUP BY
    member_id,
    member_gname || ' ' || member_fname,
    m.resort_id,
    resort_name
HAVING
    COUNT(rec.member_id_recby) = (SELECT 
                                    MAX(COUNT(rec.member_id_recby)) 
                                  FROM 
                                    tsa.member m 
                                    JOIN (SELECT member_id_recby FROM tsa.member) rec 
                                    ON m.member_id = rec.member_id_recby 
                                  GROUP BY 
                                    m.member_id)
ORDER BY
    m.resort_id,
    member_id;


/*2(c)*/
-- PLEASE PLACE REQUIRED SQL STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer
SELECT
    poi.poi_id,
    poi_name,
    RPAD(NVL(LPAD(TO_CHAR (MAX(review_rating)), 2, ' '), 'NR'), 10) AS max_rating,
    RPAD(NVL(LPAD(TO_CHAR (MIN(review_rating)), 2, ' '), 'NR'), 10) AS min_rating,
    RPAD(NVL(TO_CHAR(AVG(review_rating), '0.0'), 'NR'), 10) AS avg_rating
FROM
    tsa.point_of_interest poi
    LEFT JOIN tsa.review r
    ON poi.poi_id = r.poi_id
GROUP BY
    poi.poi_id,
    poi_name
ORDER BY
    poi.poi_id;

    
/*2(d)*/
-- PLEASE PLACE REQUIRED SQL STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer
SELECT
    poi_name,
    poi_type_descr,
    town_name,
    lpad('Lat: '
         || TO_CHAR(town_lat, '00.000000')
         || ' Long: '
         || TO_CHAR(town_long, '000.000000'),
         35, ' ')  AS town_location,
    COUNT(review_id) AS reviews_completed,
    CASE
        WHEN COUNT(review_id) = 0 THEN
            'No reviews completed'
        ELSE
            ltrim((TO_CHAR((COUNT(review_id) / (
                SELECT COUNT(review_id) FROM tsa.review
            )) * 100, '90.00') || '%'))
    END AS percent_of_reviews
FROM
    tsa.point_of_interest poi
    NATURAL JOIN tsa.poi_type
    NATURAL JOIN tsa.town
    LEFT JOIN tsa.review r
    ON poi.poi_id = r.poi_id
GROUP BY
    poi_name,
    poi_type_descr,
    town_name,
    'Lat: '
    || TO_CHAR(town_lat, '00.000000')
    || ' Long: '
    || TO_CHAR(town_long, '000.000000')
ORDER BY
    town_name,
    reviews_completed DESC,
    poi_name;
    
    
/*2(e)*/
-- PLEASE PLACE REQUIRED SQL STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer

SELECT
    m1.resort_id,
    resort_name,
    m1.member_no,
    LTRIM(m1.member_gname || ' ' || m1.member_fname) AS member_name,
    TO_CHAR(m1.member_date_joined, 'dd-Mon-yyyy') AS date_joined,
    RPAD(m2.member_no || ' ' || m2.member_gname ||(
        CASE
            WHEN m2.member_gname IS NULL THEN
                m2.member_fname
            ELSE
                ' ' || m2.member_fname
        END), 25, ' ') AS recommended_by_details,
    LPAD('$' || TO_CHAR(SUM(mc_total)), 13, ' ') AS total_charges

FROM 
    tsa.MEMBER m1 
    JOIN tsa.MEMBER m2 ON m2.member_id = m1.member_id_recby
    JOIN tsa.resort R ON m1.resort_id = R.resort_id 
    JOIN tsa.member_charge c1 ON m1.member_id = c1.member_id 

WHERE 
    m1.resort_id IN 
        (SELECT 
            resort_id FROM tsa.resort 
         WHERE 
            town_id != 
                (SELECT 
                    town_id 
                FROM 
                    tsa.town 
                WHERE 
                    UPPER(town_name) = UPPER('Byron Bay') AND UPPER(town_state) = UPPER('NSW')))
             
    AND m1.member_id_recby IS NOT NULL
    
GROUP BY 
    m1.resort_id, 
    resort_name, 
    m1.member_no, 
    m1.member_gname || ' ' || m1.member_fname, 
    TO_CHAR(m1.member_date_joined, 'dd-Mon-yyyy'), 
    (m2.member_no || ' ' || m2.member_gname || (CASE WHEN m2.member_gname IS NULL THEN m2.member_fname ELSE ' ' || m2.member_fname END))
    
HAVING SUM(mc_total) < (SELECT AVG(total_sum) FROM 
                                                (SELECT 
                                                    SUM(mc_total) AS total_sum 
                                                 FROM 
                                                    tsa.member_charge c2 JOIN tsa.MEMBER m3 ON c2.member_id = m3.member_id 
                                                 WHERE 
                                                    m3.resort_id = m1.resort_id GROUP BY m3.member_id))
ORDER BY 
    m1.resort_id, 
    m1.member_no;

                                                    
/*2(f)*/
-- PLEASE PLACE REQUIRED SQL STATEMENT FOR THIS PART HERE
-- ENSURE that your query is formatted and has a semicolon
-- (;) at the end of this answer
SELECT
    resort_id,
    resort_name,
    poi_name,
    town_name AS poi_town,
    RPAD(town_state, 9) AS poi_state,
    RPAD(nvl(to_char(poi_open_time, 'hh:mi pm'), 'Not Applicable'), 16) AS poi_opening_time,
    (TO_CHAR((
        SELECT 
            geodistance(
                (SELECT town_lat
                FROM tsa.town
                WHERE town_id = r.town_id),
                
                (SELECT town_long
                FROM tsa.town
                WHERE town_id = r.town_id),
                
                (SELECT town_lat
                FROM tsa.town
                WHERE town_id = poi.town_id),
                
                (SELECT town_long
                FROM tsa.town
                WHERE town_id = poi.town_id))   
        FROM 
            dual),'990.0') || ' Kms' ) AS distance
        
FROM 
    (tsa.resort r 
    JOIN tsa.town t ON r.town_id = t.town_id) 
    JOIN tsa.point_of_interest poi ON
    
    (SELECT 
        geodistance(
            (SELECT town_lat
            FROM tsa.town
            WHERE town_id = r.town_id),
            
            (SELECT town_long
            FROM tsa.town
            WHERE town_id = r.town_id),
            
            (SELECT town_lat
            FROM tsa.town
            WHERE town_id = poi.town_id),
            
            (SELECT town_long
            FROM tsa.town
            WHERE town_id = poi.town_id))
    FROM 
        dual) <= 100
    
ORDER BY 
    resort_name, 
    distance;



