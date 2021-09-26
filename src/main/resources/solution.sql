-- 1. Выведите список всех стран и количество городов в них
select country.name, count(*) as count_city from country
join city  on country.id = city.id_country
group by country.name;

-- 2. Получите список женских имен, встречающихся чаще 3-х раз
select person.name from person
where person.sex = 'F'
group by person.name
having count(person.name) > 3;

-- 3. Выведите список разведенных мужчин и одиноких женщин, проживающих в городе Lonzee
select person.name, person.surname from person
join city on person.id_city = city.id
where status = 'Divorced' and city.name = 'Lonzee';

-- 4. Выведите список стран, в которых количество разведенных мужчин превышает
--количество одиноких женщин
select country.name, count(person.sex = 'M'), count(person.sex = 'F') from country
join city on country.id = city.id_country
join person on city.id = person.id_city
where person.status = 'Divorced'
group by country.name
-- having count(person.sex = 'M') > count(person.sex = 'F')


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


-- 7. Найдите человека, которому была отправлена самая тяжелая посылка
select * from person
left join parcel p on person.id = p.id_person_to
where p.weight = (select max(weight) from parcel);

-- 8. Определите количество людей, у которых в адресе указан абонентский ящик (P.O. Box)
select count(*) from person
where person.address like 'P.O. Box%';

-- 9. Выведите таблицу с данными о суммарном весе международных пересылок с разбивкой по месяцам.

-- 10. Выведите список людей, которые никогда не получали посылки
select * from person
WHERE person.id NOT IN (select parcel.id_person_to from parcel);
--второе решение
select * from person
left join parcel p on person.id = p.id_person_to
where id_person_to IS NULL;

-- 11. Выведите список людей, проживающих во Франции, которые получали посылки, но сами никогда их не отправляли.



