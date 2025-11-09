import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String city;
  final String ward;
  final String street;
  final String houseNumber;

  Address({
    required this.city,
    required this.ward,
    required this.street,
    required this.houseNumber,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      city: map['city'] ?? '',
      ward: map['ward'] ?? '',
      street: map['street'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'ward': ward,
      'street': street,
      'houseNumber': houseNumber,
    };
  }

  String get fullAddress {
    return '$houseNumber $street, $ward, $city';
  }
}

class School {
  final String name;
  final int yearIn;
  final int yearOut;
  final String address;

  School({
    required this.name,
    required this.yearIn,
    required this.yearOut,
    required this.address,
  });

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      name: map['name'] ?? '',
      yearIn: map['yearIn'] ?? 0,
      yearOut: map['yearOut'] ?? 0,
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'yearIn': yearIn,
      'yearOut': yearOut,
      'address': address,
    };
  }
}

class Person {
  final String name;
  final String email;
  final Address address;
  final List<School> school;

  Person({
    required this.name,
    required this.email,
    required this.address,
    required this.school,
  });

  factory Person.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Person(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      address: Address.fromMap(data['address'] ?? {}),
      school: (data['school'] as List<dynamic>?)
              ?.map((s) => School.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'address': address.toMap(),
      'school': school.map((s) => s.toMap()).toList(),
    };
  }
}