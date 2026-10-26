import '../../../../core/domain/tag_catalog.dart';
import '../../../../core/domain/tag_vector.dart';

/// *Vibe* o estado de ánimo del paso A, con su prior `π_v`.
class OnboardingVibe {
  OnboardingVibe({
    required this.id,
    required this.label,
    required this.emoji,
    required Map<String, double> priorTagWeights,
  }) : prior = TagVector.fromTagWeights(priorTagWeights);

  final String id;
  final String label;
  final String emoji;
  final TagVector prior;
}

/// Carta conceptual del deck (paso B) u opción de un dilema (paso C).
class OnboardingCard {
  OnboardingCard({
    required this.id,
    required this.title,
    required this.emoji,
    required this.group,
    required Map<String, double> tagWeights,
  }) : tagVector = TagVector.fromTagWeights(tagWeights);

  final String id;
  final String title;
  final String emoji;
  final TagGroup group;

  /// `eᵢ`: vector de la carta.
  final TagVector tagVector;
}

/// Par de opciones A/B (paso C).
class OnboardingDilemma {
  const OnboardingDilemma({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
  });

  final String id;
  final String question;
  final OnboardingCard optionA;
  final OnboardingCard optionB;
}

/// Contenido fijo del onboarding gamificado (Entregable 1 §1.2).
///
/// El deck tiene 2 cartas por grupo de etiquetas para asegurar cobertura de
/// los 6 grupos con solo 12 cartas.
abstract final class OnboardingCatalog {
  static const int maximumSelectedVibes = 3;

  static final List<OnboardingVibe> vibes = <OnboardingVibe>[
    OnboardingVibe(
      id: 'relax',
      label: 'Relax',
      emoji: '🧘',
      priorTagWeights: <String, double>{
        'tranquilo': 1,
        'relajante': 1,
        'naturaleza': 0.5,
        'cafeteria': 0.4,
      },
    ),
    OnboardingVibe(
      id: 'aventura',
      label: 'Aventura',
      emoji: '🧗',
      priorTagWeights: <String, double>{
        'aventura': 1,
        'aire_libre': 0.9,
        'deportivo': 0.7,
        'naturaleza': 0.6,
      },
    ),
    OnboardingVibe(
      id: 'cultura',
      label: 'Cultura',
      emoji: '🏛️',
      priorTagWeights: <String, double>{
        'cultural': 1,
        'historico': 0.9,
        'museo': 0.8,
        'arquitectura': 0.7,
        'arte': 0.6,
      },
    ),
    OnboardingVibe(
      id: 'foodie',
      label: 'Foodie',
      emoji: '🍲',
      priorTagWeights: <String, double>{
        'comida_local': 1,
        'street_food': 0.7,
        'postres': 0.5,
        'bebidas_artesanales': 0.5,
        'mercado': 0.5,
      },
    ),
    OnboardingVibe(
      id: 'fiesta',
      label: 'Fiesta',
      emoji: '🎉',
      priorTagWeights: <String, double>{
        'vida_nocturna': 1,
        'discoteca': 0.8,
        'bar': 0.8,
        'musica_en_vivo': 0.7,
        'animado': 0.7,
      },
    ),
    OnboardingVibe(
      id: 'romantico',
      label: 'Romántico',
      emoji: '💞',
      priorTagWeights: <String, double>{
        'romantico': 1,
        'para_parejas': 0.9,
        'vista_panoramica': 0.6,
        'elegante': 0.5,
      },
    ),
    OnboardingVibe(
      id: 'naturaleza',
      label: 'Naturaleza',
      emoji: '🌿',
      priorTagWeights: <String, double>{
        'naturaleza': 1,
        'aire_libre': 1,
        'fotografico': 0.6,
        'tranquilo': 0.5,
      },
    ),
    OnboardingVibe(
      id: 'familia',
      label: 'Familia',
      emoji: '👨‍👩‍👧',
      priorTagWeights: <String, double>{
        'familiar': 1,
        'para_grupos': 0.6,
        'accesible': 0.6,
        'aire_libre': 0.5,
      },
    ),
  ];

