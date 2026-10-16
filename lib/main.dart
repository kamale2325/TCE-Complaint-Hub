
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTANT: Replace these four WEB values with your Firebase project's
// Web app configuration from Firebase Console > Project settings > Your apps.
// Android uses google-services.json and Firebase.initializeApp() below.
const String webApiKey = "AIzaSyAil38vOmRziFLusYChXkmQiD9wUcAIuXM";
const String webAppId = "1:797617207112:web:4e8af6d88a856f1b36a57d";
const String webMessagingSenderId = "797617207112";
const String firebaseProjectId = "tce-complaint-hub";


const maroon = Color(0xFF741D2B);
const gold = Color(0xFFC9A24A);
const ink = Color(0xFF29252A);
const pale = Color(0xFFF7F4F2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: webApiKey,
          appId: webAppId,
          messagingSenderId: webMessagingSenderId,
          projectId: firebaseProjectId,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    runApp(const ComplaintHubApp());
  } catch (e) {
    runApp(StartupErrorApp(message: e.toString()));
  }
}

class ComplaintHubApp extends StatelessWidget {
  const ComplaintHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCE Complaint Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pale,
        colorScheme: ColorScheme.fromSeed(seedColor: maroon),
        appBarTheme: const AppBarTheme(
          backgroundColor: maroon,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6DFDC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6DFDC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: maroon, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroon,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  final String message;
  const StartupErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'Firebase could not start.\n\nCheck your Firebase configuration and internet connection.\n\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user == null ? const AuthScreen() : const HubScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optional: replace this emblem with your TCE logo asset later.
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: maroon,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: maroon.withOpacity(.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(Icons.account_balance, color: gold, size: 66),
            ),
            const SizedBox(height: 22),
            const Text(
              'THIAGARAJAR COLLEGE\nOF ENGINEERING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: maroon,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                height: 1.4,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'TCE COMPLAINT HUB',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 21,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Your campus. Your voice.'),
            const SizedBox(height: 30),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: maroon,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'Enter an email and a password with at least 6 characters.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      UserCredential credential;
      if (register) {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'email': email.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HubScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = authError(e.code));
    } catch (e) {
      setState(() => error = 'Could not connect. Check internet and Firebase setup.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email already has an account. Please sign in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error: $code';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 26),
              Container(
                height: 82,
                width: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: maroon,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.campaign, color: gold, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'TCE Complaint Hub',
                style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: maroon),
              ),
              const SizedBox(height: 8),
              Text(
                register ? 'Create your student account' : 'Sign in to make your voice heard',
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Minimum 6 characters',
                ),
                onSubmitted: (_) => submit(),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(register ? 'Create account' : 'Sign in'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  register = !register;
                  error = null;
                }),
                child: Text(register
                    ? 'Already registered? Sign in'
                    : 'New here? Create an account'),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'THIAGARAJAR COLLEGE OF ENGINEERING',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45, fontSize: 11, letterSpacing: .5),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});
  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  int selected = 0;
  final pages = const [
    DashboardPage(),
    SubmitComplaintPage(),
    MyComplaintsPage(),
    HelpPage(),
  ];
  final titles = const ['Dashboard', 'Submit a complaint', 'My complaints', 'Help & support'];

  void go(int index) {
    setState(() => selected = index);
    if (Navigator.canPop(context) && MediaQuery.of(context).size.width < 700) {
      Navigator.pop(context);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 700;
    final content = pages[selected];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selected]),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: _menu()),
      body: Row(
        children: [
          if (wide) SizedBox(width: 245, child: _menu()),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: content,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Submit'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'My cases'),
          NavigationDestination(icon: Icon(Icons.help_outline), label: 'Help'),
        ],
      ),
    );
  }

  Widget _menu() => Container(
    color: Colors.white,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            color: maroon,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance, color: gold, size: 42),
                SizedBox(height: 12),
                Text('TCE COMPLAINT HUB',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Campus support portal',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _menuItem(Icons.home_outlined, 'Dashboard', 0),
          _menuItem(Icons.add_circle_outline, 'Submit complaint', 1),
          _menuItem(Icons.receipt_long_outlined, 'My complaints', 2),
          _menuItem(Icons.help_outline, 'Help & support', 3),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: maroon),
            title: const Text('Signed in'),
            subtitle: Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _menuItem(IconData icon, String label, int index) => ListTile(
    selected: selected == index,
    selectedColor: maroon,
    selectedTileColor: maroon.withOpacity(.08),
    leading: Icon(icon),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    onTap: () => go(index),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [maroon, Color(0xFF9A3947)]),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WELCOME TO TCE', style: TextStyle(color: gold, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Your campus,\nyour voice.',
                  style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('Report an issue. Track the progress. Help improve our campus.',
                  style: TextStyle(color: Colors.white70, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('Your complaint overview',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('complaints')
              .where('userId', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final total = docs.length;
            final pending = docs.where((d) => (d.data()['status'] ?? 'Submitted') == 'Submitted').length;
            final progress = docs.where((d) => d.data()['status'] == 'In Progress').length;
            final resolved = docs.where((d) => d.data()['status'] == 'Resolved').length;
            return GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 650 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                StatCard(label: 'Total', count: total, icon: Icons.receipt_long, color: maroon),
                StatCard(label: 'Submitted', count: pending, icon: Icons.schedule, color: Colors.orange),
                StatCard(label: 'In progress', count: progress, icon: Icons.autorenew, color: Colors.blue),
                StatCard(label: 'Resolved', count: resolved, icon: Icons.check_circle_outline, color: Colors.green),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Complaint categories',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            CategoryChip(icon: Icons.wifi, label: 'Wi-Fi / Internet'),
            CategoryChip(icon: Icons.computer, label: 'Lab equipment'),
            CategoryChip(icon: Icons.meeting_room, label: 'Classroom'),
            CategoryChip(icon: Icons.water_drop_outlined, label: 'Water / Sanitation'),
            CategoryChip(icon: Icons.electrical_services, label: 'Electrical'),
            CategoryChip(icon: Icons.more_horiz, label: 'Other'),
          ],
        ),
        const SizedBox(height: 24),
        const Text('How it works', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const InfoTile(icon: Icons.edit_note, title: '1. Submit', subtitle: 'Choose a category and describe the issue.'),
        const InfoTile(icon: Icons.track_changes, title: '2. Track', subtitle: 'Find your complaint and check its status.'),
        const InfoTile(icon: Icons.done_all, title: '3. Resolve', subtitle: 'The status can be updated by the support team.'),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const StatCard({super.key, required this.label, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFECE5E2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: color),
        Text('$count', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    ),
  );
}

class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const CategoryChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, color: maroon, size: 18),
    label: Text(label),
    backgroundColor: Colors.white,
    side: const BorderSide(color: Color(0xFFE9DFDB)),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
  );
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const InfoTile({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: maroon.withOpacity(.09),
        child: Icon(icon, color: maroon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    ),
  );
}

