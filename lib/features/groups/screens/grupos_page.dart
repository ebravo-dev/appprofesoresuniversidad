import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/uat_colors.dart';
import '../../../../shared/models/grupo.dart';
import '../../authentication/providers/profesor_auth_provider.dart';
import 'grupo_detail_page.dart';

class GruposPage extends ConsumerStatefulWidget {
  const GruposPage({super.key});

  @override
  ConsumerState<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends ConsumerState<GruposPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false; // Control de expansión de tarjetas
  bool _showTitle = true; // Control de visibilidad del título
  late AnimationController _pulseController;
  int? _selectedCardIndex; // Índice de la tarjeta seleccionada para navegación
  Timer? _titleVisibilityTimer; // Controla el retraso para esconder el título

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

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    [Color(0xFFFF6B9D), Color(0xFFFF5A8F)],
    [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
    [Color(0xFFFF8A65), Color(0xFFFF7043)],
    [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    [Color(0xFFFF6B9D), Color(0xFFFF5A8F)],
  ];

  static const List<Color> _cardAccentColors = [
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();

    // Animación pulsante para el indicador de clase actual
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Listener para animar el título basado en scroll
    _scrollController.addListener(_handleScroll);

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
    _titleVisibilityTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;

    if (offset <= 20) {
      _titleVisibilityTimer?.cancel();
      _titleVisibilityTimer = null;
      if (!_showTitle) {
        setState(() {
          _showTitle = true;
        });
      }
      return;
    }

    if (_showTitle && _titleVisibilityTimer == null) {
      _titleVisibilityTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _showTitle = false;
        });
        _titleVisibilityTimer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = ref.watch(profesorGruposProvider);
    final isLoading = ref.watch(profesorAuthLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content sin padding para que ocupe toda la pantalla
          isLoading && grupos.isEmpty
              ? _buildLoadingState()
              : grupos.isEmpty
              ? _buildEmptyState()
              : _buildWalletCards(grupos),
          // Gradiente sombreado desde el status bar (efecto iOS)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: MediaQuery.of(context).padding.top + 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.50),
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.10),
                      Colors.black.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.45, 0.60, 0.75, 0.85, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Floating title
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: AnimatedOpacity(
              opacity: _showTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSlide(
                offset: _showTitle ? Offset.zero : const Offset(0, -0.5),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: const Text(
                  'Mis Clases',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Row(
              children: [
                // Botón de expandir/colapsar
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E).withOpacity(0.72),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Contenedor con tema y 3 puntos (como Wallet)
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E).withOpacity(0.72),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón de cambiar tema
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // TODO: Implementar cambio de tema
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              color: Colors.transparent,
                              child: const Icon(
                                Icons.light_mode,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          // Botón de más opciones
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showOptionsMenu(context);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              color: Colors.transparent,
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _gradientForCard(int index) =>
      _cardGradients[index % _cardGradients.length];

  Color _accentForCard(int index) =>
      _cardAccentColors[index % _cardAccentColors.length];

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
        ? 180.0 // Modo expandido: mostrar hasta los valores de grupo y cantidad de estudiantes
        : 60.0; // Modo normal: suficiente para mostrar horario y días
    const cardHeight = 200.0;

    // Calcular altura total del contenido
    // Si hay una tarjeta seleccionada, agregar espacio extra para el desplazamiento
    final baseHeight = cardHeight + (grupos.length - 1) * cardPeekHeight;
    final extraHeight = _selectedCardIndex != null
        ? (cardHeight - cardPeekHeight)
        : 0.0;
    final totalHeight = baseHeight + extraHeight;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 81,
          bottom: 8,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: grupos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final grupo = entry.value;
                  // TODO: Reemplazar con lógica real de horarios
                  // La última tarjeta (la que está al frente) es la clase actual
                  final isCurrentClass = index == grupos.length - 1;

                  // Calcular posición: si hay una tarjeta seleccionada y esta está debajo,
                  // desplazarla hacia abajo
                  double topPosition = index * cardPeekHeight;
                  if (_selectedCardIndex != null &&
                      index > _selectedCardIndex!) {
                    // Desplazar tarjetas debajo hacia abajo (altura completa de la tarjeta)
                    topPosition += 200.0 - cardPeekHeight;
                  }

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                    top: topPosition,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: false,
                      child: _buildWalletCard(grupo, index, isCurrentClass),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Indicador sutil de próxima clase por atender
            const SizedBox(height: 12),
            Column(
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 4),
                Text(
                  'Próxima por atender',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(Grupo grupo, int index, bool isCurrentClass) {
    // Obtiene los colores desde la configuración compartida para mantener coherencia visual
    final gradientColors = _gradientForCard(index);
    final accentColor = _accentForCard(index);

    return Container(
      height: 200,
      margin: _isExpanded
          ? const EdgeInsets.only(bottom: 5.0)
          : EdgeInsets.zero,
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
        child: Stack(
          children: [
            // Tarjeta principal
            RepaintBoundary(
              child: Hero(
                tag: 'grupo_${grupo.group}_${grupo.subject}',
                flightShuttleBuilder:
                    (
                      BuildContext flightContext,
                      Animation<double> animation,
                      HeroFlightDirection flightDirection,
                      BuildContext fromHeroContext,
                      BuildContext toHeroContext,
                    ) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 0,
                        child: toHeroContext.widget,
                      );
                    },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();

                      // Establecer la tarjeta seleccionada y animar las demás hacia abajo
                      setState(() {
                        _selectedCardIndex = index;
                      });

                      // Esperar a que se complete la animación de desplazamiento
                      await Future.delayed(const Duration(milliseconds: 300));

                      // Navegar a la página de detalles
                      await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  GrupoDetailPage(
                                    grupo: grupo,
                                    gradientColors: gradientColors,
                                    accentColor: accentColor,
                                    horario:
                                        _placeholderHoras[index %
                                            _placeholderHoras.length],
                                    dias:
                                        _placeholderDias[index %
                                            _placeholderDias.length],
                                  ),
                          transitionDuration: const Duration(milliseconds: 400),
                          reverseTransitionDuration: const Duration(
                            milliseconds: 350,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                // Curva estilo iOS - suave y natural
                                final curvedAnimation = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                  reverseCurve: Curves.easeIn,
                                );
                                return FadeTransition(
                                  opacity: curvedAnimation,
                                  child: child,
                                );
                              },
                        ),
                      );

                      // IMPORTANTE: Esperar a que el Hero termine de regresar
                      // antes de restaurar las tarjetas de abajo
                      await Future.delayed(const Duration(milliseconds: 350));

                      // Al regresar, limpiar la selección para que las tarjetas vuelvan
                      if (mounted) {
                        setState(() {
                          _selectedCardIndex = null;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 200),
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.3),
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

                          const SizedBox(height: 12),

                          // Nombre de la materia con altura mínima fija para consistencia
                          SizedBox(
                            height: 56, // Espacio para 2 líneas
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
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
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Info del grupo - posición fija
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                    ), // Cierre Container
                  ), // Cierre InkWell
                ), // Cierre Material
              ), // Cierre Hero
            ), // Cierre RepaintBoundary
          ],
        ), // Cierre Stack
      ), // Cierre TweenAnimationBuilder
    ); // Cierre SizedBox
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
