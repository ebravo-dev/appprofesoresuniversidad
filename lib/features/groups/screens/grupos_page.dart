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

class _GruposPageState extends ConsumerState<GruposPage> {
  int? _expandedIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
                  isLoading ? Icons.hourglass_empty : Icons.add_circle_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        ref.read(profesorAuthProvider.notifier).refreshGrupos();
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
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(profesorAuthProvider.notifier).refreshGrupos();
      },
      backgroundColor: Colors.grey.shade900,
      color: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 100,
        ),
        itemCount: grupos.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return _buildStackedCard(grupos[index], index, grupos.length);
        },
      ),
    );
  }

  Widget _buildStackedCard(Grupo grupo, int index, int totalCards) {
    // Offset para el efecto de apilamiento
    final double topOffset =
        index * 8.0; // Cada tarjeta se desplaza 8px hacia abajo
    final double scale =
        1.0 - (index * 0.02); // Cada tarjeta es ligeramente más pequeña

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        double offset = 0;
        if (_scrollController.hasClients) {
          offset = _scrollController.offset;
        }

        // Calcula la opacidad y transformación basada en el scroll
        final itemOffset = topOffset - offset;
        final shouldAnimate = itemOffset < 0;
        final animationProgress = shouldAnimate
            ? (itemOffset.abs() / 100).clamp(0.0, 1.0)
            : 0.0;

        return Transform.translate(
          offset: Offset(0, shouldAnimate ? itemOffset.abs() * 0.5 : topOffset),
          child: Transform.scale(
            scale: shouldAnimate ? scale - (animationProgress * 0.1) : scale,
            child: Opacity(
              opacity: 1.0 - (animationProgress * 0.5),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: index == totalCards - 1
              ? 0
              : 240, // Espacio para ver las tarjetas apiladas
        ),
        child: _buildWalletCard(grupo, index),
      ),
    );
  }

  Widget _buildWalletCard(Grupo grupo, int index) {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _expandedIndex = _expandedIndex == index ? null : index;
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
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con badge tipo "débito/crédito"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              grupo.nombre.toUpperCase(),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.contactless,
                            color: accentColor.withOpacity(0.3),
                            size: 28,
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Nombre de la materia (estilo número de tarjeta)
                      Text(
                        grupo.materia,
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

                      const SizedBox(height: 16),

                      // Info del grupo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AULA',
                                style: TextStyle(
                                  color: accentColor.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                grupo.aula,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
              ),
            ),
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
                leading: const Icon(Icons.refresh, color: Colors.white),
                title: const Text(
                  'Actualizar Clases',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profesorAuthProvider.notifier).refreshGrupos();
                },
              ),

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
