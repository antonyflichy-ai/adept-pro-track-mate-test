create table if not exists public.invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  role text not null check (role in ('Tuteur','Responsable d’agence','RH')),
  agency text,
  invited_by uuid not null references auth.users(id) on delete restrict,
  auth_user_id uuid references auth.users(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','accepted','expired','cancelled')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz
);

create unique index if not exists invitations_one_pending_per_email
  on public.invitations (lower(email))
  where status = 'pending';

alter table public.invitations enable row level security;

create policy "masters can read invitations"
  on public.invitations for select
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'Formateur Master'
    )
  );

create policy "masters can cancel invitations"
  on public.invitations for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'Formateur Master'
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'Formateur Master'
    )
  );

create or replace function public.mark_invitation_accepted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.invitations
     set status = 'accepted',
         auth_user_id = new.id,
         accepted_at = coalesce(accepted_at, now())
   where lower(email) = lower(new.email)
     and status = 'pending';
  return new;
end;
$$;

drop trigger if exists on_auth_user_invitation_accepted on auth.users;
create trigger on_auth_user_invitation_accepted
after update of last_sign_in_at on auth.users
for each row
when (new.last_sign_in_at is distinct from old.last_sign_in_at and new.last_sign_in_at is not null)
execute function public.mark_invitation_accepted();
