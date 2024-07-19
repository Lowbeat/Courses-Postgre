/*Напишите SQL-скрипт, который потокобезопасно в рамках транзакции оформляет посадку пассажира на самолет. Скрипт должен включать:
Проверку существования рейса.
Проверку билета у пассажира на рейс.
Создание нового посадочного талона.*/
BEGIN;
DO $$
DECLARE
		-- These parameters should be inputed from somewhere on the airport reception 
    	ticket_no_var bpchar(13) := '0005435999877';
		flight_id_var int := 57218;
		passanger_id_var varchar(20) := '4013 777777';
	
		boarding_no_var int4;
		seat_no_var varchar(4);
BEGIN
	-- Validate ticket
	IF (SELECT count(*) FROM tickets t WHERE t.ticket_no = ticket_no_var AND t.passenger_id = passanger_id_var FOR UPDATE) != 1 THEN
       -- No ticket found, exception
       RAISE EXCEPTION 'No ticket found';
   	END IF;
   
   	-- Validate flight   
   	IF (SELECT count(*) FROM flights WHERE flight_id = flight_id_var FOR UPDATE) < 1 THEN
       -- No flight found, exception
       RAISE EXCEPTION 'No flight found';
   	END IF;
   
   	-- Generate boarding number
   	SELECT COALESCE(MAX(boarding_no), 0) + 1 INTO boarding_no_var FROM boarding_passes WHERE flight_id = flight_id_var FOR UPDATE;

   	-- Generate seat
  	SELECT s.seat_no INTO seat_no_var
	FROM flights f
	INNER JOIN seats s ON f.aircraft_code = s.aircraft_code
	LEFT JOIN boarding_passes bp ON s.seat_no = bp.seat_no AND bp.flight_id = f.flight_id
	WHERE f.flight_id = flight_id_var
	  AND s.fare_conditions = 'Business'
	  AND bp.seat_no IS NULL
	ORDER BY s.seat_no
	LIMIT 1
	FOR UPDATE;

   	IF seat_no_var IS NULL THEN        
        RAISE EXCEPTION 'No free seats found';
    END IF;
   
   	--Inserting values
    INSERT INTO boarding_passes
	VALUES (ticket_no_var, flight_id_var, boarding_no_var, seat_no_var);
END $$;
COMMIT;

-- Simple checks
SELECT * FROM boarding_passes bp 
WHERE bp.ticket_no = '0005435999877'