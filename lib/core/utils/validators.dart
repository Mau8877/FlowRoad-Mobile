class Validators {
  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'El correo es obligatorio';
    }

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!regex.hasMatch(text)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    if (text.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    return null;
  }
}
