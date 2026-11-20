-- 007 · Security hardening. Safe to run once, after 006.

-- 1) No more "first signup becomes admin".
--    Every new account starts unapproved. Create your first admin by hand (see bottom of this file).
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, first_name, last_name, employee_id, approved)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    nullif(new.raw_user_meta_data->>'employee_id', ''),
    false
  );
  return new;
end $$;

-- 2) A prescription can only be dispensed once, and only while Pending
--    (before: dispensing twice deducted stock twice, and cancelled prescriptions could be dispensed).
create or replace function dispense_prescription(p_rx uuid) returns void
language plpgsql security invoker as $$
declare it record; need int; b record; take int; cur rx_status;
begin
  if not is_admin() then raise exception 'Not authorized'; end if;
  select status into cur from prescriptions where id = p_rx for update;
  if not found then raise exception 'Prescription not found.'; end if;
  if cur <> 'Pending' then raise exception 'This prescription is already % and cannot be dispensed.', lower(cur::text); end if;
  for it in select * from prescription_items where prescription_id = p_rx loop
    need := it.quantity;
    for b in select * from medicine_batches
             where medicine_id = it.medicine_id and remaining > 0
             order by expiry_date for update loop
      exit when need = 0;
      take := least(need, b.remaining);
      update medicine_batches set remaining = remaining - take where id = b.id;
      need := need - take;
    end loop;
    if need > 0 then raise exception 'Insufficient stock for medicine %', it.medicine_id; end if;
  end loop;
  update prescriptions set status = 'Dispensed' where id = p_rx;
end $$;

-- 3) Audit the money and medicine tables too (payments could previously be edited/deleted untraced).
create trigger audit_payments      after insert or update or delete on payments      for each row execute function audit_change();
create trigger audit_invoice_items after insert or update or delete on invoice_items for each row execute function audit_change();
create trigger audit_prescriptions after insert or update or delete on prescriptions for each row execute function audit_change();
create trigger audit_batches       after insert or update or delete on medicine_batches for each row execute function audit_change();
create trigger audit_profiles      after insert or update or delete on profiles      for each row execute function audit_change();
create trigger audit_er_visits     after insert or update or delete on er_visits     for each row execute function audit_change();

-- ---------------------------------------------------------------------
-- CREATE YOUR FIRST ADMIN (new deployments only):
--   1. Sign up once on /register with your own email.
--   2. Run this in the SQL Editor, using that email:
--
--   update profiles set approved = true
--   where id = (select id from auth.users where email = 'you@example.com');
-- ---------------------------------------------------------------------
