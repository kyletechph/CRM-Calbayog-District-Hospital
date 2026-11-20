-- CDH: make yourself an approved admin
-- Run in Supabase: SQL Editor -> New query -> paste -> change the email -> Run
-- It works even if you don't know the exact column names in "profiles".

do $$
declare
  my_email text := 'CDHadmin@gmail.com';   -- <-- CHANGE THIS to the email you log in with
  my_id    uuid;
  col      text;
  dtype    text;
  val      text;
  changed  text := '';
begin
  select id into my_id from auth.users where email = my_email;

  if my_id is null then
    raise notice 'No user found with email %. Check the email in Authentication -> Users.', my_email;
    return;
  end if;

  -- 1. Make sure you have a row in profiles
  if not exists (select 1 from profiles where id = my_id) then
    begin
      insert into profiles (id) values (my_id);
      changed := changed || 'created-row ';
    exception when others then
      raise notice 'Could not create profile row: %', sqlerrm;
    end;
  end if;

  -- 2. Set role to admin
  begin
    update profiles set role = 'admin' where id = my_id;
    changed := changed || 'role=admin ';
  exception when others then
    raise notice 'Could not set role: %', sqlerrm;
  end;

  -- 3. Turn on any true/false approval columns
  for col, dtype in
    select column_name, data_type
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name in ('is_verified','verified','is_approved','approved','is_active','active','is_admin')
  loop
    if dtype = 'boolean' then
      execute format('update profiles set %I = true where id = $1', col) using my_id;
      changed := changed || col || '=true ';
    end if;
  end loop;

  -- 4. Set any status-style column to an approved value
  for col in
    select column_name
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name in ('status','approval_status','verification_status')
  loop
    foreach val in array array['approved','active','verified'] loop
      begin
        execute format('update profiles set %I = %L where id = $1', col, val) using my_id;
        changed := changed || col || '=' || val || ' ';
        exit;
      exception when others then
        null; -- that value isn't allowed, try the next one
      end;
    end loop;
  end loop;

  raise notice 'Done for %. Changed: %', my_email, changed;
end $$;

-- Shows the table so you can check your row
select * from profiles;