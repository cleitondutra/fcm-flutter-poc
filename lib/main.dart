import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // título
    'This channel is used for important notifications.', // descrição
    importance: Importance.high,
    playSound: true);

const _url = 'https://dev-serap-estudante.sme.prefeitura.sp.gov.br';

void _abrirSerap() async => await canLaunch(_url)
    ? await launch(_url)
    : throw 'Não foi possível abrir $_url';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Acabou de aparecer uma mensagem:  ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste notificação',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Teste notificação - Página inicial'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    // EXECUTA QUANDO ESTA EM PRIMEIRO PLANO (COM O APP ABERTO)!
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) async {
      print('Um novo evento onMessage/Primeiro plano foi publicado!');

      if (remoteMessage.notification != null &&
          remoteMessage.notification?.android != null) {
        _abrirSerap();

        flutterLocalNotificationsPlugin.show(
            remoteMessage.notification?.hashCode ?? 0,
            remoteMessage.notification?.title ?? '',
            remoteMessage.notification?.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ));
      }
    });

    // EXECUTA QUANDO ESTA EM SEGUNDO PLANO (COM O APP FECHADO/MINIMIZADO MAS RODANDO E NÃO ENCERRADO)!
    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage remoteMessage) async {
      print('Um novo evento (onMessageOpenedApp/Segundo plano) foi publicado!');

      if (remoteMessage.notification != null &&
          remoteMessage.notification?.android != null) {
        _abrirSerap();
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(remoteMessage.notification?.title ?? ''),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(remoteMessage.notification?.body ?? '')],
                  ),
                ),
              );
            });
      }
    });
  }

  void exibirNotificacaoTeste() async {
    setState(() {
      _counter++;
    });
    flutterLocalNotificationsPlugin.show(
        0,
        "Teste $_counter",
        "Olá mundo ?",
        NotificationDetails(
            android: AndroidNotificationDetails(
                channel.id, channel.name, channel.description,
                importance: Importance.high,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Quantidade de vezes que você apertou o botão:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: exibirNotificacaoTeste,
        tooltip: 'Incremento',
        child: Icon(Icons.add),
      ),
    );
  }
}
