# Metodología Kanban de VibeTrip

Guía paso a paso para montar y operar el tablero Kanban del proyecto en **GitHub Projects**, con todas las tarjetas del trabajo realizado en los Entregables 1 a 5 y el backlog pendiente.

> **Kanban y Scrum juntos (Scrumban).** El README define sprints de 2 semanas (Scrum). Kanban no los reemplaza: agrega un **flujo visual**, **límites de trabajo en curso (WIP)** y **métricas de flujo**. Los sprints quedan como cadencia de planificación y revisión; el tablero controla el día a día.

---

## Paso 1. Entender los 6 principios que vamos a aplicar

| # | Práctica Kanban | Cómo se aplica en VibeTrip |
|---|---|---|
| 1 | Visualizar el flujo | Tablero en GitHub Projects con una tarjeta (issue) por tarea |
| 2 | Limitar el trabajo en curso | Máximo 2 tarjetas en *In Progress* por persona y 3 en *Review* |
| 3 | Gestionar el flujo | Medir *lead time* y *cycle time*; atender primero lo que está más a la derecha |
| 4 | Explicitar las políticas | Criterios de entrada y salida de cada columna (Paso 3) |
| 5 | Ciclos de retroalimentación | *Daily* de 10 min frente al tablero, revisión semanal, retrospectiva por sprint |
| 6 | Mejorar en colaboración | Cada bloqueo se anota y se discute en la retrospectiva |

## Paso 2. Crear el tablero en GitHub

1. Los Projects pertenecen a una cuenta, y el repo es de la cuenta personal `JanelaCusi-03`. Créalo en **tu** cuenta: avatar → **Your projects** → **New project**.
2. Elige la plantilla **Board** y nómbralo `VibeTrip – Kanban`.
3. Vincúlalo al repositorio: https://github.com/JanelaCusi-03/VibeTrip → pestaña **Projects** → **Link a project** → elige `VibeTrip – Kanban`.
4. Comparte el tablero con el equipo: en el proyecto, **⋯** → **Settings** → **Manage access** → agrega a cada integrante con rol **Write**.
5. Renombra y crea las columnas (campo **Status**) en este orden:

| Columna | Significado | Límite WIP |
|---|---|---|
| 📥 **Backlog** | Ideas y requisitos aún no refinados | Sin límite |
| 📋 **To Do** (Listo para empezar) | Refinado: tiene criterios de aceptación y estimación | 8 |
| 🔨 **In Progress** | Alguien trabaja en ella en una rama `feat/`, `fix/` o `docs/` | 2 por persona |
| 👀 **Review / CI** | PR abierto, esperando CI verde y 1 aprobación | 3 |
| ✅ **Done** | Merge a `main` y DoD cumplida | Sin límite |

6. Para fijar el límite: en cada columna, menú **⋯** → **Set limit**.
7. Agrega campos personalizados (**+ New field**):
   - `Entregable` (selección única): E1, E2, E3, E4, E5.
   - `Tipo` (selección única): feat, docs, test, ci, chore, fix.
   - `Puntos` (número): estimación Fibonacci (1, 2, 3, 5, 8, 13).
   - `Inicio` y `Fin` (fecha): para calcular el *cycle time*.
8. Activa los **workflows** del proyecto (menú **⋯** → **Workflows**):
   - *Item added to project* → Status = Backlog.
   - *Pull request linked to issue* → Status = Review / CI.
   - *Item closed* y *Pull request merged* → Status = Done.

## Paso 3. Escribir las políticas explícitas (DoR y DoD)

Copia esto en la descripción del proyecto (**⋯** → **Settings** → **Description**):

