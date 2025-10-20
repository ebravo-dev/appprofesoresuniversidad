import 'package:flutter/material.dart';
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
          Text(
            'Cargando grupos...',
            style: TextStyle(color: Colors.white70),
          ),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: grupos.length,
        itemBuilder: (context, index) {
          return _buildWalletCard(grupos[index], index);
        },
      ),
    );
  }

  Widget _buildWalletCard(Grupo grupo, int index) {
    // Colores inspirados en Wallet (tarjetas de crédito/débito)
    final cardColors = [
      {
        'gradient': [const Color(0xFF6B4CE6), const Color(0xFF9B7EF5)],
        'accent': Colors.white
      }, // Purple
      {
        'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
        'accent': Colors.white
      }, // Red/Pink
      {
        'gradient': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
        'accent': Colors.white
      }, // Teal
      {
        'gradient': [const Color(0xFFFF9A56), const Color(0xFFFFB87A)],
        'accent': Colors.white
      }, // Orange
      {
        'gradient': [const Color(0xFF5F9EE8), const Color(0xFF7FB3F0)],
        'accent': Colors.white
      }, // Blue
      {
        'gradient': [const Color(0xFFE85F99), const Color(0xFFF07BA8)],
        'accent': Colors.white
      }, // Pink
    ];

    final colorScheme = cardColors[index % cardColors.length];
    final gradientColors = colorScheme['gradient'] as List<Color>;
    final accentColor = colorScheme['accent'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
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
