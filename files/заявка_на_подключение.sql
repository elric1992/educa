SELECT a.public_uid,
       u.rblock,
       CASE WHEN s.user_id IS NULL THEN a.create_type ELSE 1 END,
       a.id,
       unix_timestamp() - unix_timestamp(a.create_date) gap,
       SUM(bh.qnt)                                      sum
FROM connecting.applications a
         LEFT JOIN bills_history bh ON a.public_uid = bh.uid
         LEFT JOIN users u ON u.id = a.public_uid
         LEFT JOIN stock.get_promo_code() s ON s.user_id = a.public_uid
WHERE a.type = 3
  AND a.state IN (SELECT id FROM connecting.state WHERE state IN (1, 2))
  --AND unix_timestamp() - unix_timestamp(a.create_date) < 1209600
GROUP BY 1, 2, 3, 4, 5;


SELECT a.id,
       surname,
       name,
       middle_name,
       did,
       porch,
       floor,
       apartment,
       did_com,
       private_house,
       cm.phone                                                                                 phone_main,
       cs.phone                                                                                 phone_sup,
       e_mail                                                                                   email,
       GREATEST(tariff, 0)                                                                      tariff,
       type,
       public_uid,
       array_to_string(serv, ',')                                                               serv,
       array_to_string(tv_pack, ',')                                                            tv_pack,
       type,
       s.id         as                                                                          state_id,
       sg.state_name || CASE WHEN s.sub_state != '' THEN '. ' || s.sub_state || '.' ELSE '' END state,
       loyalty,
       current_provider,
       current_provider_price,
       tv_count,
       date_trunc('minutes', next_call_date)                                                    next_call_date,
       CASE WHEN s.state IN (5, 7) THEN 1 ELSE 0 END                                            closed,
       CASE WHEN is_smart THEN 'Да' ELSE 'Нет' END                                              is_smart,
       competitor,
       CASE WHEN s.state = 7 THEN 1 ELSE 0 END                                                  fail,
       CASE WHEN cable_avail @> ARRAY [1] THEN 'Есть витая пара' ELSE 'Нет витой пары' END || ', ' ||
       CASE WHEN cable_avail @> ARRAY [3] THEN 'Есть коаксиал' ELSE 'Нет коаксиала' END         cable_avail,
       CASE WHEN s.state = 4 THEN 1 ELSE 0 END                                                  connect,
       house_start = 4                                                                          house_start,
       have_tv = 1                                                                              have_tv,
       have_ctv = 1                                                                             have_ctv,
       CASE WHEN a.agent_id <> a.new_agent AND a.new_agent > 0 THEN e.full_name ELSE '' END     new_agent,
       tv_pack                                                                                  tv_pack_m,
       a.products_service_ids,
       str.city_id,
       ea.full_name as                                                                          agent,
       a.birthday,
       a.comm       as                                                                          first_comment
FROM connecting.applications a
         LEFT JOIN connecting.contacts cm ON a.id = cm.appl_id AND cm.main
         LEFT JOIN connecting.contacts cs ON a.id = cs.appl_id AND NOT cs.main
         LEFT JOIN connecting.state s ON s.id = a.state
         LEFT JOIN staff.employees e ON e.id = a.new_agent AND a.new_agent > 0
         LEFT JOIN staff.employees ea ON ea.id = a.agent_id
         LEFT JOIN connecting.state_group sg ON sg.id = s.state
         LEFT JOIN address.dom d ON d.id = a.did
         LEFT JOIN address.street str ON str.id = d.s_id
         LEFT JOIN account.competitors c ON c.id = a.current_provider_id
WHERE a.id = 133336
LIMIT 1;

with max_tariff_id as (select max(id) max_id, uid
                       from history.tariff
                       group by uid),
     current_user_tariff as (select mti.uid, t.tariff_new, tc.tname, tc.abonpay
                             from max_tariff_id mti
                                      left join history.tariff t on t.id = mti.max_id
                                      left join tariffs_current tc on tc.tid = t.tariff_new)
select app.id                                                               as id_заявки,
       app.public_uid                                                       as id_абонента,
       to_timestamp(u.reg_date)                                             as Дата_регистрации_абонента,
       app.create_date                                                      as Дата_создания_заявки,
       to_timestamp(bh.max_date)                                            as Дата_последнего_платежа,
       case when cut.tariff_new is null then tc.tid else cut.tariff_new end as ID_тарифа,
       case when cut.tname is null then tc.tname else cut.tname end         as Наименование_тарифа,
       case when cut.abonpay is null then tc.abonpay else cut.abonpay end   as Абонентская_палата_по_тарифу
from connecting.applications app
         left join connecting.state st on st.id = app.state
         left join users u on u.id = app.public_uid
         left join (select max(date) max_date, uid
                    from bills_history
                    group by uid) bh on bh.uid = app.public_uid
         left join current_user_tariff cut on cut.uid = app.public_uid
         left join tariffs_current tc on tc.tid = app.tariff
where app.type = 3
  and app.close_date is null
  and app.state != 17
  and bh.max_date is not null
order by 5 DESC;

with max_tariff_id as (select max(id) max_id, uid
                       from history.tariff
                       group by uid)
select mti.uid, t.tariff_new, tc.tname, tc.abonpay
from max_tariff_id mti
         left join history.tariff t on t.id = mti.max_id
         left join tariffs_current tc on tc.id = t.tariff_new;