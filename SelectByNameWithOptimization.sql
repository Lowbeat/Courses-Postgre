/*Напишите запрос для поиска билетов по имени пассажиров. Оптимизируйте скорость его выполнения.
Приложите результаты выполнения команд EXPLAIN ANALYZE до и после оптимизации.*/

EXPLAIN ANALYZE
SELECT * FROM tickets
WHERE lower(passenger_name) = lower('SERGEY AFANASEV');
/*
Gather  (cost=1000.00..70351.53 rows=14749 width=104) (actual time=0.208..674.722 rows=1074 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on tickets  (cost=0.00..67876.63 rows=6145 width=104) (actual time=0.548..670.834 rows=358 loops=3)
        Filter: (lower(passenger_name) = 'sergey afanasev'::text)
        Rows Removed by Filter: 982929
Planning Time: 0.058 ms
Execution Time: 674.809 ms
*/

-- По идее лучше всего должно работать с хешем, но у меня локально почему-то работает с обычным индексом лучше (даже примеры из уроков)
CREATE INDEX idx_tickets_passenger_name ON tickets USING HASH (lower(passenger_name));
EXPLAIN ANALYZE
SELECT * FROM tickets
WHERE lower(passenger_name) = lower('SERGEY AFANASEV');
/*
Bitmap Heap Scan on tickets  (cost=410.30..32352.59 rows=14749 width=104) (actual time=0.153..0.967 rows=1074 loops=1)
  Recheck Cond: (lower(passenger_name) = 'sergey afanasev'::text)
  Heap Blocks: exact=1061
  ->  Bitmap Index Scan on idx_tickets_passenger_name  (cost=0.00..406.62 rows=14749 width=0) (actual time=0.077..0.077 rows=1074 loops=1)
        Index Cond: (lower(passenger_name) = 'sergey afanasev'::text)
Planning Time: 0.096 ms
Execution Time: 0.998 ms
*/
DROP INDEX idx_tickets_passenger_name;
CREATE INDEX idx_tickets_passenger_name ON tickets (lower(passenger_name));
EXPLAIN ANALYZE
SELECT * FROM tickets
WHERE lower(passenger_name) = lower('SERGEY AFANASEV');
/*
Bitmap Heap Scan on tickets  (cost=170.73..32113.02 rows=14749 width=104) (actual time=0.152..0.728 rows=1074 loops=1)
  Recheck Cond: (lower(passenger_name) = 'sergey afanasev'::text)
  Heap Blocks: exact=1061
  ->  Bitmap Index Scan on idx_tickets_passenger_name  (cost=0.00..167.05 rows=14749 width=0) (actual time=0.076..0.077 rows=1074 loops=1)
        Index Cond: (lower(passenger_name) = 'sergey afanasev'::text)
Planning Time: 0.155 ms
Execution Time: 0.760 ms
*/
DROP INDEX idx_tickets_passenger_name;