| Transición | Política (para mover la tarjeta debe cumplirse) |
|---|---|
| Backlog → To Do | **Definition of Ready:** historia o tarea con objetivo claro, criterios de aceptación (Gherkin si es HU), trazabilidad a RF/RNF y estimación en puntos |
| To Do → In Progress | Hay capacidad dentro del límite WIP; se crea la rama `feat/…`, `fix/…` o `docs/…` y la persona se asigna |
| In Progress → Review / CI | PR abierto con descripción, `flutter analyze` limpio y pruebas locales en verde |
| Review / CI → Done | **Definition of Done (README):** revisión de 1 par, CI verde, cobertura del dominio ≥ 90 %, criterios Gherkin demostrados, merge a `main` |
| Cualquier columna → Bloqueada | Etiqueta `bloqueado` + comentario con la causa; se trata en la *daily* |

## Paso 4. Crear las etiquetas

En **Issues → Labels → New label**:

| Etiqueta | Color | Uso |
|---|---|---|
| `E1` … `E5` | `#0E8A16` | Entregable al que pertenece |
| `feat` · `docs` · `test` · `ci` · `chore` · `fix` | `#1D76DB` | Mismo tipo que el Conventional Commit |
| `HU-01` … `HU-05` | `#FBCA04` | Historia de usuario |
| `bloqueado` | `#B60205` | La tarjeta no puede avanzar |
| `clase-urgente` | `#D93F0B` | Clase de servicio *expedite*: salta la cola (máximo 1 a la vez) |

## Paso 5. Plantilla de tarjeta

Cada tarjeta es un **issue**. Usa este formato:

```markdown
**Como** <rol> **quiero** <acción> **para** <beneficio>      ← solo si es HU

**Trazabilidad:** RF-xx, RNF-xx · **Entregable:** E#
**Criterios de aceptación:**
- [ ] ...
**Evidencia:** commit / PR / captura / reporte de pruebas
```

## Paso 6. Cargar las tarjetas del trabajo realizado

Estas son las tarjetas que **ya están hechas**. Créalas y ponlas directamente en la columna indicada; la evidencia es el commit o el PR.

### Entregable 1: requisitos, método de captura y modelo de datos (equipo, antes de esta iteración)

| # | Tarjeta | Tipo | Evidencia | Estado |
|---|---|---|---|---|
| 1 | Método híbrido de captura de gustos (explícito, implícito, contextual) | docs | `docs/entregable-1/ENTREGABLE_1.md` | Done |
| 2 | Requisitos RF/RNF y 5 HU en Gherkin | docs | `ENTREGABLE_1.md` §2-§4 | Done |
| 3 | Esquema PostgreSQL + RLS + seed de etiquetas | feat | `supabase/migrations/*`, `seed.sql` | Done |
| 4 | Diagrama ER en Mermaid | docs | `docs/entregable-1/er-diagram.mmd` | Done |

### Sprint 1: plataformas y CI (PR #1)

| # | Tarjeta | Tipo | Pts | Commit | Estado |
|---|---|---|---|---|---|
| 5 | Generar carpetas Android/iOS | chore | 1 | `58362d2` | Review / CI |
| 6 | Pipeline de CI con quality gate de cobertura ≥ 90 % | ci | 3 | `de19b51` | Review / CI |

### Entregable 2: diseño matemático y arquitectura (PR #2)

| # | Tarjeta | Tipo | Pts | Commit | Estado |
|---|---|---|---|---|---|
| 7 | Dependencias del `pubspec.yaml` justificadas | chore | 2 | `80e89a0` | Review / CI |
| 8 | Documento E2: fórmula híbrida, Mermaid, árbol, ADR-01/02 | docs | 5 | `5e64dbe` | Review / CI |
| 9 | Núcleo matemático: catálogo de 48 etiquetas, coseno, Haversine | feat | 3 | `754bed6` | Review / CI |
| 10 | Esqueleto: Riverpod, go_router, tema Material 3 | feat | 2 | `7439b18` | Review / CI |
| 11 | README: enlaces del repo y badge de CI | docs | 1 | `e8190f4` | Review / CI |

### Entregable 3: dominio, datos y modelos (PR #3)

