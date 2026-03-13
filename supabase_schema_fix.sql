-- ============================================================
--  AURA BOUTIQUE — Correction (supprime les politiques existantes)
--  Copiez-collez ce code dans : Supabase → SQL Editor → Run
-- ============================================================

-- Supprimer les anciennes politiques si elles existent
drop policy if exists "Produits visibles par tous" on products;
drop policy if exists "Produits modifiables par admin" on products;
drop policy if exists "Profil visible par son propriétaire" on profiles;
drop policy if exists "Profil modifiable par son propriétaire" on profiles;
drop policy if exists "Profil créé à l'inscription" on profiles;
drop policy if exists "Commandes visibles par leur auteur" on orders;
drop policy if exists "Commandes créées par l'utilisateur connecté" on orders;
drop policy if exists "Lignes visibles par l'auteur de la commande" on order_items;
drop policy if exists "Lignes insérables avec la commande" on order_items;
drop policy if exists "Panier visible par son propriétaire" on cart_items;
drop policy if exists "Panier modifiable par son propriétaire" on cart_items;

-- Recréer les politiques
create policy "Produits visibles par tous"
  on products for select using (true);

create policy "Produits modifiables par admin"
  on products for all
  using (auth.jwt() ->> 'role' = 'admin')
  with check (auth.jwt() ->> 'role' = 'admin');

create policy "Profil visible par son propriétaire"
  on profiles for select using (auth.uid() = id);

create policy "Profil modifiable par son propriétaire"
  on profiles for update using (auth.uid() = id);

create policy "Profil créé à l'inscription"
  on profiles for insert with check (auth.uid() = id);

create policy "Commandes visibles par leur auteur"
  on orders for select using (auth.uid() = user_id);

create policy "Commandes créées par l'utilisateur connecté"
  on orders for insert with check (auth.uid() = user_id);

create policy "Lignes visibles par l'auteur de la commande"
  on order_items for select
  using (exists (select 1 from orders o where o.id = order_id and o.user_id = auth.uid()));

create policy "Lignes insérables avec la commande"
  on order_items for insert
  with check (exists (select 1 from orders o where o.id = order_id and o.user_id = auth.uid()));

create policy "Panier visible par son propriétaire"
  on cart_items for select using (auth.uid() = user_id);

create policy "Panier modifiable par son propriétaire"
  on cart_items for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Trigger auto-création profil
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Message de confirmation
select 'Installation réussie ! Toutes les tables et politiques sont prêtes.' as message;
