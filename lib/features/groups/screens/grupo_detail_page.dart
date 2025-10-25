import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/models/grupo.dart';

class GrupoDetailPage extends StatefulWidget {
  final Grupo grupo;
  final List<Color> gradientColors;
  final Color accentColor;
  final String horario;
  final String dias;

  const GrupoDetailPage({
    super.key,
    required this.grupo,
    required this.gradientColors,
    required this.accentColor,
    required this.horario,
    required this.dias,
  });

  @override
  State<GrupoDetailPage> createState() => _GrupoDetailPageState();
}

class _GrupoDetailPageState extends State<GrupoDetailPage>
    with TickerProviderStateMixin {
  // Mapa para controlar el estado de asistencia de cada estudiante
  final Map<String, bool> _asistencias = {};
  late AnimationController _buttonAnimationController;
  late AnimationController _studentsAnimationController;
  late Animation<double> _studentsOpacity;
  late Animation<Offset> _studentsSlide;
  // Control del tab seleccionado (0 = Mi asistencia, 1 = Alumnos)
  int _selectedTab = 0;
  bool _profesorAsistencia = false;

  // Para detectar pull-to-dismiss
  final ScrollController _scrollController = ScrollController();
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Animación para estudiantes con delay
    _studentsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _studentsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _studentsAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _studentsSlide =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _studentsAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Se eliminó la inicialización de _buttonAnimation porque no se usa
    // Esperar a que termine la animación del Hero
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _buttonAnimationController.forward();
      }
    });

    // Delay de 400ms antes de animar estudiantes
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _studentsAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _studentsAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            // Verificar si estamos en el top
            final isAtTop = notification.metrics.pixels <= 0;

            if (isAtTop && notification.metrics.pixels < 0) {
              // Hay overscroll negativo (estamos jalando hacia abajo desde el top)
              setState(() {
                _dragDistance = notification.metrics.pixels.abs();
              });

              // Si supera el threshold, cerrar
              if (_dragDistance > 100) {
                HapticFeedback.mediumImpact();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                return true; // Consumir la notificación
              }
            }
          } else if (notification is ScrollEndNotification ||
              notification is OverscrollNotification) {
            // Resetear cuando termina el scroll
            setState(() {
              _dragDistance = 0;
            });
          }
          return false;
        },
        child: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                // AlwaysScrollableScrollPhysics asegura que siempre se pueda hacer scroll
                // incluso cuando el contenido es pequeño, permitiendo el pull-to-dismiss
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    toolbarHeight:
                        60, // Ajustar altura para coincidir con el header normal
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                        child: _buildWalletButton(
                          isWide: true,
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
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Card
                          RepaintBoundary(
                            child: Hero(
                              tag:
                                  'grupo_${widget.grupo.group}_${widget.grupo.subject}',
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: widget.gradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.gradientColors[0]
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: widget.accentColor
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: widget.accentColor
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.grupo.aula,
                                                  style: TextStyle(
                                                    color: widget.accentColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                widget.horario,
                                                style: TextStyle(
                                                  color: widget.accentColor
                                                      .withOpacity(0.8),
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
                                              widget.dias,
                                              style: TextStyle(
                                                color: widget.accentColor
                                                    .withOpacity(0.6),
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
                                            widget.grupo.materia
                                                .replaceAll(
                                                  RegExp(r'\([^)]*\)\s*'),
                                                  '',
                                                )
                                                .trim(),
                                            style: TextStyle(
                                              color: widget.accentColor,
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
                                      // Info adicional - posición fija
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
                                                  color: widget.accentColor
                                                      .withOpacity(0.7),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.grupo.group,
                                                style: TextStyle(
                                                  color: widget.accentColor,
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
                                                  color: widget.accentColor
                                                      .withOpacity(0.7),
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
                                                    color: widget.accentColor,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${widget.grupo.totalAlumnos}',
                                                    style: TextStyle(
                                                      color: widget.accentColor,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                          const SizedBox(height: 32),
                          // Tab menu y contenido con animación
                          FadeTransition(
                            opacity: _studentsOpacity,
                            child: SlideTransition(
                              position: _studentsSlide,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tab Menu
                                  _buildTabMenu(),
                                  const SizedBox(height: 16),
                                  // Contenido basado en el tab seleccionado
                                  _selectedTab == 0
                                      ? _buildMiAsistenciaContent()
                                      : _buildAlumnosContent(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ], // Cierre de slivers
              ), // Cierre CustomScrollView
            ), // Cierre SafeArea
          ], // Cierre Stack children
        ), // Cierre Stack
      ), // Cierre NotificationListener
    ); // Cierre Scaffold
  }

  Widget _buildWalletButton({
    required Widget child,
    VoidCallback? onTap,
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWide ? 22 : 22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 44,
            width: isWide ? null : 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.72),
              borderRadius: BorderRadius.circular(isWide ? 22 : 22),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTabMenu() {
    return Row(
      children: [
        _buildTabButton(
          label: 'Mi asistencia',
          isSelected: _selectedTab == 0,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedTab = 0);
          },
        ),
        const SizedBox(width: 24),
        _buildTabButton(
          label: 'Alumnos',
          isSelected: _selectedTab == 1,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedTab = 1);
          },
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 3,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: widget.gradientColors[0],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiAsistenciaContent() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _profesorAsistencia = !_profesorAsistencia;
            });
            // TODO: Guardar asistencia del profesor en backend
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: widget.gradientColors[0].withOpacity(0.2),
          highlightColor: widget.gradientColors[0].withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Icono de profesor
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registrar mi asistencia',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profesorAsistencia
                            ? '✓ Asistencia registrada'
                            : 'Toca para marcar tu asistencia',
                        style: TextStyle(
                          color: _profesorAsistencia
                              ? widget.gradientColors[0]
                              : Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: _profesorAsistencia
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox grande
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _profesorAsistencia
                        ? widget.gradientColors[0]
                        : Colors.transparent,
                    border: Border.all(
                      color: _profesorAsistencia
                          ? widget.gradientColors[0]
                          : Colors.grey.shade600,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _profesorAsistencia
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlumnosContent() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: List.generate(
            widget.grupo.students.length,
            (index) => _buildStudentCard(
              widget.grupo.students[index],
              isLast: index == widget.grupo.students.length - 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(dynamic alumno, {bool isLast = false}) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              final currentValue =
                  _asistencias[alumno.number.toString()] ?? false;
              _asistencias[alumno.number.toString()] = !currentValue;
            });
            // TODO: Guardar asistencia en backend
          },
          splashColor: widget.gradientColors[0].withOpacity(0.2),
          highlightColor: widget.gradientColors[0].withOpacity(0.1),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    // Nombre del estudiante
                    Expanded(
                      child: Text(
                        alumno.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Checkbox de asistencia con animación
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: (_asistencias[alumno.number.toString()] ?? false)
                            ? widget.gradientColors[0].withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                (_asistencias[alumno.number.toString()] ??
                                    false)
                                ? widget.gradientColors[0]
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  (_asistencias[alumno.number.toString()] ??
                                      false)
                                  ? widget.gradientColors[0]
                                  : Colors.grey.shade600,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child:
                              (_asistencias[alumno.number.toString()] ?? false)
                              ? Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Línea separadora alineada con el contenido (excepto para el último elemento)
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Container(
                    height: 0.5,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildMenuOption(
                  icon: Icons.insights_rounded,
                  title: 'Ver estadísticas',
                  subtitle: 'Asistencia y reportes del grupo',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navegar a estadísticas
                  },
                ),
                _buildMenuOption(
                  icon: Icons.share_rounded,
                  title: 'Compartir grupo',
                  subtitle: 'Enviar información del grupo',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Compartir grupo
                  },
                ),
                _buildMenuOption(
                  icon: Icons.settings_rounded,
                  title: 'Configuración',
                  subtitle: 'Ajustes del grupo y notificaciones',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Abrir configuración
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.gradientColors[0].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: widget.gradientColors[0], size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Esta función _verificarAsistenciaProfesor fue eliminada porque no se usa
}