const complaintCategories = [
  'Wi-Fi / Internet',
  'Laboratory equipment',
  'Classroom facilities',
  'Water / Sanitation',
  'Electrical issue',
  'Hostel',
  'Library',
  'Transport',
  'Other',
];

class SubmitComplaintPage extends StatefulWidget {
  const SubmitComplaintPage({super.key});
  @override
  State<SubmitComplaintPage> createState() => _SubmitComplaintPageState();
}

class _SubmitComplaintPageState extends State<SubmitComplaintPage> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();
  String category = complaintCategories.first;
  String priority = 'Normal';
  bool sending = false;
  String? message;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> sendComplaint() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      sending = true;
      message = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final doc = await FirebaseFirestore.instance.collection('complaints').add({
        'userId': user.uid,
        'email': user.email,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'category': category,
        'priority': priority,
        'location': location.text.trim(),
        'status': 'Submitted',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => message = 'Complaint submitted successfully! ID: ${doc.id}');
      title.clear();
      description.clear();
      location.clear();
      setState(() {
        category = complaintCategories.first;
        priority = 'Normal';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your complaint has been saved to Firebase.')),
      );
    } catch (e) {
      setState(() => message = 'Could not save complaint. Check Firestore setup and internet.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Tell us what needs attention',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ink)),
      const SizedBox(height: 6),
      const Text('Give enough detail so the right team can respond.',
          style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 20),
      Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Complaint title', prefixIcon: Icon(Icons.title)),
              validator: (v) => v == null || v.trim().length < 4 ? 'Enter at least 4 characters.' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
              items: complaintCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => category = v ?? complaintCategories.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: location,
              decoration: const InputDecoration(labelText: 'Location (block / room / area)', prefixIcon: Icon(Icons.place_outlined)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter the issue location.' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(labelText: 'Priority', prefixIcon: Icon(Icons.flag_outlined)),
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (v) => setState(() => priority = v ?? 'Normal'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: description,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (v) => v == null || v.trim().length < 10 ? 'Please describe the issue in 10+ characters.' : null,
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              SelectableText(message!, style: TextStyle(color: message!.startsWith('Complaint submitted') ? Colors.green : Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: sending ? null : sendComplaint,
              icon: sending
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(sending ? 'Submitting...' : 'Submit complaint'),
            ),
          ],
        ),
      ),
    ],
  );
}

