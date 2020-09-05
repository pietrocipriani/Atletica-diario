import 'dart:convert';
import 'dart:io';

import 'package:Atletica/atletica_me/athlete.dart';
import 'package:http/http.dart' as http;

Future<Iterable<Athlete>> searchAthletes(final String query) async {
  if (query == null || query.isEmpty) return <Athlete>[];
  final http.Response res = await http.post(
    'https://atletica.me/query/search_all.php',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {'nome': query},
  );

  if (res.statusCode != HttpStatus.ok) return <Athlete>[];

  return jsonDecode(res.body)
      .where((a) =>
          a['fonte'] == 'a' && a['terza_info'] == 'Fondazione M. Bentegodi')
      .map<Athlete>((a) => Athlete.parse(a));
}
