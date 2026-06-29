--====================================================================
-- Pactics Sewing Lines — Expand to 25 slots + add Line 18
--====================================================================
-- 1. Tops EVERY line up to 25 slots (adds empty slots only — existing
--    machine assignments are never touched).
-- 2. Adds the missing Line 18 to Building 3 (between Line 17 and 19),
--    with 25 slots.
-- Safe to re-run (idempotent). Run ONCE in the Supabase SQL Editor.
--====================================================================

begin;

-- 1. Add Line 18 to Building 3 ---------------------------------------
-- Give it a sort_order between Line 17 and Line 19, but only shift the
-- other lines the FIRST time (when Line 18 doesn't yet exist), so re-runs
-- don't keep drifting the numbers.
do $$
declare s17 int;
begin
  if not exists (select 1 from public.lines where line_id = 'B3-18') then
    select sort_order into s17 from public.lines where line_id = 'B3-17';
    if s17 is null then s17 := 100; end if;
    update public.lines set sort_order = sort_order + 1 where sort_order > s17;
    insert into public.lines (line_id, building_code, label, sort_order)
      values ('B3-18','B3','18', s17 + 1);
  end if;
end $$;

-- 2. Top up every line to 25 slots -----------------------------------
-- For each line, find its current max position and add slots up to 25.
do $$
declare ln record; pos int; maxpos int;
begin
  for ln in select line_id from public.lines loop
    select coalesce(max(position),0) into maxpos from public.line_slots where line_id = ln.line_id;
    pos := maxpos + 1;
    while pos <= 25 loop
      insert into public.line_slots (slot_id, line_id, position)
        values (ln.line_id || '-' || lpad(pos::text,2,'0'), ln.line_id, pos)
        on conflict (slot_id) do nothing;
      pos := pos + 1;
    end loop;
  end loop;
end $$;

commit;

-- 3. Verify ----------------------------------------------------------
-- select count(*) from public.lines;        -- 27 (was 26 + Line 18)
-- select count(*) from public.line_slots;   -- 27 * 25 = 675
-- select l.label, count(s.*) from public.line_slots s
--   join public.lines l on l.line_id = s.line_id
--   where l.building_code='B3' group by l.label, l.sort_order order by l.sort_order;
