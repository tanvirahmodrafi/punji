import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punji/screens/auth/views/login_page.dart';
import 'package:punji/screens/home/blocs/get_expenses/get_expenses_bloc.dart';
import 'package:punji/screens/home/blocs/get_incomes/get_incomes_bloc.dart';
import 'package:punji/screens/home/views/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  State<MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  String? _lastLoadedUserId;

  void _refreshDataForUser(String userId) {
    if (_lastLoadedUserId == userId) {
      return;
    }
    _lastLoadedUserId = userId;
    context.read<GetExpensesBloc>().add(GetExpenses());
    context.read<GetIncomesBloc>().add(GetIncomes());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Punji",
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: Colors.grey.shade100,
          onSurface: Colors.black,
          primary: Color(0xFF00B2E7),
          secondary: Color(0xFFE064F7),
          tertiary: Color(0xFFFF8D6C),
          outline: Colors.grey.shade700,
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, _) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            _lastLoadedUserId = null;
            return const LoginPage();
          }

          _refreshDataForUser(user.id);
          return const HomeScreen();
        },
      ),
    );
  }
}
