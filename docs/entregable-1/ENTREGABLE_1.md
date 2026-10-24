# Entregable 1: Ingeniería de Requisitos, Método de Captura y Modelo de Datos

**Proyecto:** VibeTrip (nombre de trabajo)
**Estándares:** ISO/IEC/IEEE 29148 (requisitos), ISO/IEC 25010 (calidad), Clean Architecture, Scrum

> Los scripts SQL completos están en [`/supabase/migrations`](../../supabase/migrations), los datos base en [`/supabase/seed.sql`](../../supabase/seed.sql) y el diagrama ER en [`er-diagram.mmd`](./er-diagram.mmd).

---

## 1. Método híbrido de captura de gustos

### 1.1 Espacio de características (d = 48)

| Grupo | Índices | Etiquetas |
|---|---|---|
| ambiente | 0-7 | tranquilo, animado, romantico, familiar, bohemio, elegante, casual, vista_panoramica |
| actividad | 8-15 | aire_libre, aventura, cultural, historico, naturaleza, deportivo, relajante, fotografico |
| gastronomia | 16-23 | comida_local, comida_internacional, vegetariano, cafeteria, postres, street_food, fine_dining, bebidas_artesanales |
| social_nocturno | 24-31 | vida_nocturna, musica_en_vivo, bar, discoteca, karaoke, juegos, eventos, terraza |
| perfil_contexto | 32-39 | economico, premium, para_grupos, para_parejas, solo_friendly, pet_friendly, accesible, wifi_trabajo |
| experiencia | 40-47 | artesania, arte, museo, arquitectura, tradicion_local, mistico, compras, mercado |

Un lugar tiene pesos `w ∈ [0,1]` por etiqueta; el usuario tiene pesos `u ∈ [-1,1]` (negativo = rechazo explícito).

### 1.2 Captura explícita gamificada (Cold Start, ≤ 45 s)

| Paso | Mecánica | Cantidad | Presupuesto | Salida |
|---|---|---|---|---|
| A. Vibes | Chips multiselección (máx. 3) | 8 opciones | 8 s | Prior p |
| B. Swipe | Derecha +1, izquierda −1, arriba +2 | 12 cartas | 24 s | Señal s |
| C. Dilemas A/B | Dos fotos, un toque | 3 pares | 9 s | Contraste d |
| D. Presupuesto y compañía | Slider de 4 niveles y 4 íconos | 2 controles | 4 s | Defaults |

Fórmulas:

```
p = (1/|V|) · Σ π_v                      (prior de vibes)
s = Σ r_i · e_i,  r_i ∈ {-1, +1, +2}     (swipes, 12 cartas)
d = Σ (e_Aj - e_Bj)                      (contraste A/B, 3 pares)
u(0) = (α·p̂ + β·ŝ + γ·d̂) / ||α·p̂ + β·ŝ + γ·d̂||₂
α = 0.30, β = 0.50, γ = 0.20 (calibrables); x̂ = normalización L2
```

Selección de las 12 cartas: 2 por grupo (cobertura), selección por Maximal Marginal Relevance (diversidad) y, desde la carta 7, prioridad a las etiquetas de menor magnitud acumulada (incertidumbre). El botón «Saltar» siempre es visible (RF-02): sin onboarding se usa el prior de vibes o un vector de popularidad.

### 1.3 Captura implícita

| `interaction_type` | Detección en Flutter | `signal_weight` |
|---|---|---|
| impression_skip | Tarjeta visible < 1 s y sale del viewport | −0.05 |
| view_detail | Navegación al detalle | +0.25 |
| dwell | Tiempo de permanencia | 0 a +0.60 |
| photo_expand | Galería a pantalla completa | +0.35 |
| directions_click | Toque en «Cómo llegar» | +0.90 |
| share | Compartir lugar | +0.80 |
| favorite_add | Guardar en favoritos | +1.00 |
| favorite_remove | Quitar de favoritos | −0.50 |
| discard | «No me interesa» | −1.00 |

