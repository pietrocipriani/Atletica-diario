import 'package:flutter/material.dart';

class Athlete {
  final String id;
  final String name;
  final String profilePhotoId;

  Athlete.parse(Map<String, dynamic> raw)
      : id = raw['id'],
        name = raw['nome'],
        profilePhotoId = raw['id_face'];

  @override
  String toString() => name;
}

class AthleteItemWidget extends StatelessWidget {
  final Athlete athlete;
  AthleteItemWidget(this.athlete);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: ClipOval(
          child: Image.network(
            athlete.profilePhotoId == null
                ? 'https://atletica.me/img/noimage.jpg'
                : 'https://graph.facebook.com/${athlete.profilePhotoId}/picture?width=70&height=70',
          ),
        ),
      ),
      title: Text(athlete.name),
    );
  }
}
