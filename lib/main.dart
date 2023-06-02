import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo/login.dart';
import 'package:photo/photo_library.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'item.dart';

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 
    Intl.defaultLocale = 'ja_JP';
    await Firebase.initializeApp( 
      options: DefaultFirebaseOptions.android,
    );
  initializeDateFormatting('ja_JP').then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return const LoginPage();  
            } else {
              return const MyPage();  
            }
          }
          return const CircularProgressIndicator();  
        },
      ),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

  final FirebaseFirestore firestore = FirebaseFirestore.instance;//Firestoreデータベースのインスタンスを生成する。
 
class _MyPageState extends State<MyPage> {
  final CollectionReference<Map<String, dynamic>> myCollection = firestore.collection('myList');//リストの各項目に対するドキュメントを作成
  final ImagePicker _picker = ImagePicker();
  List<Item> activities = [];
  Future<void>? _initializeDataFuture;
  bool isLoading = false;// データの読み込み
  bool _tutorialShown = false;//チュートリアルが表示されたかどうか
  //以下はチュートリアルで使用
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];
  final GlobalKey _key = GlobalKey();
  final GlobalKey _key1 = GlobalKey();
  final GlobalKey _key2 = GlobalKey();

  @override
  void initState() {
    initTargets();
    WidgetsBinding.instance.addPostFrameCallback(_layout);
    _initializeDataFuture = _initializeData();
    super.initState();
  }

  //初期化時
  Future<void> _initializeData() async {
    await FirebaseFirestore.instance
      .collection('myList')
      .get()
      .then((querySnapshot) {
      if(mounted) {
        setState(() {
          activities = List.generate(
            querySnapshot.size,
            (index) => Item(
              description: '',
              date: null,
              image: null,
              controller: TextEditingController(),
            ),
            growable: true,
          );
        });
        for (var doc in querySnapshot.docs) {
          final index = int.parse(doc.id);
          final value = doc.data()['value'];
          final date = doc.data()['date']?.toDate();
          final image = doc.data()['image']; 
          if(mounted) {
            setState(() {
              activities[index] = Item(
                description: value,
                date: date,
                image: image,
                controller: TextEditingController(text: value)
              );
            });
          }
        }
      }
    });
  }

  //遅延メソッド
  void _layout(_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if(!_tutorialShown){
      showTutorial();
      _tutorialShown = true;
    }
  }

  // 登録時にて情報をFirestoreに保存する
  void saveData(int index, String value ,DateTime? date) async {
    await myCollection.doc(index.toString()).set({
      'value': value,
      'date': date != null ? Timestamp.fromDate(date) : null,
    });
  }

  //編集時にて情報をFIrestoreに保存
  Future<void> editSaveData(int index, String description, DateTime date, String imageUrl) async {
    final docRef = myCollection.doc(index.toString());
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      // ドキュメントが存在する場合は、データを更新
      await docRef.update({
        'value': description,
        'date': Timestamp.fromDate(date), 
        'imageUrl': imageUrl,
      });
    } else {
      // ドキュメントが存在しない場合は、新しいドキュメントを作成してデータを保存
      await docRef.set({
        'value': description,
        'date': Timestamp.fromDate(date), 
        'imageUrl': imageUrl,
      });
    }
  }

  //登録の際
  Future<void> _customFunction(int index) async {
    // ボタンが押されたときに、現在のテキストフィールドの値をFirestoreに保存
    saveData(index, activities[index].description, activities[index].date);
    //選択された写真がある場合Firestoreに保存
    if (activities[index].image != null) {
      final String imageUrl = await _uploadImageToFirebase(index, activities[index].image!);
      await _saveImageUrlToFirestore(index, imageUrl);
    }
  }

  //編集の際
  Future<void> _editCustomFunction(int index, String imageUrl) async {
    // dateがnullの場合は、現在の日付をデフォルト値
    editSaveData(index, activities[index].description, activities[index].date ?? DateTime.now(), imageUrl);
  }

  //削除ボタン
  Future<void> _deleteItem(int index) async {
    if (index < 0 || index >= activities.length) {
      return;
    }
    // Firestoreから画像のURLを取得
    final String imageUrl = await _getImageFromFirebase(index);
    // アラートダイアログの表示
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '削除確認'
          ),
          content: const Text(
            '本当に削除しますか？'
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'キャンセル'
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '削除'
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }
    // Firestoreドキュメントを削除
    await myCollection.doc(index.toString()).delete();
    // Firestorageの写真を削除
    await _deleteImageFromFirebase(imageUrl);
    // 配列から要素を削除
    setState(() {
      activities.removeAt(index);
    });
    // 削除前の activities の長さを保存
    int oldLength = activities.length + 1;
    for (int i = index + 1; i < oldLength; i++) {
      String updatedImageUrl = await _getUpdatedImageUrl(i - 1);
      if (updatedImageUrl.isNotEmpty) {
          activities[i - 1].image = File(updatedImageUrl);
        } else {
          activities[i - 1].image = null;
        }
      if (i != oldLength - 1) {
        // コレクション内の各ドキュメントを取得
        DocumentSnapshot<Map<String, dynamic>> myCollectionDoc =
          await myCollection.doc(i.toString()).get();
        // ドキュメントIDをデクリメントして新しいドキュメントを作成し、データをコピー
        if (myCollectionDoc.data() != null) {
          await myCollection.doc((i - 1).toString()).set(myCollectionDoc.data()!);
        }
        // 元のドキュメントを削除
        await myCollection.doc(i.toString()).delete();
        } else {
        // コレクション内の各ドキュメントを取得
        DocumentSnapshot<Map<String, dynamic>> myCollectionDoc =
          await myCollection.doc(i.toString()).get();
        // ドキュメントIDをデクリメントして新しいドキュメントを作成し、データをコピー
        if (myCollectionDoc.data() != null) {
          await myCollection.doc((i - 1).toString()).set(myCollectionDoc.data()!);
        }
        // 元のドキュメントを削除
        await myCollection.doc(i.toString()).delete();
      }
    }
    _initializeData();
  }

    //FirebaseStorageに画像をアップロード
  Future<String> _uploadImageToFirebase(int index, File imageFile) async {
    final String fileName = 'myImage_${DateTime.now().millisecondsSinceEpoch}.jpg'; 
    final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    final UploadTask uploadTask = storageRef.putFile(imageFile);
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    setState(() {
      activities[index].image = imageFile;
    });
    return downloadUrl;
  }
  //Firebase Firestoreに画像のURLを保存
  Future<void> _saveImageUrlToFirestore(int index, String imageUrl) async {
    // ドキュメントが存在するかどうかを確認
    final docRef = myCollection.doc(index.toString());
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      // ドキュメントが存在する場合は、データを更新
      await docRef.update({
        'imageUrl': imageUrl,
      });
    } else {
      // ドキュメントが存在しない場合は、新しいドキュメントを作成してデータを保存
      await docRef.set({
        'value': activities[index].description,
        'imageUrl': imageUrl,
      });
    }
  }

  //Firebase Firestoreから画像のURLを取得
  Future<String> _getImageFromFirebase(int index) async {
    final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
    await myCollection.doc(index.toString()).get();
    final String imageUrl = docSnapshot.data()?['imageUrl'] ?? '';
    return imageUrl;
  }

  //Firebase Firestoreから更新された画像のURLを取得
  Future<String> _getUpdatedImageUrl(int index) async {
    DocumentSnapshot<Map<String, dynamic>> myCollectionDoc =
      await myCollection.doc(index.toString()).get();
      if (myCollectionDoc.data() != null && myCollectionDoc.data()!['image_url'] != null) {
        return myCollectionDoc.data()!['image_url'];
      } else {
        return '';
      }
  }

  //Firebase Storageから画像を削除
  Future<void> _deleteImageFromFirebase(String imageUrl) async {
    // URLが空でない場合にのみ削除処理を実行
    if (imageUrl.isNotEmpty) {
      final Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      try {
        await storageRef.delete();
      } catch (e) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'エラー',
                style: GoogleFonts.bizUDGothic(),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '画像の削除中にエラーが発生しました。詳細:',
                    style: GoogleFonts.bizUDGothic(),
                  ),
                  Text(
                    '$e',
                    style: GoogleFonts.bizUDGothic()
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '閉じる',
                    style: GoogleFonts.bizUDGothic()
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  //日付・写真・テキスト全て入力されているかどうかの判別
  bool _isRegisterButtonEnabled(
    List<DateTime?> selectedDates,
    String text,
    File? image,
  ) {
    return selectedDates.every((date) => date != null) && text.isNotEmpty && image != null;
  }

  //サインアウト
  void _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "サインアウト",
            style: GoogleFonts.bizUDGothic()
          ),
          content: Text(
            "本当にサインアウトしますか？",
            style: GoogleFonts.bizUDGothic()
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } catch (e) {
                  print(e);
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          "エラー",
                          style: GoogleFonts.bizUDGothic()
                        ),
                        content: Text(
                          "サインアウトに失敗しました。もう一度お試しください。",
                          style: GoogleFonts.bizUDGothic()
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "閉じる",
                              style: GoogleFonts.bizUDGothic()
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text(
                "はい",
                style: GoogleFonts.bizUDGothic()
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "キャンセル",
                style: GoogleFonts.bizUDGothic()
              ),
            ),
          ],
        );
      },
    );
  }


  //登録メソッド
  void _showRegistrationPage(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    DateTime? selectedDate;
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {  
          return SingleChildScrollView(
            padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1C1C1C)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'new memory',
                    style: GoogleFonts.ruda(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 日付選択
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(selectedDate != null
                            ? (DateFormat.yMMMd('ja_JP'))
                            .format(selectedDate!)
                            : 'いつの思い出？',
                            style: GoogleFonts.bizUDGothic(
                              color: Colors.white,
                              fontSize: 18
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.date_range,
                              color: Colors.white
                            ),
                            onPressed: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020, 1),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  // 画像選択
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setImageState) {
                    return OutlinedButton(
                      onPressed: () async {
                        final XFile? image =
                          await _picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final File imageFile = File(image.path);
                              setState(() {
                                selectedImage = imageFile;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white
                          ),
                        ),
                        child: Text(
                          '写真を選択',
                          style: GoogleFonts.bizUDGothic(
                          color: Colors.white
                        )
                      ),
                    );
                  }
                ),
                  // 選択された画像を表示する Container
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setImageState) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: selectedImage != null
                          ? Image.file(
                            selectedImage!,
                            fit: BoxFit.contain
                          )
                          :  Center(
                            child: Text(
                              '画像が選択されていません',
                              style: GoogleFonts.bizUDGothic(
                                color: Colors.white
                              ),
                            )
                          ),
                        );
                      }
                    ),
                  TextFormField(
                    controller: textController,
                    style: GoogleFonts.bizUDGothic(
                      color: Colors.white
                    ),
                    decoration: InputDecoration(
                      hintText: '何して遊んだ？',
                      hintStyle: GoogleFonts.bizUDGothic(
                        color: const Color.fromARGB(138, 124, 124, 136)
                      ),
                      filled: true,
                      fillColor: const Color(0xFF3C3C3C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0x0ff85dcb)
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 登録ボタン
                  ElevatedButton(
                    onPressed: () {
                      if (_isRegisterButtonEnabled(
                        [selectedDate], textController.text, selectedImage)) {
                          setState(() {
                            activities.add(Item(
                              description: textController.text,
                              date: selectedDate!,
                              image: selectedImage!,
                              controller: textController,
                            ));
                          });
                          _customFunction(activities.length - 1);
                          Navigator.pop(context);
                        }
                      },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _isRegisterButtonEnabled(
                            [selectedDate], textController.text, selectedImage
                          )
                        ? const Color(0x0ff85dcb)
                        : Colors.grey,
                        textStyle: GoogleFonts.bizUDGothic(
                          fontSize: 16
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '登録'
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  //編集ボタン
  void _showEditPage(BuildContext context, int index) {
    final TextEditingController textController = TextEditingController(text: activities[index].description);
    DateTime? selectedDate = activities[index].date;
    File? selectedImage = activities[index].image;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) { 
            if(isLoading){
              return const CircularProgressIndicator();
            }  
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF1C1C1C),
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                  children: [
                    // 日付選択
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedDate != null
                            ? (DateFormat.yMMMd('ja_JP'))
                            .format(selectedDate!)
                            : '日付', 
                          style: GoogleFonts.bizUDGothic(
                            color: Colors.white,
                            fontSize: 18
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.date_range,
                            color: Colors.white
                          ),
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020, 1),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    // 画像選択
                    OutlinedButton(
                      onPressed: () async {
                        final XFile? image =
                          await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final File imageFile = File(image.path);
                          setState(() {
                            selectedImage = imageFile;
                          });
                        }
                      },
                        style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.white
                        ),
                      ),
                      child: Text(
                        '写真を選択',
                        style: GoogleFonts.bizUDGothic(
                          color: Colors.white
                        )
                      ),
                    ),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: selectedImage != null
                      ? Image.file(
                        selectedImage!,
                        fit: BoxFit.contain,
                      )
                      : Center(
                        child: Text(
                          '画像を変更する場合は選択してね！',
                          style: GoogleFonts.bizUDGothic(
                            color : Colors.white
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: textController,
                      style: GoogleFonts.bizUDGothic(
                        color: Colors.white
                      ),
                      decoration: InputDecoration(
                        hintText: '何して遊んだ？',
                        hintStyle: GoogleFonts.bizUDGothic(
                          color: const Color.fromARGB(138, 124, 124, 136)
                        ),
                        filled: true,
                        fillColor: const Color(0xFF3C3C3C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color(0x0ff85dcb)
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16
                    ),
                    // 更新ボタン
                    ElevatedButton(
                      onPressed: () async {
                        String previousImageUrl = await _getImageFromFirebase(index);
                        String newImageUrl = previousImageUrl; 
                        // 新しい画像が選択されていればFirebaseにアップロードし、新しいURLを取得する
                        if (selectedImage != null) {
                          newImageUrl = await _uploadImageToFirebase(index, selectedImage!);
                          // 以前の画像を削除する
                          if (previousImageUrl.isNotEmpty) {
                            await _deleteImageFromFirebase(previousImageUrl);
                          }
                        }
                        this.setState(() {
                          activities[index] = Item(
                            description: textController.text,
                            date: selectedDate!,
                            image: selectedImage ?? activities[index].image,
                            controller: textController,
                          );
                        });
                        await _editCustomFunction(index, newImageUrl);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _isRegisterButtonEnabled(
                          [selectedDate],
                          textController.text,
                          selectedImage,
                        )
                        ? const Color(0x0ff85dcb)
                        : Colors.grey,
                        textStyle: GoogleFonts.bizUDGothic(
                          fontSize: 16
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                      ),
                      child: const Text('更新')
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(
            0xFF344955
          ),
          title: Text(
            'Memory',
            style: GoogleFonts.adventPro(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showRegistrationPage(context);
                    },
                    key: _key,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFB7C3C4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8
                      ),
                    ),
                    child: Text(
                      '登録',
                      style: GoogleFonts.bizUDGothic(
                        fontSize: 14,
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  SizedBox(
                    key: _key1,
                    child: IconButton(
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 32),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhotoLibraryPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  IconButton(
                    onPressed: (){
                      _signOut();
                    }, 
                    key: _key2,
                    icon: const Icon(
                      Icons.exit_to_app_rounded,
                      size: 35,
                    )
                  )
                ],
              ),
            ),
          ],
        ),
          body: FutureBuilder(
            future: _initializeDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF344955),
                        Color(0xFF232F34),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemExtent: 320,
                          shrinkWrap: true,
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              margin:
                              const EdgeInsets.symmetric(
                                horizontal: 20, 
                                vertical: 8
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromARGB(255, 211, 219, 222),
                                      Color.fromARGB(255, 249, 250, 251),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Color.fromARGB(255, 41, 65, 79)
                                                  ),
                                                  onPressed: () =>
                                                  _showEditPage(context, index),
                                                ),
                                              ),
                                              Text(
                                                activities[index].date != null
                                                ? (DateFormat.yMMMd('ja_JP'))
                                                .format(activities[index].date!)
                                                : '日付',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.bizUDGothic(
                                                  color: const Color(0xFF263238),
                                                  fontSize: 18,),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Color(0xFF263238)),
                                            onPressed: () => _deleteItem(index),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                    ListTile( 
                                      title: TextFormField(
                                        style: GoogleFonts.bizUDGothic(
                                          fontSize: 16, color: const Color(0xFF263238),
                                        ),
                                        enabled: false,
                                        controller: activities[index].controller,
                                        maxLines: 3, 
                                        textInputAction: TextInputAction.newline, 
                                        decoration: InputDecoration(
                                          hintText: '何して遊んだ？',
                                          hintStyle: GoogleFonts.bizUDGothic(color: Colors.grey),
                                          border: OutlineInputBorder( 
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      contentPadding:const EdgeInsets.symmetric(horizontal: 30.0),
                                      subtitle: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height:16),
                                            if (activities[index].image != null)
                                              GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return Dialog(
                                                        child: GestureDetector(
                                                          onTap: () => Navigator.of(context).pop(),
                                                          child: Image.file(
                                                            activities[index].image!,
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );                                                 
                                                },
                                                child: Image.file(
                                                  activities[index].image!,
                                                  fit: BoxFit.cover,
                                                  height: 130,
                                                ),
                                              )
                                            else
                                            FutureBuilder(
                                              future: _getImageFromFirebase(index),
                                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                              if (snapshot.connectionState == ConnectionState.done) {
                                              if (snapshot.data!.isNotEmpty) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return Dialog(
                                                          child: GestureDetector(
                                                            onTap: () => Navigator.of(context).pop(),
                                                            child: Image.network(
                                                              snapshot.data!,
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Image.network(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                    height: 130,
                                                  ),
                                                );
                                                } else {
                                                  return const SizedBox.shrink();
                                                }
                                              } else {
                                                return const CircularProgressIndicator();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],  
                                ),
                              )
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
            } else {
              return const Center(
                child: CircularProgressIndicator()
              );
            }
          },
        ),
      ),
    );
  }

  void initTargets() {
    targets.add(
      TargetFocus(
        identify: "Target 0",
        keyTarget: _key,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "登録ボタン", 
                  style: GoogleFonts.bizUDGothic(
                    color: Colors.white, 
                    fontSize: 24.0, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(
                  height: 40
                ),
                SizedBox(
                  width: 150,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: (){
                      null;
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFFB7C3C4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10
                        ),
                      ), 
                    child: Text(
                      '登録',
                      style: GoogleFonts.bizUDGothic(
                        fontSize: 30,
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30
                ),
                const Text(
                  "登録ボタンでは、日付・写真・テキストを入力できます。\n\nあなた独自の思い出リストを作成しよう!",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold
                    ),
                ),
              ],
            ),
          )
        ],
        shape: ShapeLightFocus.Circle,
        radius: 10,
        color: Colors.black45
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Target 1",
        keyTarget: _key1,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '写真一覧',
                  style: GoogleFonts.bizUDGothic(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight : FontWeight.bold
                  ),
                ),
                const SizedBox(
                  height : 24
                ),
                IconButton(
                  onPressed: (){
                    null;
                  },
                  icon: const Icon(
                    Icons.photo_library_outlined
                  ),
                  color: Colors.white,
                  iconSize: 120,
                ),
                const SizedBox(
                  height: 20
                ),
                const Text(
                  "今までに登録した思い出の写真が\n一覧として見ることができます。",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            )
          )
        ],
        shape: ShapeLightFocus.Circle,
        radius: 5,
        color: Colors.black45
      ),
    );
    targets.add(
      TargetFocus(
        identify: 'Target 2',
        keyTarget: _key2,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children:<Widget>[
                Text(
                  'サインアウト',
                  style: GoogleFonts.bizUDGothic(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                IconButton(
                  onPressed: (){
                    null;
                }, 
                  icon: const Icon(
                    Icons.exit_to_app_rounded
                  ),
                  color: Colors.white,
                  iconSize: 120,
                ),
                const SizedBox(
                  height: 20
                ),
                Text(
                  'サインアウトしたい際に使用します。',
                  style: GoogleFonts.bizUDGothic(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ),
                )
              ],
            )
          )
        ],
        shape: ShapeLightFocus.Circle,
        radius: 5,
        color: Colors.black45
      )
    );
  }

  void showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      textSkip: "SKIP",
      paddingFocus: 5,
      opacityShadow: 0.9,
    )..show(context: context);
  }
}