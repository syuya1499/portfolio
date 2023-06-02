import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PhotoLibraryPage extends StatefulWidget {
  const PhotoLibraryPage({Key? key}) : super(key: key);

  @override
  _PhotoLibraryPageState createState() => _PhotoLibraryPageState();
}

class _PhotoLibraryPageState extends State<PhotoLibraryPage> {
  late Future<List<String>> _imageUrlsFuture;
    late Future<List<String>> _datesFuture;

  @override
  void initState() {
    super.initState();
    _imageUrlsFuture = _fetchAllImages();
    _datesFuture = _fetchDates();
  }

  //全ての画像URL取得
  Future<List<String>> _fetchAllImages() async {
    ListResult result = await FirebaseStorage.instance.ref().list();
    List<String> imageUrls = [];
    for (var item in result.items) {
      String url = await item.getDownloadURL();
      imageUrls.add(url);
    }
    return imageUrls;
  }

  //日付と画像URLが対応するリストの作成
  Future<List<String>> _fetchDates() async {
    QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('myList').get();
    List<String> dates = [];
    List<String> imageUrls = await _fetchAllImages();
    int index = 0;
    for (var doc in querySnapshot.docs) {
      Timestamp timestamp = doc['date'];
      String date = DateFormat('yyyy-MM-dd')
      .format(timestamp.toDate());
      // 画像の対応が存在する場合のみ追加
      if (index < imageUrls.length) {
        dates.add(date);
        index++;
      }
    }
    return dates;
  }

    //写真をタップした際に拡大
    void _onImageTap(BuildContext context, String imageUrl) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      );
    }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF344955),
        title: Text(
          'Photo View',
          style: GoogleFonts.adventPro(
            color: Colors.white, 
            fontSize: 20,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _imageUrlsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              List<String> imageUrls = snapshot.data!;
              return FutureBuilder<List<String>>(
                future: _datesFuture,
                builder:
                  (BuildContext context, AsyncSnapshot<List<String>> dateSnapshot) {
                  if (dateSnapshot.connectionState == ConnectionState.done) {
                    if (dateSnapshot.hasData) {
                      List<String> myList = dateSnapshot.data!;
                      if (imageUrls.length != myList.length) {
                        return Center(
                          child: Text(
                            '画像と日付データの数が一致しません',
                            style: GoogleFonts.bizUDGothic(fontSize: 20),
                          ),
                        );
                      }
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
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: imageUrls.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0x0ff85dcb),
                                    Color(0xFF45A29E),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 8,
                                    offset: const Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                        _onImageTap(context, imageUrls[index]),
                                      child: Image.network(
                                        imageUrls[index],
                                        fit: BoxFit.cover,
                                        height: double.infinity,
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                            BorderRadius.circular(15),
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        child: Text(
                                          myList[index],
                                          style: GoogleFonts.bizUDGothic(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return const Center(
                        child: Text('日付データがありません')
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator()
                    );
                  }
                },
              );
            } else {
              return const Center(
                child: Text('画像がありません')
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator()
            );
          }
        },
      ),
    );
  }
}