class MyComplaintsPage extends StatelessWidget {
  const MyComplaintsPage({super.key});

  Color statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Could not load complaints. Check your Firestore setup.'),
          ));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final at = a.data()['createdAt'] as Timestamp?;
            final bt = b.data()['createdAt'] as Timestamp?;
            return (bt?.millisecondsSinceEpoch ?? 0).compareTo(at?.millisecondsSinceEpoch ?? 0);
          });
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
                  SizedBox(height: 12),
                  Text('No complaints yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Your submitted complaints will appear here.', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text('${docs.length} complaint${docs.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final doc in docs)
              Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFECE5E2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(doc.data()['title'] ?? 'Untitled complaint',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor(doc.data()['status'] ?? 'Submitted').withOpacity(.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(doc.data()['status'] ?? 'Submitted',
                                style: TextStyle(color: statusColor(doc.data()['status'] ?? 'Submitted'), fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${doc.data()['category'] ?? 'Other'} • ${doc.data()['location'] ?? 'No location'}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(doc.data()['description'] ?? ''),
                      const SizedBox(height: 10),
                      Text('ID: ${doc.id}', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Help & support',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)),
      const SizedBox(height: 8),
      const Text('Need help using TCE Complaint Hub? Start here.'),
      const SizedBox(height: 20),
      const InfoTile(icon: Icons.edit_note, title: 'How do I submit a complaint?', subtitle: 'Open Submit, choose a category, enter the location and describe the issue, then tap Submit complaint.'),
      const InfoTile(icon: Icons.track_changes, title: 'How do I track it?', subtitle: 'Open My complaints. Your complaint and its current status appear there.'),
      const InfoTile(icon: Icons.lock_outline, title: 'Is my account required?', subtitle: 'Yes. Sign in so your complaints are linked to your account.'),
      const InfoTile(icon: Icons.sync, title: 'What do the statuses mean?', subtitle: 'Submitted: received. In Progress: being handled. Resolved: marked complete.'),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About the project', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            SizedBox(height: 8),
            Text('TCE Complaint Hub is a student mini-project designed to make campus issue reporting organised, trackable and accessible.'),
            SizedBox(height: 12),
            Text('Technology: Flutter • Firebase Authentication • Cloud Firestore',
                style: TextStyle(fontSize: 12, color: maroon, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
}