```
w_dwell(t) = 0                                  si t < t_min
w_dwell(t) = w_max · (1 − e^(−(t − t_min)/τ))   si t ≥ t_min
t_min = 2000 ms, w_max = 0.60, τ = 6000 ms
```

Reglas de robustez:

- Cronómetro activo solo con ≥ 50 % de la tarjeta visible y la app en `AppLifecycleState.resumed`.
- Tope de ±1.5 por (usuario, lugar, sesión).
- Olvido temporal con vida media H = 30 días: `w_ef = w · 2^(−Δt/H)`.
- Cola local en SQLite y envío por lotes (10 eventos, 30 s o al pasar a segundo plano); `event_id` (UUID v4) como clave de idempotencia.
- Sin `telemetry_consent = true` solo se procesan eventos explícitos (RF-16).

### 1.4 Captura contextual

El contexto no se almacena en el vector de gustos: modula el puntaje al consultar y se guarda como *snapshot* en el log.

| Variable | Fuente | Dominio | Actualización | Fallback |
|---|---|---|---|---|
| Ubicación | `geolocator` | lat/lon + radio (1, 3, 5, 10 km) | Al abrir el feed y al moverse > 200 m | Última posición, luego zona manual |
| Franja horaria | Reloj | morning 06-11, afternoon 12-17, evening 18-21, night 22-05 | Al abrir y cada 30 min | Siempre disponible |
| Clima | Open-Meteo | clear, cloudy, rain, cold, hot | Caché 30 min | unknown (neutro) |
| Presupuesto | Usuario | price_level 1-4 | Por sesión | default_budget_level |
| Compañía | Chips | solo, couple, friends, family | Por sesión | default_companion |

---

## 2. Requerimientos funcionales (MoSCoW)

| ID | Requerimiento | Prio. | HU |
|---|---|---|---|
| RF-01 | Autenticación por correo y Google (Supabase Auth) | M | - |
| RF-02 | Onboarding gamificado en ≤45 s con opción de saltar | M | HU-01 |
| RF-03 | Generar y persistir el vector inicial | M | HU-01 |
| RF-04 | Registrar señales implícitas | M | HU-03 |
| RF-05 | Capturar contexto: GPS, hora, clima, presupuesto, compañía | M | HU-02 |
| RF-06 | Filtros rápidos: Solo, Con amigos, Económico, Cerca de mí | M | HU-02 |
| RF-07 | Feed ordenado por matchScore (0-100 %) | M | HU-02 |
| RF-08 | Explicación textual de cada recomendación | M | HU-04 |
| RF-09 | Actualizar el vector tras cada interacción | M | HU-03 |
| RF-10 | Pantalla de detalle | M | HU-04 |
| RF-11 | Agregar y quitar favoritos | S | HU-04 |
| RF-12 | «No me interesa» con efecto inmediato | S | HU-04 |
| RF-13 | Mapa interactivo con pines por categoría | S | - |
| RF-14 | «Cómo llegar» por deep link | S | - |
| RF-15 | Modo sin conexión: caché y cola de eventos | M | HU-05 |
| RF-16 | Privacidad: consentimiento, exportar y eliminar datos | M | - |
| RF-17 | Reiniciar o reajustar gustos | C | HU-01 |

## 3. Requerimientos no funcionales

| ID | Atributo (ISO 25010) | Requisito | Verificación |
|---|---|---|---|
| RNF-01 | Eficiencia | Ranking de 500 candidatos | p95 ≤ 150 ms (`Stopwatch` + DevTools) |
| RNF-02 | Eficiencia | Arranque en frío | ≤ 3 s al primer feed |
| RNF-03 | Eficiencia | Scroll | ≥ 55 fps y < 1 % de jank |
| RNF-04 | Usabilidad | Onboarding | ≤ 45 s mediana (5 usuarios) |
| RNF-05 | Fiabilidad | Sin red | Caché de hasta 24 h |
| RNF-06 | Fiabilidad | Telemetría | Entrega ≥ 99 %, cero duplicados |
| RNF-07 | Seguridad | Aislamiento | RLS en todas las tablas de usuario |
| RNF-08 | Seguridad | Transporte y sesión | TLS ≥ 1.2, JWT ≤ 1 h |
| RNF-09 | Privacidad | Consentimiento | Telemetría implícita desactivada por defecto |
| RNF-10 | Mantenibilidad | Estructura | Clean Architecture, complejidad ciclomática ≤ 10 |
| RNF-11 | Mantenibilidad | Calidad estática | `flutter analyze` sin advertencias |
| RNF-12 | Testabilidad | Cobertura | ≥ 90 % en dominio y aplicación |
| RNF-13 | Accesibilidad | WCAG 2.1 AA | Áreas táctiles ≥ 48 dp |
| RNF-14 | Portabilidad | Plataformas | Android 8+ (API 26) e iOS 13+ |