| # | Tarjeta | Tipo | Pts | Commit | Estado |
|---|---|---|---|---|---|
| 12 | Entidades inmutables (Place, UserProfile, InteractionEvent…) | feat | 5 | `d2cd1c3` | Review / CI |
| 13 | Seed JSON con 18 lugares de Cusco | feat | 3 | `f0391c2` | Review / CI |
| 14 | Repositorio de lugares + Decorator Offline-First (HU-05) | feat | 5 | `5bfc7ca` | Review / CI |
| 15 | Perfil local + cola de telemetría idempotente (HU-05) | feat | 5 | `25ccd33` | Review / CI |
| 16 | Generador de `seed_places.sql` desde el JSON | feat | 2 | `66c7c00` | Review / CI |
| 17 | Documento E3 | docs | 2 | `ccbe80b` | Review / CI |

### Entregable 4: motor y telemetría (PR #4)

| # | Tarjeta | Tipo | Pts | Commit | Estado |
|---|---|---|---|---|---|
| 18 | `RecommendationEngineService` con Strategy (HU-02, HU-04) | feat | 8 | `c501c40` | Review / CI |
| 19 | Aprendizaje del vector, DwellStopwatch, TelemetryService (HU-03) | feat | 8 | `55d5545` | Review / CI |
| 20 | Catálogo del onboarding y vector `u₀` (HU-01) | feat | 5 | `d3e4ac5` | Review / CI |
| 21 | Widget `UserBehaviorTracker` (HU-03) | feat | 3 | `fbfed57` | Review / CI |
| 22 | Documento E4 | docs | 2 | `bfb95ac` | Review / CI |

### Entregable 5: UI, geolocalización y QA (PR #5)

| # | Tarjeta | Tipo | Pts | Commit | Estado |
|---|---|---|---|---|---|
| 23 | Contexto: GPS, clima Open-Meteo y filtros rápidos (HU-02) | feat | 5 | `7c6e944` | Review / CI |
| 24 | Inyección de dependencias, estado del perfil y del feed | feat | 5 | `9033959` | Review / CI |
| 25 | Pantallas: onboarding, feed, detalle, mapa y perfil | feat | 13 | `9637223` | Review / CI |
| 26 | Evaluación: Precision@K y latencia | test | 3 | `4324b6d` | Review / CI |
| 27 | Documento E5 con capturas y métricas | docs | 3 | `aa6c0cf` | Review / CI |
| 28 | Guía de metodología Kanban (este documento) | docs | 2 | PR #5 | Review / CI |

> Cuando hagan el merge de cada PR, sus tarjetas pasan a **Done** (automático si activaron el workflow del Paso 2.8).

## Paso 7. Cargar el backlog pendiente

| # | Tarjeta | Tipo | Pts | Prioridad | Trazabilidad |
|---|---|---|---|---|---|
| 29 | Revisar y hacer merge de los PR #1 a #5 (en orden) | chore | 1 | 🔴 Alta | DoD |
| 30 | Autenticación con correo y Google en Supabase | feat | 8 | 🔴 Alta | RF-01 |
| 31 | Crear el proyecto Supabase y probar migraciones + `seed_places.sql` | chore | 3 | 🔴 Alta | E1, E3 |
| 32 | Sincronizar el perfil con `PUT /v1/me/preferences` (`If-Match`) | feat | 5 | 🟠 Media | API E1 |
| 33 | Medir latencia y fps en un celular con el Profiler (`--profile`) | test | 3 | 🟠 Media | RNF-01 a RNF-03 |
| 34 | Prueba de usabilidad del onboarding con 5 usuarios (≤ 45 s) | test | 3 | 🟠 Media | RNF-04 |
| 35 | Prueba de integración `integration_test` onboarding → feed | test | 3 | 🟠 Media | E1 §8 |
| 36 | Selección adaptativa de cartas del deck (MMR) | feat | 5 | 🟢 Baja | E1 §1.2 |
| 37 | Agrupar pines cercanos en el mapa (*clustering*) | feat | 3 | 🟢 Baja | RF-13 |
| 38 | Completar la tabla de roles del README con los nombres del equipo | docs | 1 | 🟢 Baja | Planificación |

