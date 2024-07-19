/*Напишите SQL-скрипт, который потокобезопасно в рамках транзакции создает новое бронирование. Скрипт должен включать:
Создание нового бронирования.
Создание нового билета.
Привязка билета к перелету.*/

-- Function for random book_ref
CREATE OR REPLACE FUNCTION get_next_bpchar6() RETURNS bpchar(6) AS $$
DECLARE
    last_val bpchar(6);
    next_val bpchar(6);
    num_part int8;
BEGIN
    -- Select the last value from the table
    SELECT book_ref INTO last_val
    FROM bookings
    ORDER BY book_ref DESC
    LIMIT 1;

    -- If there's no last value, start from '000000'
    IF last_val IS NULL THEN
        next_val := '000001';
	ELSE
        -- Initialize next_val as the increment of last_val
        num_part := ('x' || last_val)::bit(24)::bigint + 1;
        next_val := LPAD(to_hex(num_part), 6, '0');
        
        -- Check if the next_val already exists and increment until a unique value is found
        WHILE EXISTS (SELECT 1 FROM bookings WHERE book_ref = next_val) LOOP
            num_part := num_part + 1;
            next_val := LPAD(to_hex(num_part), 6, '0');
        END LOOP;
    END IF;

    RETURN next_val;
END;
$$ LANGUAGE plpgsql;

-- Function checking line
--SELECT get_next_bpchar6();

-- Start of the transaction
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

	DO $$
		DECLARE 
			book_ref_var bpchar(6);
		 	ticket_no_var bpchar(13);
		 	amount_var numeric(10, 2);
	
		BEGIN
		-- Create a new row in the bookings table
		-- TODO : Add locks?
		--LOCK TABLE inventory IN ACCESS SHARE MODE;
	
		-- Fill vars
		SELECT get_next_bpchar6() INTO book_ref_var;
		SELECT ROUND((random() * 999.99)::numeric, 2) INTO amount_var;
			
		-- Inserting values
		INSERT INTO bookings
		VALUES (book_ref_var, now(), amount_var);
		
		-- Create a new row in the tickets table
		-- TODO : Add locks?
		--LOCK TABLE inventory IN ACCESS SHARE MODE;
	
		-- Generate a new ticket number
		SELECT LPAD(to_hex(('x' || (SELECT ticket_no
	    FROM tickets
	    ORDER BY ticket_no DESC
	    LIMIT 1 FOR UPDATE))::bit(52)::bigint + 1), 13, '0') INTO ticket_no_var;
   
		INSERT INTO tickets
		VALUES (ticket_no_var, book_ref_var, '4013 777777', 'SERGEY AFANASEV', '{"phone": "88005553535"}');
	
		-- Create a binding in the ticket_flights table
		INSERT INTO ticket_flights
		VALUES (ticket_no_var, (SELECT flight_id FROM flights ORDER BY scheduled_departure DESC LIMIT 1), 'Business', amount_var);
	END $$;
COMMIT;

-- Simple results checker
SELECT * FROM bookings b 
JOIN tickets t ON b.book_ref = t.book_ref
JOIN ticket_flights tf ON tf.ticket_no = t.ticket_no 
ORDER BY b.book_date DESC 
LIMIT 3;


 