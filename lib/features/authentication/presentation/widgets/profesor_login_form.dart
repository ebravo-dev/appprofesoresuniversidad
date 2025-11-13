import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/uat_colors.dart';
import '../../providers/profesor_auth_provider.dart';
import '../../../../shared/widgets/email_suggestion_bar.dart';

class ProfesorLoginForm extends ConsumerStatefulWidget {
  const ProfesorLoginForm({super.key});

  @override
  ConsumerState<ProfesorLoginForm> createState() => _ProfesorLoginFormState();
}

class _ProfesorLoginFormState extends ConsumerState<ProfesorLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isFormValid = false;
  bool _isLoginMode = true; // true = login, false = register

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _emailController.addListener(_onEmailChanged);
    _emailFocusNode.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    try {
      EmailSuggestionOverlay.hide(); // Limpiar overlay
    } catch (e) {
      // Ignorar errores al limpiar overlay
    }
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final text = _emailController.text;
    // Mostrar sugerencias cuando hay @ y el usuario está escribiendo el dominio
    final atIndex = text.indexOf('@');
    final shouldShow =
        _emailFocusNode.hasFocus &&
        atIndex != -1 &&
        atIndex < text.length - 1; // Hay @ y algo después

    if (shouldShow) {
      // Extraer la parte antes del @
      final userPart = text.substring(0, atIndex + 1); // Incluye el @
      EmailSuggestionOverlay.show(
        context: context,
        currentText: userPart,
        onSuggestionTapped: _onSuggestionTapped,
      );
    } else {
      EmailSuggestionOverlay.hide();
    }

    // Forzar revalidación del formulario para actualizar errores
    _validateForm();
  }

  void _onEmailFocusChanged() {
    if (!_emailFocusNode.hasFocus) {
      EmailSuggestionOverlay.hide();
    } else {
      _onEmailChanged();
    }
  }

  void _onSuggestionTapped(String suggestion) {
    _emailController.text = suggestion;
    _emailController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    EmailSuggestionOverlay.hide();
    // Mover focus al campo de contraseña
    FocusScope.of(context).nextFocus();
  }

  void _validateForm() {
    final baseValid =
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _emailController.text.contains('@');

    // En modo registro, también requerir el nombre
    final isValid = _isLoginMode
        ? baseValid
        : baseValid && _nameController.text.isNotEmpty;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }

    // Forzar actualización del estado para que se actualicen los mensajes de error
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Guardar credenciales en el autofill del sistema
        TextInput.finishAutofillContext();
      } catch (e) {
        // Ignorar errores de autofill en iOS
      }

      if (_isLoginMode) {
        ref
            .read(profesorAuthProvider.notifier)
            .login(_emailController.text.trim(), _passwordController.text);
      } else {
        ref
            .read(profesorAuthProvider.notifier)
            .register(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _passwordController.text,
            );
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(profesorAuthProvider);

    // Mostrar error si existe
    ref.listen<ProfesorAuthState>(profesorAuthProvider, (previous, next) {
      if (next.hasError && next.errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(profesorAuthProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Name field (only for register)
            if (!_isLoginMode) ...[
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                enabled: !authState.isLoading,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  hintText: 'Ej: Dr. María González',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: UATColors.neutral80,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: UATColors.neutral40),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: UATColors.neutral40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: UATColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: UATColors.surface,
                ),
                validator: (value) {
                  if (!_isLoginMode && (value == null || value.isEmpty)) {
                    return 'Por favor ingresa tu nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !authState.isLoading,
              autocorrect: false,
              enableSuggestions:
                  false, // Deshabilitamos las sugerencias nativas de texto
              textCapitalization: TextCapitalization.none,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.username,
              ],
              decoration: InputDecoration(
                labelText: 'Email institucional',
                hintText: 'ejemplo@uat.edu.mx',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: UATColors.neutral80,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: UATColors.neutral40),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: UATColors.neutral40),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: UATColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: UATColors.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu email';
                }
                if (!value.contains('@')) {
                  return 'Por favor ingresa un email válido';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !authState.isLoading,
              autocorrect: false,
              enableSuggestions:
                  true, // Habilitamos sugerencias para contraseñas
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _handleSubmit(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Usa Face ID, Touch ID o ingresa tu contraseña',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: UATColors.neutral80,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: UATColors.neutral80,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: UATColors.neutral40),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: UATColors.neutral40),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: UATColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: UATColors.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (value.length < 4) {
                  return 'La contraseña debe tener al menos 4 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: authState.isLoading || !_isFormValid
                    ? null
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UATColors.primary,
                  foregroundColor: UATColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: UATColors.neutral40,
                  disabledForegroundColor: UATColors.neutral80,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: authState.isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              UATColors.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
                          key: ValueKey(_isLoginMode ? 'login' : 'register'),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Toggle between login and register
            TextButton(
              onPressed: _toggleMode,
              child: Text(
                _isLoginMode
                    ? '¿Es tu primera vez? Regístrate aquí'
                    : '¿Ya tienes cuenta? Inicia sesión',
                style: TextStyle(
                  color: UATColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Help text
            Text(
              _isLoginMode
                  ? 'Usa tu email y contraseña institucional'
                  : 'Crea tu cuenta con tu email institucional',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: UATColors.neutral80),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
