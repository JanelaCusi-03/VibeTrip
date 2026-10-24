-- Tipos enumerados del dominio
CREATE TYPE time_bucket       AS ENUM ('morning', 'afternoon', 'evening', 'night');
CREATE TYPE companion_type    AS ENUM ('solo', 'couple', 'friends', 'family');
CREATE TYPE tag_group         AS ENUM ('ambiente', 'actividad', 'gastronomia',
                                       'social_nocturno', 'perfil_contexto', 'experiencia');
CREATE TYPE capture_channel   AS ENUM ('explicit', 'implicit');
CREATE TYPE interaction_type  AS ENUM (
  'swipe_like', 'swipe_dislike', 'swipe_superlike', 'ab_choice',
  'impression_skip', 'view_detail', 'dwell', 'photo_expand',
  'directions_click', 'share', 'favorite_add', 'favorite_remove', 'discard'
);
