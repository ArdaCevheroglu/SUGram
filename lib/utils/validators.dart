class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Simple regex for email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@sabanciuniv\.edu$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid Sabancı University email';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    // Username can only contain letters, numbers, and underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  // Full name validation
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    
    if (value.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    
    return null;
  }

  // Event title validation
  static String? validateEventTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Event title is required';
    }
    
    if (value.length < 3) {
      return 'Event title must be at least 3 characters';
    }
    
    return null;
  }

  // Event description validation
  static String? validateEventDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Event description is required';
    }
    
    if (value.length < 10) {
      return 'Event description must be at least 10 characters';
    }
    
    return null;
  }

  // Event location validation
  static String? validateEventLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Event location is required';
    }
    
    return null;
  }

  // Post caption validation (optional)
  static String? validatePostCaption(String? value) {
    // Caption is optional, so return null if empty
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (value.length > 2200) {
      return 'Caption must be less than 2200 characters';
    }
    
    return null;
  }

  // Comment validation
  static String? validateComment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Comment cannot be empty';
    }
    
    if (value.length > 1000) {
      return 'Comment must be less than 1000 characters';
    }
    
    return null;
  }

  // Message validation
  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Message cannot be empty';
    }
    
    return null;
  }
}