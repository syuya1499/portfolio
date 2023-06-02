import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photo/sign_up.dart';
import 'forgot_password.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isObscure = true;

  String getErrorMessage(String errorCode){
    switch(errorCode){
      case 'invalid-email':
        return 'メールアドレスを入力して下さい';
      case 'wrong-password':
        return 'パスワードが間違っています。';
      case 'user-not-found':
        return 'このメールアドレスは存在しません';
      default:
        return '再度試して下さい';
    }
  } 

  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _mailController.text,
        password: _passwordController.text,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _errorMessage = '';
        });
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyPage()),
      );
    } catch (e) {
      if(e is FirebaseAuthException){
        String errorCode = e.code;
        String errorMessage = getErrorMessage(errorCode);
        if (mounted) {
          setState(() {
            _errorMessage = 'ログインエラー: $errorMessage';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'ログインエラー: $e';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _mailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景画像
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ぼかし効果
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 2.0,
              sigmaY: 2.0
            ),
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Craft Memory',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 50),
                        TextFormField(
                          controller: _mailController,
                          decoration: InputDecoration(
                            labelText: 'メールアドレス',
                            labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 114, 112, 112),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.0
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 20
                        ),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 114, 112, 112),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              onPressed: (){
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                              icon: Icon(
                              _isObscure ? Icons.visibility_off : Icons.visibility,
                            ),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.0
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 20
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _login();
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Login',
                              style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w100
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PasswordResetForm()
                              )
                            );
                          },
                          style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.transparent,
                           elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'パスワードをお忘れですか？',
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w100,
                              fontSize: 10
                            ),
                          )
                        ),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                          height: 40
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) {
                                return const SignUpPage();
                              }),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            textStyle: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child:Text(
                            'Sign Up',
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w100,
                              fontSize : 16
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ]
      )
    );
  }
}
