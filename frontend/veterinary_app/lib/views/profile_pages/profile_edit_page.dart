import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';

class EditProfileService {
  final String editProfileUrl;

  EditProfileService({required this.editProfileUrl});

  Future<bool> updateProfile(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(editProfileUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    print('Update profile response status: ${response.statusCode}');
    print('Update profile response body: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _phone;

  bool _isLoading = false;

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    // Retrieve the token from SharedPreferences
    String? token = await TokenService.getToken();

    if (token != null) {
      // Prepare the data to be sent
      Map<String, dynamic> data = {
        'name': _name,
        'email': _email,
        'phone': _phone,
      };

      // Make the API call to update profile
      EditProfileService(
            editProfileUrl: 'https://your-api-url.com/profile/update',
          )
          .updateProfile(token, data)
          .then((success) {
            setState(() {
              _isLoading = false;
            });

            if (success) {
              // Handle success (e.g., show success message or navigate)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile updated successfully')),
              );
            } else {
              // Handle failure (e.g., show error message)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update profile')),
              );
            }
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred: $error')),
            );
          });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No token found. Please log in again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (value) {
                  _name = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (value) {
                  _email = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _phone,
                decoration: InputDecoration(labelText: 'Phone'),
                onSaved: (value) {
                  _phone = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        _updateProfile();
                      }
                    },
                    child: Text('Update Profile'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