---

## 4. Historias de usuario (Gherkin)

### HU-01: Onboarding rápido de gustos
**Como** usuario nuevo, **quiero** indicar mis gustos con gestos simples, **para** recibir recomendaciones relevantes desde la primera pantalla. Prioridad: Must · Puntos: 8 · RF-02, RF-03, RF-17

```gherkin
# language: es
Característica: Onboarding gamificado de preferencias

  Escenario: Completar el onboarding y generar el vector inicial
    Dado que soy un usuario autenticado sin vector de preferencias
    Cuando elijo 2 vibes, califico 12 cartas y respondo 3 dilemas A/B
    Entonces el sistema guarda un vector inicial normalizado de dimensión 48
    Y registra la fecha en "onboarding_completed_at"
    Y me muestra el feed personalizado

  Escenario: Saltar el onboarding
    Dado que estoy en cualquier paso del onboarding
    Cuando toco "Saltar"
    Entonces el sistema genera un vector de popularidad general
    Y el feed muestra un aviso para afinar mis gustos más tarde

  Escenario: Cumplimiento del tiempo objetivo
    Dado que completo el flujo sin pausas
    Cuando finalizo el último paso
    Entonces la duración total medida no supera los 45 segundos en la mediana de pruebas
```

### HU-02: Feed contextual con filtros rápidos
**Como** usuario, **quiero** ver lugares ordenados por afinidad y ajustados a mi situación, **para** decidir rápido qué plan hacer hoy. Prioridad: Must · Puntos: 13 · RF-05, RF-06, RF-07

```gherkin
# language: es
Característica: Feed inteligente con contexto

  Escenario: Ordenar lugares por afinidad
    Dado que tengo un vector de preferencias y permiso de ubicación
    Cuando abro el feed
    Entonces veo lugares dentro de mi radio ordenados por "matchScore" descendente
    Y cada tarjeta muestra el porcentaje de match entre 0 % y 100 %

  Escenario: Aplicar el filtro "Económico"
    Dado que estoy en el feed
    Cuando activo el filtro "Económico"
    Entonces solo veo lugares con "price_level" menor o igual a 2
    Y la lista se reordena en menos de 150 ms

  Escenario: Ubicación no disponible
    Dado que denegué el permiso de ubicación
    Cuando abro el feed
    Entonces la app me pide elegir una zona manualmente
    Y no se bloquea la visualización de recomendaciones
```

### HU-03: Aprendizaje implícito de mis gustos
**Como** usuario, **quiero** que la app aprenda de lo que miro y guardo, **para** que las recomendaciones mejoren sin llenar formularios. Prioridad: Must · Puntos: 13 · RF-04, RF-09

```gherkin
# language: es
Característica: Telemetría implícita y actualización de pesos

  Escenario: Registrar permanencia relevante
    Dado que di consentimiento de telemetría
    Y una tarjeta está visible en al menos 50 % de su área
    Cuando permanezco 8 segundos mirándola
    Entonces se registra un evento "dwell" con "dwell_ms" cercano a 8000
    Y se calcula un "signal_weight" positivo menor o igual a 0.60

  Escenario: Ignorar permanencia accidental
    Dado que di consentimiento de telemetría
    Cuando una tarjeta permanece visible menos de 2 segundos
    Entonces no se registra evento "dwell"

  Escenario: Respetar la ausencia de consentimiento
    Dado que no di consentimiento de telemetría
    Cuando miro una tarjeta durante 10 segundos
    Entonces no se registra ningún evento implícito
```

