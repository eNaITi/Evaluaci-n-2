import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final ImagePicker picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();

  File? _image;
  int _selectedIndex = 0;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _pickImage(Function setDialogState) async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setDialogState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _publishPost() async {
    if (_image == null || _descriptionController.text.isEmpty || currentUser == null) return;

    final imageBytes = await _image!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    await db.collection("posts").add({
      "username": currentUser!.displayName?.isNotEmpty == true
          ? currentUser!.displayName
          : currentUser!.email ?? "Usuario desconocido",
      "description": _descriptionController.text,
      "imageBase64": base64Image,
      "timestamp": FieldValue.serverTimestamp(),
      "userId": currentUser!.uid,
      "likes": [], // <-- Inicializamos la lista de likes vacía
    });

    if (mounted) {
      setState(() {
        _image = null;
        _descriptionController.clear();
      });
    }
  }

  Future<void> _deletePost(String postId) async {
    await db.collection("posts").doc(postId).delete();
  }

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes, bool hasLiked) async {
    final postRef = db.collection("posts").doc(postId);

    if (hasLiked) {
      // Quitar like
      await postRef.update({
        "likes": FieldValue.arrayRemove([currentUser!.uid])
      });
    } else {
      // Dar like
      await postRef.update({
        "likes": FieldValue.arrayUnion([currentUser!.uid])
      });
    }
  }

  Widget _buildFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection("posts").orderBy("timestamp", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            final username = data["username"] ?? "Usuario";
            final description = data["description"] ?? "";
            final base64Image = data["imageBase64"];
            final userId = data["userId"] ?? "";
            final likes = List<String>.from(data["likes"] ?? []);

            final hasLiked = currentUser != null && likes.contains(currentUser!.uid);

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: currentUser != null && currentUser!.uid == userId
                          ? IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("¿Eliminar publicación?"),
                                    content: Text("¿Estás seguro de que quieres eliminar este post?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Cancelar"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deletePost(post.id);
                                          Navigator.pop(context);
                                        },
                                        child: Text("Eliminar"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : null,
                    ),
                    if (base64Image != null && base64Image.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.memory(
                          base64Decode(base64Image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(description),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              hasLiked ? Icons.favorite : Icons.favorite_border,
                              color: hasLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              _toggleLike(post.id, likes, hasLiked);
                            },
                          ),
                          Text('${likes.length}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfile() {
    if (currentUser == null) return Center(child: Text("No hay usuario autenticado."));

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection("posts")
          .where("userId", isEqualTo: currentUser!.uid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error al cargar publicaciones: ${snapshot.error}"));
        }

        final userPosts = snapshot.data?.docs ?? [];

        final userName = currentUser!.displayName ?? currentUser!.email ?? "Usuario";
        final userEmail = currentUser!.email ?? "";

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(userName.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(height: 8),
                Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(userEmail),
                const SizedBox(height: 8),
                Text("Total publicaciones: ${userPosts.length}"),
              ],
            ),
            const Divider(height: 32),
            ...userPosts.map((post) {
              final data = post.data() as Map<String, dynamic>;
              final description = data["description"] ?? "";
              final base64Image = data["imageBase64"];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (base64Image != null && base64Image.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 1,
                          child: Image.memory(
                            base64Decode(base64Image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(description),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showNewPostDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Nueva publicación"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _image == null
                        ? Text("No se ha seleccionado ninguna imagen.")
                        : Image.file(_image!),
                    SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(hintText: "Agrega una descripción..."),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _pickImage(setDialogState),
                      child: Text("Seleccionar Imagen"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    await _publishPost();
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: Text("Publicar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildFeed(),
      Center(child: Text("Explorar (pendiente)")),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        centerTitle: true,
        title: Text("iñstagra"),
      ),
      backgroundColor: Colors.grey[100],
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showNewPostDialog,
              backgroundColor: Colors.cyan,
              child: Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.cyan,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}