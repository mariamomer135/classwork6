import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC6eRtLuAKB42woCFNgMkD-bc8a8Zviv4M",
      authDomain: "classwork6-bb4a9.firebaseapp.com",
      projectId: "classwork6-bb4a9",
      storageBucket: "classwork6-bb4a9.appspot.com",
      messagingSenderId: "301929031781",
      appId: "1:301929031781:web:7e7a67d9f8736e79193e8c",
    ),
  );

  runApp(TaskApp());
}

class TaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primaryColor: Color(0xFFFF6F61), // Coral
        scaffoldBackgroundColor: Color(0xFFFFE5EC), // Light Blush
        colorScheme: ColorScheme.light(
          secondary: Color(0xFFE0BBE4), // Lavender
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFF6F61),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFD6A5), // Peach
            foregroundColor: Color(0xFF4A148C), // Deep Plum
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFFFF6F61),
          ),
        ),
        cardTheme: CardTheme(
          color: Color(0xFFFFE5EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF4A148C),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'DancingScript',
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF4A148C),
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.hasData) return TaskListScreen();
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login(BuildContext context) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
  }

  void register(BuildContext context) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Color(0xFFFF6F61)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF6F61)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Color(0xFFFF6F61)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF6F61)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => login(context),
              child: Text("Login"),
            ),
            TextButton(
              onPressed: () => register(context),
              child: Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  String id;
  String title;
  bool isDone;
  List<Map<String, dynamic>> subTasks;

  Task({required this.id, required this.title, required this.isDone, required this.subTasks});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
      'subTasks': subTasks,
    };
  }

  static Task fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
      subTasks: List<Map<String, dynamic>>.from(data['subTasks'] ?? []),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController taskController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get taskCollection =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks');

  void addTask() {
    final title = taskController.text.trim();
    if (title.isNotEmpty) {
      taskCollection.add({
        'title': title,
        'isDone': false,
        'subTasks': [],
      });
      taskController.clear();
    }
  }

  void toggleTask(Task task) {
    taskCollection.doc(task.id).update({'isDone': !task.isDone});
  }

  void deleteTask(Task task) {
    taskCollection.doc(task.id).delete();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      labelText: "Enter task name",
                      labelStyle: TextStyle(color: Color(0xFFFF6F61)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF6F61)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addTask,
                  child: Text("Add"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: taskCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                final tasks = snapshot.data!.docs.map((doc) => Task.fromDoc(doc)).toList();

                return ListView(
                  children: tasks.map((task) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Checkbox(
                              value: task.isDone,
                              activeColor: Color(0xFFFF6F61),
                              onChanged: (_) => toggleTask(task),
                            ),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A148C),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Color(0xFFFF6F61)),
                              onPressed: () => deleteTask(task),
                            ),
                          ],
                        ),
                        children: task.subTasks.map((sub) {
                          return ListTile(
                            title: Text("${sub['time']} - ${sub['desc']}",
                                style: TextStyle(color: Color(0xFF4A148C))),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
