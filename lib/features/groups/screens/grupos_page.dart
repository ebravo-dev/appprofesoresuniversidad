import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/uat_colors.dart';
import '../../../../shared/models/grupo.dart';
import '../../../../shared/models/profesor.dart';
import '../../authentication/providers/profesor_auth_provider.dart';

class GruposPage extends ConsumerWidget {
  const GruposPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profesor = ref.watch(currentProfesorProvider);
    final grupos = ref.watch(profesorGruposProvider);
    final isLoading = ref.watch(profesorAuthLoadingProvider);

    return Scaffold(
      backgroundColor: UATColors.surface,
      appBar: AppBar(
        title: const Text('Mis Grupos'),
        backgroundColor: UATColors.primary,
        foregroundColor: UATColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading
                ? null
                : () {
                    ref.read(profesorAuthProvider.notifier).refreshGrupos();
                  },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    const Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Profesor info header
          if (profesor != null) _buildProfesorHeader(profesor),

          // Grupos content
          Expanded(
            child: isLoading && grupos.isEmpty
                ? _buildLoadingState()
                : grupos.isEmpty
                ? _buildEmptyState(ref)
                : _buildGruposList(grupos),
          ),
        ],
      ),
    );
  }

  Widget _buildProfesorHeader(Profesor profesor) {
    // Obtener la primera letra del email
    final firstLetter = profesor.email.isNotEmpty
        ? profesor.email[0].toUpperCase()
        : 'P';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [UATColors.primary, UATColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: UATColors.onPrimary,
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: UATColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido/a',
                    style: TextStyle(
                      color: UATColors.onPrimary.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profesor.email,
                    style: TextStyle(
                      color: UATColors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando grupos...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: UATColors.neutral60),
            const SizedBox(height: 16),
            Text(
              'No tienes grupos asignados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: UATColors.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contacta al administrador si crees que esto es un error.',
              style: TextStyle(color: UATColors.neutral80),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(profesorAuthProvider.notifier).refreshGrupos();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UATColors.primary,
                foregroundColor: UATColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGruposList(List<Grupo> grupos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        final grupo = grupos[index];
        return _buildGrupoCard(grupo);
      },
    );
  }

  Widget _buildGrupoCard(Grupo grupo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navegar a detalles del grupo o toma de asistencia
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: UATColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.class_,
                        color: UATColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grupo.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            grupo.materia,
                            style: TextStyle(
                              fontSize: 14,
                              color: UATColors.neutral80,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '${grupo.totalAlumnos} estudiantes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Información adicional del grupo
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      size: 14,
                      color: UATColors.neutral60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aula: ${grupo.aula}',
                      style: TextStyle(
                        fontSize: 12,
                        color: UATColors.neutral60,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: UATColors.neutral60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Periodo: ${grupo.period}',
                      style: TextStyle(
                        fontSize: 12,
                        color: UATColors.neutral60,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Ver lista de alumnos
                      },
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text('Ver Alumnos'),
                      style: TextButton.styleFrom(
                        foregroundColor: UATColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Tomar asistencia
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Asistencia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UATColors.primary,
                        foregroundColor: UATColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(profesorAuthProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
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
