# Calbayog District Hospital — Hospital Management System

Next.js 16 (App Router) · React 19 · Tailwind CSS · Supabase (Postgres + Auth + Storage)

## Setup
1. Create a project at https://supabase.com
2. In **SQL Editor**, run these files **in order**:
   1. `supabase/schema.sql` (base tables, auth profiles, security rules)
   2. `supabase/migrations/002_admissions.sql`
   3. `supabase/migrations/003_er_triage.sql`
   4. `supabase/migrations/004_vitals.sql`
   5. `supabase/migrations/005_diagnostics.sql`
   6. `supabase/migrations/006_philhealth_claims.sql`
   7. `supabase/migrations/007_security_hardening.sql`
   8. *(optional demo data)* `supabase/seed.sql`, then `supabase/seed_features.sql`
3. `cp .env.example .env.local` and paste your project URL + anon key (Project Settings → API)
4. `npm install && npm run dev` → http://localhost:3000
5. Click **Create an admin account**. New accounts are never auto-approved. Approve your own first account with the SQL snippet at the bottom of
   `007_security_hardening.sql`; later sign-ups are approved in **Settings → Administrator access**.

Already ran `schema.sql` earlier? Don't run it again — just run the new migration files you haven't run yet.

## Modules
| Area | What it does |
| --- | --- |
| Dashboard | Today’s overview, calendar, bed occupancy |
| Patients | Directory, registration, profile |
| Admissions | Assign beds, inpatient census, discharge |
| Emergency | ER triage queue (5 levels), start treatment, discharge, transfer |
| Vital signs | Nurse entry with abnormal-reading highlights |
| Appointments | Weekly view, queue, new appointment |
| Records | Clinical notes with attachments, sign, PDF export |
| Lab & imaging | Requests, priorities, results |
| Billing | Itemized invoices, payments, printable statement |
| PhilHealth | Claims tracker from filing to reimbursement |
| Pharmacy | Inventory, stock intake, prescriptions (print + dispense) |
| Staff | Directory, schedules, add staff |
| Settings | Hospital profile, notifications, administrator approval, audit log |

## Notes
- Every table uses Row Level Security: only approved admins can read or write patient data.
- Record attachments go to a private Storage bucket named `records` (created by `schema.sql`).
- In development, turn off "Confirm email" in Supabase → Authentication → Providers → Email.
- PDFs (records, prescriptions, billing statements) are generated on the server with `pdf-lib`.
  The billing statement is not an official receipt.
- Vital-sign highlights use simple adult screening ranges as a prompt for a second look, not a diagnosis.

