import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension CollectionHelper on FirebaseFirestore {
  UserHelperCollection get users => collection('users').withConverter(
        fromFirestore: (snapshot, _) => UserHelper.parse(snapshot),
        toFirestore: (helper, _) => helper.toMap,
      );
}

typedef UserHelperCollection = CollectionReference<UserHelper>;
