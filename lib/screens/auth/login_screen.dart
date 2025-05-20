import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        
        final success = await authViewModel.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.error ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (success && mounted) {
          // Log successful auth
          print('Login successful, user: ${authViewModel.currentUser?.username}');
          
          // Force navigation to main screen
          print('Manually navigating to main screen after successful login');
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } catch (e) {
        print('Unexpected error during login: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleSigningIn = true;
    });
    
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.signInWithGoogle();
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.error ?? 'Google Sign-In failed'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (success && mounted) {
        // Log successful auth
        print('Google sign-in successful, user: ${authViewModel.currentUser?.username}');
        
        // Force navigation to main screen
        print('Manually navigating to main screen after successful Google sign-in');
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final isLoading = authViewModel.isLoading || _isGoogleSigningIn;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/App name
                  const Text(
                    'SUGram',
                    style: TextStyle(
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40.0),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'example@sabanciuniv.edu',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: isLoading ? null : _togglePasswordVisibility,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : () {
                        // Show a dialog to enter email for password reset
                        showDialog(
                          context: context,
                          builder: (context) => _buildForgotPasswordDialog(context),
                        );
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: isLoading && !_isGoogleSigningIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text('Log In'),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Divider with "OR" text
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Google Sign-in Button
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _loginWithGoogle,
                    icon: _isGoogleSigningIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Signup link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                  
                  // Demo account (for development only)
                  const Divider(height: 30),
                  const Text('Demo Account', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            _emailController.text = 'demo@sabanciuniv.edu';
                            _passwordController.text = 'demo123456';
                            _login();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                    ),
                    child: const Text('Use Demo Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
          ),
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context);
              
              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              
              try {
                await authViewModel.resetPassword(emailController.text.trim());
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent. Check your inbox.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send reset email: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Send Reset Link'),
        ),
      ],
    );
  }
}