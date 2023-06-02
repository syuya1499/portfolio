import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';

class PasswordResetForm extends StatelessWidget {
  const PasswordResetForm({Key? key}) : super(key: key);

  String getErrorMessage(String errorCode){
    switch(errorCode){
      case 'invalid-email':
        return 'メールアドレスを入力して下さい';
      case 'user-not-found':
        return 'このメールアドレスは存在しません';
      default:
        return '再度試して下さい';
    }
  } 

  @override
  Widget build(BuildContext context) {
    final TextEditingController _mailController = TextEditingController();
    return Scaffold(
      body: Stack(
        children: [
          //背景画像
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/resetPassword.jpg'),
                fit: BoxFit.cover
              )
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5.0,
              sigmaY: 5.0
            )
          ),
          Align(
            alignment: const Alignment(0, 0.7),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'パスワードの変更',
                        style: GoogleFonts.bizUDGothic(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mailController,
                        decoration: InputDecoration(
                          labelText: 'メールアドレス',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(
                              color: Colors.blue
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white54,
                        ),
                      ),
                      const SizedBox(
                        height: 20
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final String email = _mailController.text;
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'パスワードリセットメール送信済み'
                                ),
                                content: const Text(
                                  'パスワードリセットの手順を含むメールを送信しました。'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            String errorMessage = 'パスワード変更メールの送信に失敗しました。';
                            if (e is FirebaseAuthException) {
                              errorMessage += '\n ${getErrorMessage(e.code)}';
                            } else {
                              errorMessage += '\n $e';
                            }
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('エラー'),
                                content: Text(errorMessage),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          side: const BorderSide(
                            color: Colors.black
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'メールを送信',
                          style: GoogleFonts.bizUDGothic(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) {
                                return const LoginPage();
                              }),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          side: const BorderSide(
                            color: Colors.black
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:Text(
                          'Login',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.black,
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
        ]
      ),
    );
  }
}
