# 06/04/2021: match name_id with action string
select a.id, m.string as 'action', a.name_id, a.owner_guid
from annotations a
inner join metastrings m on a.name_id = m.id;

# 06/04/2021: count actions in annotations and objects_property tables for each user
select *, (n.create+n.comment+n.edit+n.view) as 'total_actions' from (
select owner_guid, sum(o.action = 'create') as 'create', sum(o.action = 'generic_comment') as 'comment', sum(o.action = 'revised_docs') as 'edit', sum(o.action = 'viewed_lds') as 'view'
from (
select m.string as 'action', owner_guid from annotations a
inner join metastrings m on a.name_id = m.id
union all
select 'create' as 'action' , owner_guid from objects_property
) as o
group by owner_guid) as n;

# 10/04/2021: all actions by each user - first eventlog (user, action, timestamp)
select a.owner_guid, m.string as 'action', from_unixtime(a.time_created)as 'timestamp'
from annotations a
inner join metastrings m on a.name_id = m.id
where (a.name_id = 2338 or a.name_id = 2021 or a.name_id = 2052)
union(
select owner_guid, 'create', from_unixtime(time_created) as 'timestamp'
from objects_property
)
order by owner_guid asc, timestamp asc;

# eventlog as (user, action, LD owner, timestamp)
# actions: login, create, create from duplicate, view, comment, edit, delete, publish, all shares
# individual queries below
select performed_by_guid, event, owner_guid, from_unixtime(timestamp) as 'timestamp' from 
(select a.performed_by_guid, a.event, a.owner_guid, a.time_created as 'timestamp' from system_log a
where (a.event like 'delete' and a.object_subtype like 'LdS')
or a.event like 'login'
union all
select owner_guid as performed_by_guid, 'create from duplicate' as 'event', owner_guid, time_created as 'timestamp' from metadata
where name_id = 2232
union all
select a.performed_by_guid, a.event, a.owner_guid, a.time_created as 'timestamp' from system_log a
where a.event like 'create' and a.object_subtype = 'LdS' and not exists(
select owner_guid, 'create' as event, owner_guid, time_created as 'timestamp' from metadata b
where name_id = 2232 and a.object_id = b.entity_guid)
union all
select a.owner_guid as 'performed_by_guid', m.string as 'event', o.owner_guid, a.time_created as 'timestamp'
from annotations a
inner join metastrings m on a.name_id = m.id
inner join objects_property o on a.entity_guid = o.guid
where a.name_id = 2338 or a.name_id = 2021 or a.name_id = 2052
union all
select owner_guid as 'performed_by_guid', 'publish' as 'event', owner_guid, time_created as 'timestamp' from metadata b
where b.name_id = 2522 #mooc1
#where b.name_id = 2449 #mooc2
union all
select a.owner_guid as 'performed_by_guid', m.string as 'event', o.owner_guid, a.time_created as 'timestamp' from annotations a
inner join metastrings m on a.name_id = m.id
inner join objects_property o on a.entity_guid = o.owner_guid
where a.name_id = 200879 or a.name_id = 200764 or a.name_id = 200744 or a.name_id = 202635 or a.name_id = 202606 #mooc1
#where a.name_id = 3101 or a.name_id = 2372 or a.name_id = 3175 or a.name_id = 170029 or a.name_id = 170013 or a.name_id = 169997 #mooc2
group by a.id) o
where o.performed_by_guid != 0 
and timestamp < 1403301600 #mooc1
#and timestamp < 1419023000 #mooc2
order by timestamp asc, performed_by_guid asc, event asc
limit 100000;

# action count by user using the mega-query from above
select performed_by_guid, 2 as mooc, sum(o.event = 'create') as 'create', sum(o.event = 'generic_comment') as 'comment', sum(o.event = 'revised_docs') as 'edit', 
sum(o.event = 'viewed_lds') as 'view', sum(o.event = 'create from duplicate') as 'create from duplicate', sum(o.event = 'login') as 'login', 
sum(o.event = 'publish') as 'publish', sum(o.event = 'viewed_profile') as 'viewed_profile', sum(o.event = 'delete') as 'delete', 
sum(o.event = 'share_add_editor') as 'share_add_editor', sum(o.event = 'share_add_viewer') as 'share_add_viewer', 
sum(o.event = 'share_add_acv') as 'share_add_acv', sum(o.event = 'share_del_viewer') as 'share_del_viewer', sum(o.event = 'share_remove_acv') as 'share_remove_acv' 

