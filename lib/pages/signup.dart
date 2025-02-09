import 'package:cb/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _password;
  String? _mobile;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();


  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try{
      User? user = await _firebaseService.signUp(_name!,_email!,_password!,_mobile!);
      if(user != null){
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, 'signin');
      }
    } catch(e){
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 64.0),
            child: Center(
              child: Text(
                'Signup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _buildTextField(
            'Name',
             Icons.person,
              TextInputType.text,
               (value) {
            if (value == null || value.isEmpty) return 'Please enter your name';
            return null;
          }, (value) => _name = value),
          SizedBox(height: 16),
          _buildTextField('Email',
           Icons.email,
            TextInputType.emailAddress,
             (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(value)) {
              return null;
            }
            return 'Please enter a valid email address';
          }, (value) => _email = value),
          SizedBox(height: 16),
          _buildTextField('Mobile Number',
           Icons.phone,
            TextInputType.phone, 
            (value) {
            if (value == null || value.isEmpty) return 'Please enter your mobile number';
            if (!RegExp(r'^\d{10}\$').hasMatch(value)) return null;
            return 'Please enter a valid 10-digit mobile number';
          }, (value) => _mobile = value),
          SizedBox(height: 16),
          _buildTextField('Password',
           Icons.lock,
            TextInputType.visiblePassword, 
            (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 6) return 'Password must be at least 6 characters long';
            return null;
          }, (value) => _password = value, obscureText: true),
          SizedBox(height: 24),
          _buildRegisterButton(),
          SizedBox(height: 16),
          _buildLoginRedirect(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextInputType keyboardType, FormFieldValidator<String> validator, FormFieldSetter<String> onSaved, {bool obscureText = false}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onSaved,
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color.fromARGB(255, 4, 55, 78),
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Sign Up',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
    );
  }

  Widget _buildLoginRedirect() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account?"),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, 'signin'),
          child: Text(
            'Sign in',
            style: TextStyle(
              color: const Color.fromARGB(255, 4, 55, 78),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatify', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
        backgroundColor: const Color.fromARGB(255, 4, 55, 78),
        elevation: 20.0,
        shadowColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(10.0,16.0,10.0,16.0),
          child: Center(
            child: Dialog(
              
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
