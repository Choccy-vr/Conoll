import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase/auth/Auth.dart';
import 'services/supabase/auth/auth_listener.dart';
import 'package:conoll/pages/Home_Page.dart';
import 'package:conoll/pages/Login/Login_page.dart';

const supabaseUrl = 'https://gdsgkuokgxtcqdjndxin.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdkc2drdW9rZ3h0Y3Fkam5keGluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzMDg1MDIsImV4cCI6MjA3Mzg4NDUwMn0.mxyUFx6q6QOdpamHAWAnRtQeDaxky40uGiq2ywaaAqM';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(null, null);

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  AuthListener.startListening();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conoll',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      //home: HomePage(),
      home: FutureBuilder<bool>(
        future: Authentication.restoreStoredSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data == true) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