## Paso 8. Asignar responsables por rol

| Rol (README) | Tarjetas sugeridas |
|---|---|
| Product Owner | 29, 34, 38 (prioriza el backlog y valida los criterios de aceptación) |
| Coach / Scrum Master | Vigilar los límites WIP, facilitar *daily* y retro, revisar la DoD |
| Mobile Lead | 35, 36, 37 (UI y Flutter) |
| Data/Backend Engineer | 30, 31, 32, 33 (Supabase, API y rendimiento) |

## Paso 9. Operar el tablero día a día

1. **Daily (10 min, de pie, frente al tablero):** se recorre el tablero **de derecha a izquierda** («dejar de empezar, empezar a terminar»). Preguntas: ¿qué falta para mover esta tarjeta? ¿hay bloqueos?
2. **Tirar, no empujar (*pull*):** solo se toma una tarjeta de *To Do* si la persona tiene espacio en su límite WIP.
3. **Flujo por tarjeta** (igual al que se usó en este repo):
   ```bash
   git checkout -b feat/<tarjeta>          # mover a In Progress
   # programar + pruebas
   git commit -m "feat(<area>): <qué>"     # Conventional Commits
   git push -u origin feat/<tarjeta>
   gh pr create                             # mover a Review / CI
   # CI verde + 1 aprobación → merge       # mover a Done
   ```
4. **Reposición (semanal, 20 min):** el PO pasa tarjetas de *Backlog* a *To Do* cumpliendo la Definition of Ready.
5. **Revisión y retrospectiva (cada sprint):** se revisan las métricas del Paso 10 y se ajustan los límites WIP.

## Paso 10. Medir el flujo

| Métrica | Cómo se calcula | Dónde verla |
|---|---|---|
| **Lead time** | Fecha Done − fecha de creación de la tarjeta | Campos `Inicio`/`Fin` o vista *Insights* |
| **Cycle time** | Fecha Done − fecha de entrada a *In Progress* | Igual |
| **Throughput** | Tarjetas en Done por semana | *Insights* → gráfico por Status |
| **WIP** | Tarjetas en *In Progress* + *Review* | Contador de cada columna |
| **CFD** (diagrama de flujo acumulado) | Tarjetas por columna en el tiempo | *Insights* → **Status chart** (área apilada) |

En GitHub Projects: **Insights** → **New chart** → tipo *Stacked area*, eje X = tiempo, agrupar por `Status`. Si una banda del CFD se ensancha, ahí hay un cuello de botella (por ejemplo, muchos PR esperando revisión → bajar el WIP de *Review* o revisar antes de empezar trabajo nuevo).

## Paso 11 (opcional). Crear las tarjetas desde la terminal

Requiere el permiso `project` en GitHub CLI:

```bash
gh auth refresh -h github.com -s project

# Crear el proyecto en tu cuenta y vincularlo al repo (anota el número)
gh project create --owner "@me" --title "VibeTrip – Kanban"
gh project link <NUMERO> --owner "@me" --repo JanelaCusi-03/VibeTrip

# Crear una tarjeta del backlog como issue y agregarla al proyecto
gh issue create --repo JanelaCusi-03/VibeTrip \
  --title "Autenticación con correo y Google (RF-01)" \
  --label "feat" \
  --body "Trazabilidad: RF-01 · Entregable: E5 · Puntos: 8"
gh project item-add <NUMERO> --owner "@me" \
  --url https://github.com/JanelaCusi-03/VibeTrip/issues/<N>
```

Las etiquetas deben existir antes (Paso 4). Para las tarjetas ya hechas, basta con agregar los PR #1 a #5 al proyecto con `gh project item-add`.
