import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CoachHelper extends FirebaseUserHelper {
  final Stream<QuerySnapshot> requests;

  CoachHelper(
      {@required FirebaseUser user, @required DocumentReference userReference})
      : requests = firestore
            .collection('requests')
            .where('coach', isEqualTo: userReference)
            .snapshots(),
        super(user: user, userReference: userReference);

  Future<void> acceptRequest(
      DocumentReference request, DocumentReference athlete) async {
    refuseRequest(request);
    firestore.collection('coaches').document(user.uid).updateData({
      'athletes': FieldValue.arrayUnion([athlete])
    });
  }

  Future<void> refuseRequest(DocumentReference request) async {
    await request.delete();
  }
}