### HU-04: Entender y corregir las recomendaciones
**Como** usuario, **quiero** saber por qué se me recomienda un lugar y poder descartarlo, **para** confiar en el sistema y corregirlo. Prioridad: Must · Puntos: 5 · RF-08, RF-10, RF-11, RF-12

```gherkin
# language: es
Característica: Explicabilidad y retroalimentación

  Escenario: Ver la explicación de una recomendación
    Dado que veo un lugar con 87 % de match
    Cuando abro su detalle
    Entonces veo una explicación en lenguaje natural basada en mis etiquetas dominantes
    Y la explicación menciona al menos una etiqueta de coincidencia

  Escenario: Descartar un lugar
    Dado que veo un lugar en el feed
    Cuando toco "No me interesa"
    Entonces el lugar desaparece del feed inmediatamente
    Y se registra un evento "discard" con "signal_weight" igual a -1.0

  Escenario: Guardar en favoritos
    Dado que estoy en el detalle de un lugar
    Cuando toco el ícono de favorito
    Entonces el lugar aparece en mi lista de favoritos
    Y se registra un evento "favorite_add" con "signal_weight" igual a 1.0
```

### HU-05: Uso con mala conexión
**Como** viajero, **quiero** seguir usando la app con señal débil, **para** no depender de la red durante mi recorrido. Prioridad: Must · Puntos: 8 · RF-15, RNF-05, RNF-06

```gherkin
# language: es
Característica: Funcionamiento Offline-First

  Escenario: Ver el feed sin conexión
    Dado que cargué lugares en las últimas 24 horas
    Y no tengo conexión a internet
    Cuando abro la app
    Entonces veo el último feed en caché ordenado con mi vector local
    Y se muestra un indicador de "modo sin conexión"

  Escenario: Sincronizar eventos al recuperar la red
    Dado que generé 15 eventos de interacción sin conexión
    Cuando se restablece la conexión
    Entonces los eventos se envían en lotes con su "event_id"
    Y el servidor no crea duplicados si el envío se reintenta
```

---

## 5. Contrato de la API REST

Principios: GET solo para lecturas seguras; PUT para reemplazos idempotentes; POST para creación, idempotente mediante `event_id`; DELETE idempotente. Errores en formato *Problem Details* (RFC 9457). Implementación con PostgREST (Supabase) y Edge Functions.

| Verbo | Ruta | Idempotente | Éxito | Errores |
|---|---|---|---|---|
| GET | `/v1/places?lat&lon&radius_m&category&limit&cursor` | Sí | 200 | 400, 401, 500 |
| GET | `/v1/places/{placeId}` | Sí | 200 | 401, 404, 500 |
| GET | `/v1/me/preferences` | Sí | 200 | 401, 404, 500 |
| PUT | `/v1/me/preferences` (`If-Match: <version>`) | Sí | 200, 201 | 400, 401, 412, 500 |
| POST | `/v1/me/interactions` (lote con `event_id`) | Sí, por clave | 201 (hay nuevos), 200 (todos duplicados) | 400, 401, 500 |
| PUT | `/v1/me/favorites/{placeId}` | Sí | 201 (nuevo), 204 (ya existía) | 401, 404, 500 |
| DELETE | `/v1/me/favorites/{placeId}` | Sí | 204 | 401, 404, 500 |
| DELETE | `/v1/me` | Sí | 204 | 401, 500 |

```json
{
  "type": "https://vibetrip.app/problems/invalid-vector",
  "title": "Vector de preferencias inválido",
  "status": 400,
  "detail": "El vector debe tener exactamente 48 componentes en el rango [-1, 1].",
  "instance": "/v1/me/preferences"
}
```

---

## 6. Planificación y equipo

