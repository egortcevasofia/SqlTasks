-- 1. Выведите список всех стран и количество городов в них
select country.name, count(city) as count_city
from country
left join city on country.id = city.id_country
group by country.name;

-- 2. Получите список женских имен, встречающихся чаще 3-х раз
select person.name from person
where person.sex = 'F'
group by person.name
having count(person.name) > 3;

-- 3. Выведите список разведенных мужчин и одиноких женщин, проживающих в городе Lonzee
select person.name, person.surname
from person
join city on person.id_city = city.id
where (status = 'Single' and sex = 'F'and city.name = 'Lonzee')
   or (status = 'Divorced' and sex = 'M' and city.name = 'Lonzee');

-- 4. Выведите список стран, в которых количество разведенных мужчин превышает количество одиноких женщин
with men as (
    select country.name, count(person) cm
    from country
             join city on country.id = city.id_country
             join person on city.id = person.id_city
    where (person.status = 'Divorced' and person.sex = 'M')
    group by country.id),

     women as (
         select country.name, count(person) cw
         from country
                  join city on country.id = city.id_country
                  join person on city.id = person.id_city
         where (person.status = 'Single' and person.sex = 'F')
         group by country.id)

select men.name, cm from men
join women on women.name = men.name
where cm > cw;


-- 5. Выведите посылки, отправленные в мае 2020 года из Франции в Бельгию
select * from parcel
join person pfrom on parcel.id_person_from = pfrom.id
join person pto on parcel.id_person_to = pto.id
join city cityfrom on pfrom.id_city = cityfrom.id
join city cityto on pto.id_city = cityto.id
join country cfrom on cityfrom.id_country = cfrom.id
join country cto on cityto.id_country = cto.id
where cfrom.name = 'France' and cto.name = 'Belgium'
and parcel.departure_date between '2020-05-01 00:00:00' and '2020-05-31 23:59:59';

-- 6. Выведите список посылок, находящихся в процессе доставки 1 января 2019 года
select * , departure_date + make_interval(hours := delivery_time) as arrival_time from parcel
where '2019-01-01' between  departure_date and departure_date + make_interval(hours := delivery_time);

-- 7. Найдите человека, которому была отправлена самая тяжелая посылка
select * from person
left join parcel p on person.id = p.id_person_to
where p.weight = (select max(weight) from parcel);

-- 8. Определите количество людей, у которых в адресе указан абонентский ящик (P.O. Box)
select count(*) from person
where person.address like '%P.O. Box%';

-- 9. Выведите таблицу с данными о суммарном весе международных пересылок с разбивкой по месяцам.
select sum(weight) as sum_weight, EXTRACT(YEAR FROM departure_date), EXTRACT(MONTH FROM departure_date)
from parcel
         join person pfrom on parcel.id_person_from = pfrom.id
         join person pto on parcel.id_person_to = pto.id
         join city cityfrom on pfrom.id_city = cityfrom.id
         join city cityto on pto.id_city = cityto.id
         join country cfrom on cityfrom.id_country = cfrom.id
         join country cto on cityto.id_country = cto.id
where cfrom != cto
GROUP BY  EXTRACT(year FROM departure_date), EXTRACT(MONTH FROM departure_date);

-- 10. Выведите список людей, которые никогда не получали посылки
select * from person
WHERE person.id NOT IN (select parcel.id_person_to from parcel);
--второе решение
select * from person
left join parcel p on person.id = p.id_person_to
where id_person_to IS NULL;

-- 11. Выведите список людей, проживающих во Франции, которые получали посылки, но сами никогда их не отправляли.
select per.*
from person per
         join city cit on per.id_city = cit.id
         join country c on cit.id_country = c.id
where c.id = 4
  and per.id in (select id_person_to --есть в персон_ту но нет в персон_фром
                 from parcel
                     except
                 select id_person_from
                 from parcel);

--12. Выведите 10 первых значений функции факториал (1, 2, 6, 24, 120 и т.д.)
WITH RECURSIVE temp (n, fact) AS
                   (SELECT 0, 1
                    UNION ALL
                    SELECT n+1, (n+1)*fact FROM temp
                    WHERE n < 9)
SELECT * FROM temp;

-- 13. Две посылки объединяются в цепочку, если вторая посылка отправлена в тот же день,
--     когда получена первая посылка и страна отправления второй посылки совпадает со страной
--     прибытия первой посылки. Все посылки в цепочке должны быть международными.
--     Напишите запрос, который находит самые длинные цепочки (по количеству объединенных посылок)
--     и выводит их в виде последовательного объединения кодов посылок (например 1157 - 2195 - 2989)

CREATE VIEW new_table AS  select parcel.id parcel_id,
                                 date(departure_date + make_interval(hours := delivery_time)) delivery_date_parent,
                                 date(parcel.departure_date) departure_date_cildren,
                                 cto.id country_to_parent,
                                 cfrom.id country_from_cildren
                          from parcel
                                   join person pfrom on parcel.id_person_from = pfrom.id
                                   join person pto on parcel.id_person_to = pto.id
                                   join city cityfrom on pfrom.id_city = cityfrom.id
                                   join city cityto on pto.id_city = cityto.id
                                   join country cfrom on cityfrom.id_country = cfrom.id
                                   join country cto on cityto.id_country = cto.id
                          where cto != cfrom
                          order by delivery_date_parent asc;

select * from new_table;

WITH RECURSIVE temp(child_country_id, parent_country_id,
                    child_date_id, parent_date_id,
                    depth, path) AS (
    SELECT nt.country_from_cildren, nt.country_to_parent,
           nt.departure_date_cildren, nt.delivery_date_parent,
           1::INT AS depth, nt.parcel_id::TEXT AS path
    FROM new_table AS nt
--     where delivery_date_parent != '2010-01-09'

    UNION all

    SELECT nt.country_from_cildren, nt.country_to_parent,
           nt.departure_date_cildren, nt.delivery_date_parent,
           t.depth + 1 AS depth, (t.path || '->' || nt.parcel_id::TEXT)
    FROM temp AS t, new_table AS nt
    WHERE nt.country_from_cildren = t.parent_country_id and nt.departure_date_cildren = t.parent_date_id
)
SELECT * FROM temp
order by temp.depth desc;



-- 14. Напишите запрос добавления столбца для хранения округленного веса в таблицу parcel и напишите
--     запрос, сохраняющий в этот столбец округленных вес посылки. Вес посылок до 1 кг должен округляться до 100 грамм,
--     1 - 10 кг до 250 грамм, свыше 10 кг до 500 грамм

select * from parcel;
ALTER TABLE parcel ADD COLUMN round_weight integer;

UPDATE parcel SET round_weight = case
                                     when (parcel.weight between 0 and 1000) then (round(weight / 100.0) * 100)
                                     when (parcel.weight between 1001 and 10000) then (round(weight / 250.0) * 250)
                                     else (round(parcel.weight / 500.0) * 500) end;