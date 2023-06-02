import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'main.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  String getErrorMessage(String errorCode){
    switch(errorCode){
      case 'invalid-email':
        return 'メールアドレスを入力して下さい';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードが短すぎます。６文字以上で設定して下さい。';
      default:
        return '。再度試して下さい';
    }
  }

  Future<void> _signUp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _mailController.text,
        password: _passwordController.text,
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) {
          return const MyPage();
        }),
      );
    } catch (e) {
      String errorMessage;
      if(e is FirebaseAuthException){
        String errorCode = e.code;
        errorMessage = getErrorMessage(errorCode);
      } else {
        errorMessage = e.toString(); 
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'エラー'
            ),
            content: Text(
              '新規登録時にエラーが発生しました: $errorMessage'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  '閉じる'
                ),
              ),
            ],
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //背景画像
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/signUp.jpg'), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          //ぼかし効果
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5.0,
              sigmaY: 5.0
            ), 
            child: Container(
              color: Colors.black.withOpacity(0), 
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.5), 
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 24
                      ),
                      TextFormField(
                        controller: _mailController,
                        decoration:  InputDecoration(
                          labelText: 'メールアドレス',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: const OutlineInputBorder(),
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
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                            icon: Icon(
                              _isObscure ? Icons.visibility_off : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _signUp();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white.withOpacity(0.6),
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
                          'Sign Up',
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w100
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                              return const LoginPage();
                            }),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white.withOpacity(0.6),
                          textStyle: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:Text(
                          'Login',
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
        ],
      ),
    );
  }
}