| Rol | Responsabilidad |
|---|---|
| Product Owner | Prioriza el backlog y valida criterios de aceptación |
| Coach / Scrum Master | Facilita ceremonias, elimina impedimentos y vela por el DoD |
| Mobile Lead | UI, estado y arquitectura Flutter |
| Data/Backend Engineer | Esquema SQL, API y motor de recomendación |

| Capa del story map | Historias | Entregable |
|---|---|---|
| 1. Fundamentos | Esquema SQL, seed, RLS | E1, E3 |
| 2. Captura de gustos | HU-01, HU-03 | E1, E4 |
| 3. Recomendación | HU-02, HU-04 | E2, E4 |
| 4. Robustez y entrega | HU-05, CI/CD, métricas | E3, E5 |

Sprints de 2 semanas: S1 modelo de datos y CI · S2 dominio y datos · S3 motor y telemetría · S4 UI y mapa · S5 QA, optimización y sustentación.

**Definición de Hecho:** revisión por un par, pruebas en verde, cobertura del módulo ≥ 90 %, `flutter analyze` limpio y criterios Gherkin demostrados.

## 7. Código limpio y patrones

| Evitar | Usar |
|---|---|
| `list1`, `x`, `d` | `candidatePlaces`, `userVector`, `distanceInMeters` |
| `calc()` | `computeHaversineDistanceInMeters()` |
| `flag` | `hasTelemetryConsent` |
| `data`, `info` | `placeSnapshot`, `contextSnapshot` |
| `w` | `dwellSignalWeight` |

| Patrón | Tipo | Aplicación | Entregable |
|---|---|---|---|
| Repository | Arquitectónico | `PlaceRepository`, `UserProfileRepository` | E3 |
| Decorator | GoF | `CachedPlaceRepository` | E3 |
| Strategy | GoF | `ScoringStrategy` por factor | E4 |
| Observer / Pub-Sub | Arquitectónico | Riverpod y stream de telemetría | E4 |
| Factory | GoF | `InteractionEvent.fromViewDuration(...)` | E3 |
| Dependency Injection | Implementación | Providers de Riverpod | E2 |
| Clean Architecture | Arquitectónico | Presentation, Domain, Data | E2 |

## 8. Pruebas, versionado y optimización

- **Pruebas:** unitarias (`flutter_test`, `mocktail`, ≥90 %), widget, integración (`integration_test`) y contrato API contra Supabase local.
- **Versionado:** GitHub Flow, `main` protegida (PR + 1 aprobación + CI verde), ramas `feat/`, `fix/`, `docs/`, Conventional Commits.
- **CI/CD:** [`ci.yml`](../../.github/workflows/ci.yml) con formato, análisis, pruebas, *quality gate* de cobertura y build de APK.
- **Optimización:** primero funcionalidad; medir con el Profiler contra RNF-01 a RNF-03; optimizar solo si un requisito falla; documentar en `docs/perf/` con medición antes y después.

## 9. Modelo de datos

Decisiones: vectores densos `vector(48)` (pgvector), `JSONB` legible para explicabilidad, `place_tags` como fuente de verdad (el `embedding` y `tag_weights` se derivan por trigger), ubicación con PostGIS e índice espacial, y `version` en `user_preference_vectors` para concurrencia optimista.

| Tabla | Propósito | Cardinalidad |
|---|---|---|
| `users` | Perfil, defaults y consentimiento | 1 por usuario |
| `categories` | Clasificación jerárquica con ícono y color | 1 : N lugares |
| `tags` | Catálogo de las 48 dimensiones | N:M con lugares |
| `places` | Lugares con ubicación, contexto y embedding | N:1 categoría |
| `place_tags` | Peso de cada etiqueta en cada lugar | Tabla puente |
| `user_preference_vectors` | Vector de gustos versionado | 1:1 usuario |
| `user_interactions_log` | Eventos con snapshot de contexto | 1 : N |
| `user_favorites` | Lugares guardados | N:M |

Nota de escalabilidad: si `user_interactions_log` supera el millón de filas, se particiona por rango mensual de `occurred_at`; no antes (criterio de optimización).

Diagrama ER: ver [`er-diagram.mmd`](./er-diagram.mmd) (también renderizado en el README principal).
