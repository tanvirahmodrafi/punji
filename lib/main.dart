import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:punji/app.dart';
import 'package:punji/simple_bloc_observer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xkxegziupnnwecsvuwgm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhreGVneml1cG5ud2Vjc3Z1d2dtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MDY3NzMsImV4cCI6MjA4NzA4Mjc3M30.N5w7E_cHYVSHcBnB0YNel0Vv7VstedJZHTXOcQ5d9vs',
  );

  Bloc.observer = SimpleBlocObserver();
  runApp(const MyApp());
}