  static final List<OnboardingCard> swipeDeck = <OnboardingCard>[
    OnboardingCard(
      id: 'cafe_tranquilo',
      title: 'Café tranquilo con libros',
      emoji: '☕',
      group: TagGroup.ambiente,
      tagWeights: <String, double>{
        'tranquilo': 1,
        'cafeteria': 0.7,
        'relajante': 0.6,
        'solo_friendly': 0.5,
      },
    ),
    OnboardingCard(
      id: 'mirador_atardecer',
      title: 'Mirador al atardecer',
      emoji: '🌄',
      group: TagGroup.ambiente,
      tagWeights: <String, double>{
        'vista_panoramica': 1,
        'romantico': 0.7,
        'fotografico': 0.7,
        'aire_libre': 0.5,
      },
    ),
    OnboardingCard(
      id: 'trekking',
      title: 'Trekking de montaña',
      emoji: '🥾',
      group: TagGroup.actividad,
      tagWeights: <String, double>{
        'aventura': 1,
        'naturaleza': 0.9,
        'aire_libre': 0.9,
        'deportivo': 0.7,
      },
    ),
    OnboardingCard(
      id: 'ruinas_incas',
      title: 'Ruinas incas',
      emoji: '🗿',
      group: TagGroup.actividad,
      tagWeights: <String, double>{
        'historico': 1,
        'cultural': 0.8,
        'arquitectura': 0.7,
        'mistico': 0.5,
      },
    ),
    OnboardingCard(
      id: 'mercado_callejero',
      title: 'Mercado y comida callejera',
      emoji: '🌮',
      group: TagGroup.gastronomia,
      tagWeights: <String, double>{
        'street_food': 1,
        'mercado': 0.8,
        'comida_local': 0.8,
        'economico': 0.6,
      },
    ),
    OnboardingCard(
      id: 'cena_autor',
      title: 'Cena de autor',
      emoji: '🍷',
      group: TagGroup.gastronomia,
      tagWeights: <String, double>{
        'fine_dining': 1,
        'elegante': 0.8,
        'premium': 0.7,
        'romantico': 0.4,
      },
    ),
    OnboardingCard(
      id: 'bar_musica',
      title: 'Bar con música en vivo',
      emoji: '🎸',
      group: TagGroup.socialNocturno,
      tagWeights: <String, double>{
        'musica_en_vivo': 1,
        'bar': 0.8,
        'vida_nocturna': 0.8,
        'animado': 0.6,
      },
    ),
    OnboardingCard(
      id: 'discoteca',
      title: 'Discoteca hasta tarde',
      emoji: '🪩',
      group: TagGroup.socialNocturno,
      tagWeights: <String, double>{
        'discoteca': 1,
        'vida_nocturna': 1,
        'animado': 0.8,
        'para_grupos': 0.6,
      },
    ),
    OnboardingCard(
      id: 'plan_amigos',
      title: 'Plan con amigos y juegos',
      emoji: '🎲',
      group: TagGroup.perfilContexto,
      tagWeights: <String, double>{
        'para_grupos': 1,
        'animado': 0.6,
        'juegos': 0.5,
        'economico': 0.4,
      },
    ),
    OnboardingCard(
      id: 'coworking',
      title: 'Café con buen wifi para trabajar',
      emoji: '💻',
      group: TagGroup.perfilContexto,
      tagWeights: <String, double>{
        'wifi_trabajo': 1,
        'solo_friendly': 0.6,
        'cafeteria': 0.6,
        'tranquilo': 0.5,
      },
    ),
    OnboardingCard(
      id: 'taller_artesania',
      title: 'Taller de artesanía',
      emoji: '🧶',
      group: TagGroup.experiencia,
      tagWeights: <String, double>{
        'artesania': 1,
        'tradicion_local': 0.8,
        'arte': 0.6,
        'compras': 0.4,
      },
    ),
    OnboardingCard(
      id: 'museo_arte',
      title: 'Museo de arte',
      emoji: '🖼️',
      group: TagGroup.experiencia,
      tagWeights: <String, double>{
        'museo': 1,
        'arte': 0.9,
        'cultural': 0.7,
        'tranquilo': 0.4,
      },
    ),
  ];

  static final List<OnboardingDilemma> dilemmas = <OnboardingDilemma>[
    OnboardingDilemma(
      id: 'manana',
      question: '¿Cómo empiezas el día?',
      optionA: OnboardingCard(
        id: 'manana_museo',
        title: 'Museo y café',
        emoji: '🏛️',
        group: TagGroup.experiencia,
        tagWeights: <String, double>{'museo': 1, 'cultural': 0.8},
      ),
      optionB: OnboardingCard(
        id: 'manana_caminata',
        title: 'Caminata al aire libre',
        emoji: '🏞️',
        group: TagGroup.actividad,
        tagWeights: <String, double>{
          'naturaleza': 1,
          'aire_libre': 0.8,
          'aventura': 0.5,
        },
      ),
    ),
    OnboardingDilemma(
      id: 'cena',
      question: '¿Dónde cenas?',
      optionA: OnboardingCard(
        id: 'cena_elegante',
        title: 'Restaurante elegante',
        emoji: '🍽️',
        group: TagGroup.gastronomia,
        tagWeights: <String, double>{'fine_dining': 1, 'elegante': 0.8},
      ),
      optionB: OnboardingCard(
        id: 'cena_huarique',
        title: 'Huarique local',
        emoji: '🥘',
        group: TagGroup.gastronomia,
        tagWeights: <String, double>{
          'comida_local': 1,
          'economico': 0.7,
          'casual': 0.6,
        },
      ),
    ),
    OnboardingDilemma(
      id: 'noche',
      question: '¿Y en la noche?',
      optionA: OnboardingCard(
        id: 'noche_bar',
        title: 'Bar animado',
        emoji: '🍻',
        group: TagGroup.socialNocturno,
        tagWeights: <String, double>{
          'bar': 1,
          'vida_nocturna': 0.8,
          'animado': 0.7,
        },
      ),
      optionB: OnboardingCard(
        id: 'noche_terraza',
        title: 'Terraza tranquila con vista',
        emoji: '🌃',
        group: TagGroup.socialNocturno,
        tagWeights: <String, double>{
          'terraza': 1,
          'tranquilo': 0.8,
          'vista_panoramica': 0.6,
        },
      ),
    ),
  ];
}
