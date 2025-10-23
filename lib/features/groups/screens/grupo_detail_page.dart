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
    with SingleTickerProviderStateMixin {
  // Mapa para controlar el estado de asistencia de cada estudiante
  final Map<String, bool> _asistencias = {};
  late AnimationController _buttonAnimationController;
  // Eliminada Animation<double> _buttonAnimation porque no se usa

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Se eliminó la inicialización de _buttonAnimation porque no se usa
    // Esperar a que termine la animación del Hero
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _buttonAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildWalletButton(
                      icon: Icons.close,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
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
                        const SizedBox(height: 32),
                        // Lista de estudiantes
                        Text(
                          'Estudiantes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Lista de alumnos en contenedor con estilo
                        Container(
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
                                  isLast:
                                      index == widget.grupo.students.length - 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildWalletButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.72),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // Esta función fue eliminada porque no se usa

  // Esta función fue eliminada porque no se usa

  // Esta función _subirAsistenciaNube fue eliminada porque no se usa

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

  // Esta función _verificarAsistenciaProfesor fue eliminada porque no se usa
}
