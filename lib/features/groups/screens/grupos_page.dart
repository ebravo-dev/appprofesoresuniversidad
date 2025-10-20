import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/uat_colors.dart';
import '../../../../shared/models/grupo.dart';
import '../../../../shared/models/profesor.dart';
import '../../authentication/providers/profesor_auth_provider.dart';

class GruposPage extends ConsumerStatefulWidget {
  const GruposPage({super.key});

  @override
  ConsumerState<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends ConsumerState<GruposPage>
    with SingleTickerProviderStateMixin {
  int? _expandedIndex;
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false; // Control de expansión de tarjetas
  late AnimationController _pulseController;

  // Horas de ejemplo proporcionadas por el usuario para mostrar mientras no hay horarios reales
  static const List<String> _placeholderHoras = <String>[
    '10:00-11:00',
    '13:00-14:00',
    '16:00-17:00',
    '19:00-20:00',
    '20:00-21:00',
    '20:00-21:00',
    '20:00-21:00',
  ];

  // Días de la semana para cada clase
  static const List<String> _placeholderDias = <String>[
    'L-J',
    'L-V',
    'Ma,J',
    'Mi-V',
    'L-M',
  ];

  @override
  void initState() {
    super.initState();

    // Animación pulsante para el indicador de clase actual
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Configurar status bar para tema oscuro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profesor = ref.watch(currentProfesorProvider);
    final grupos = ref.watch(profesorGruposProvider);
    final isLoading = ref.watch(profesorAuthLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header estilo Wallet
            _buildWalletHeader(context, profesor, isLoading),

            // Grupos como tarjetas apiladas
            Expanded(
              child: isLoading && grupos.isEmpty
                  ? _buildLoadingState()
                  : grupos.isEmpty
                  ? _buildEmptyState()
                  : _buildWalletCards(grupos),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHeader(
    BuildContext context,
    Profesor? profesor,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mis Clases',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => _showOptionsMenu(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Cargando grupos...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes clases asignadas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Contacta al administrador si crees que esto es un error.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCards(List<Grupo> grupos) {
    // Altura visible de cada tarjeta empalmada (como en Wallet)
    final cardPeekHeight = _isExpanded
        ? 120.0
        : 65.0; // Más espacio para ver los intervalos de días
    const cardHeight = 200.0;

    // Calcular altura total del contenido
    final totalHeight = cardHeight + (grupos.length - 1) * cardPeekHeight;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          height: totalHeight,
          child: Stack(
            children: grupos.asMap().entries.map((entry) {
              final index = entry.key;
              final grupo = entry.value;
              // TODO: Reemplazar con lógica real de horarios
              // La última tarjeta (la que está al frente) es la clase actual
              final isCurrentClass = index == grupos.length - 1;
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                top: index * cardPeekHeight,
                left: 0,
                right: 0,
                child: _buildWalletCard(grupo, index, isCurrentClass),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(Grupo grupo, int index, bool isCurrentClass) {
    // Colores inspirados en Wallet (tarjetas de crédito/débito)
    final cardColors = [
      {
        'gradient': [const Color(0xFF6B4CE6), const Color(0xFF9B7EF5)],
        'accent': Colors.white,
      }, // Purple
      {
        'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
        'accent': Colors.white,
      }, // Red/Pink
      {
        'gradient': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
        'accent': Colors.white,
      }, // Teal
      {
        'gradient': [const Color(0xFFFF9A56), const Color(0xFFFFB87A)],
        'accent': Colors.white,
      }, // Orange
      {
        'gradient': [const Color(0xFF5F9EE8), const Color(0xFF7FB3F0)],
        'accent': Colors.white,
      }, // Blue
      {
        'gradient': [const Color(0xFFE85F99), const Color(0xFFF07BA8)],
        'accent': Colors.white,
      }, // Pink
    ];

    final colorScheme = cardColors[index % cardColors.length];
    final gradientColors = colorScheme['gradient'] as List<Color>;
    final accentColor = colorScheme['accent'] as Color;

    return Hero(
      tag: 'grupo_card_$index',
      child: SizedBox(
        height: 200,
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            // Clamp value to ensure it stays within valid range
            final clampedValue = value.clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.8 + (clampedValue * 0.2),
              child: Opacity(opacity: clampedValue, child: child),
            );
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              // Animación de pulso solo para la clase actual
              final pulseValue = isCurrentClass
                  ? Tween<double>(begin: 1.0, end: 1.01)
                        .animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        )
                        .value
                  : 1.0;

              return Transform.scale(
                scale: pulseValue,
                child: Stack(
                  children: [
                    // Borde brillante animado para clase actual
                    if (isCurrentClass)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(
                                0.15 + (_pulseController.value * 0.1),
                              ),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentColor.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    // Tarjeta principal
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _expandedIndex = _expandedIndex == index
                                  ? null
                                  : index;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors[0].withOpacity(
                                    isCurrentClass ? 0.3 : 0.2,
                                  ),
                                  blurRadius: isCurrentClass ? 20 : 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header con badge del grupo y hora
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: accentColor.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            grupo.aula,
                                            style: TextStyle(
                                              color: accentColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        // TODO: Reemplazar con horario real cuando esté en el modelo
                                        Text(
                                          _placeholderHoras[index %
                                              _placeholderHoras.length],
                                          style: TextStyle(
                                            color: accentColor.withOpacity(0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Días flotando abajo a la derecha
                                    Positioned(
                                      right: 0,
                                      top: 22,
                                      child: Text(
                                        _placeholderDias[index %
                                            _placeholderDias.length],
                                        style: TextStyle(
                                          color: accentColor.withOpacity(0.6),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Nombre de la materia (sin código entre paréntesis)
                                Text(
                                  grupo.materia
                                      .replaceAll(RegExp(r'\([^)]*\)\s*'), '')
                                      .trim(),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const Spacer(),

                                const SizedBox(height: 16),

                                // Info del grupo
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GRUPO',
                                          style: TextStyle(
                                            color: accentColor.withOpacity(0.7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          grupo.group,
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PERIODO',
                                          style: TextStyle(
                                            color: accentColor.withOpacity(0.7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'P${grupo.period}',
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ESTUDIANTES',
                                          style: TextStyle(
                                            color: accentColor.withOpacity(0.7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.people_rounded,
                                              color: accentColor,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${grupo.totalAlumnos}',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final profesor = ref.read(currentProfesorProvider);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar y nombre
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: UATColors.primary,
                    child: Text(
                      profesor?.email[0].toUpperCase() ?? 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profesor?.name ?? 'Profesor',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          profesor?.email ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),

              // Opciones
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(profesorAuthProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