from (select a.performed_by_guid, a.event, a.owner_guid, a.time_created as 'timestamp' from system_log a
where (a.event like 'delete' and a.object_subtype like 'LdS')
or a.event like 'login'
union all
select owner_guid as performed_by_guid, 'create from duplicate' as 'event', owner_guid, time_created as 'timestamp' from metadata
where name_id = 2232
union all
select a.performed_by_guid, a.event, a.owner_guid, a.time_created as 'timestamp' from system_log a
where a.event like 'create' and a.object_subtype = 'LdS' and not exists(
select owner_guid, 'create' as event, owner_guid, time_created as 'timestamp' from metadata b
where name_id = 2232 and a.object_id = b.entity_guid)
union all
select a.owner_guid as 'performed_by_guid', m.string as 'event', o.owner_guid, a.time_created as 'timestamp'
from annotations a
inner join metastrings m on a.name_id = m.id
inner join objects_property o on a.entity_guid = o.guid
where a.name_id = 2338 or a.name_id = 2021 or a.name_id = 2052
union all
select owner_guid as 'performed_by_guid', 'publish' as 'event', owner_guid, time_created as 'timestamp' from metadata b
#where b.name_id = 2522 #mooc1
where b.name_id = 2449 #mooc2
union all
select distinct a.owner_guid as 'performed_by_guid', m.string as 'event', o.owner_guid, a.time_created as 'timestamp' from annotations a
inner join metastrings m on a.name_id = m.id
inner join objects_property o on a.entity_guid = o.owner_guid
#where a.name_id = 200879 or a.name_id = 200764 or a.name_id = 200744 or a.name_id = 202635 or a.name_id = 202606 #mooc1
where a.name_id = 3101 or a.name_id = 2372 or a.name_id = 3175 or a.name_id = 170029 or a.name_id = 170013 or a.name_id = 169997 #mooc2
group by a.id) o

where o.performed_by_guid != 0 
#and timestamp < 1403301600 #mooc1
and timestamp < 1419023000 #mooc2
group by performed_by_guid
limit 100000; 


# individual queries:
# extract delete and login actions from system_log
select a.performed_by_guid, a.event, a.owner_guid, a.time_created as 'timestamp' from system_log a
where (a.event like 'delete' and a.object_subtype like 'LdS')
or a.event like 'login';

# extract create from duplicate
select owner_guid as performed_by_guid, 'create from duplicate' as 'event', owner_guid, time_created as 'timestamp' from metadata
where name_id = 2232;

# extract create (excluding from duplicate)
select a.performed_by_guid, a.event, a.owner_guid, a.time_created as 'timestamp' from system_log a
where a.event like 'create' and a.object_subtype = 'LdS' and not exists(
select owner_guid, 'create' as event, owner_guid, time_created as 'timestamp' from metadata b
where name_id = 2232 and a.object_id = b.entity_guid);

# view, comment, edit and sharing from annotations
select a.owner_guid as 'performed_by_guid', m.string as 'event', o.owner_guid, a.time_created as 'timestamp'
from annotations a
inner join metastrings m on a.name_id = m.id
inner join objects_property o on a.entity_guid = o.guid
where a.name_id = 2338 or a.name_id = 2021 or a.name_id = 2052;

# publishing data from metadata
select owner_guid as 'performed_by_guid', 'publish' as 'event', owner_guid, time_created as 'timestamp' from metadata b
#where b.name_id = 2522; #mooc1
where b.name_id = 2449; #mooc2

# sharing + view profile from annotations
select a.id, a.owner_guid as 'performed_by_guid', m.string as 'event', o.owner_guid, a.time_created as 'timestamp' from annotations a
inner join metastrings m on a.name_id = m.id
inner join objects_property o on a.entity_guid = o.owner_guid
#where a.name_id = 200879 or a.name_id = 200764 or a.name_id = 200744 or a.name_id = 202635 or a.name_id = 202606 #mooc1
where a.name_id = 3101 or a.name_id = 2372 or a.name_id = 3175 or a.name_id = 170029 or a.name_id = 170013 or a.name_id = 169997 #mooc2
group by a.id;