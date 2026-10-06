create extension if not exists pg_cron;

create table if not exists public.guestbook_messages (
    id bigint generated always as identity primary key,
    name text not null check (char_length(name) between 1 and 30),
    message text not null check (char_length(message) between 1 and 180),
    created_at timestamptz not null default now(),
    constraint guestbook_name_clean check (
        name !~* '\m(anjing|asu|bangsat|bajingan|tolol|goblok|kontol|memek|ngentot|jancok|tai|fuck|shit|bitch|asshole)\M'
    ),
    constraint guestbook_message_clean check (
        message !~* '\m(anjing|asu|bangsat|bajingan|tolol|goblok|kontol|memek|ngentot|jancok|tai|fuck|shit|bitch|asshole)\M'
    )
);

alter table public.guestbook_messages enable row level security;

grant select, insert on public.guestbook_messages to anon;
grant usage, select on sequence public.guestbook_messages_id_seq to anon;

drop policy if exists "Anyone can read recent guestbook messages" on public.guestbook_messages;
create policy "Anyone can read recent guestbook messages"
    on public.guestbook_messages for select to anon
    using (created_at >= now() - interval '24 hours');

drop policy if exists "Anyone can sign the guestbook" on public.guestbook_messages;
create policy "Anyone can sign the guestbook"
    on public.guestbook_messages for insert to anon
    with check (
        created_at >= now() - interval '24 hours'
        and created_at <= now()
    );

select cron.unschedule(jobid)
from cron.job
where jobname = 'delete-expired-guestbook-messages';

select cron.schedule(
    'delete-expired-guestbook-messages',
    '*/10 * * * *',
    $$delete from public.guestbook_messages where created_at < now() - interval '24 hours';$$
);