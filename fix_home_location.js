const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\home_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Add dart:io and http imports
if (!content.includes("import 'dart:io';")) {
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:io';\nimport 'package:http/http.dart' as http;\nimport 'dart:convert';");
}

// Fix the fetch logic to use http.get directly and add Platform check
content = content.replace("final response = await ApiService().getRaw(url.toString());", "final responseData = await http.get(url, headers: {'User-Agent': 'AgriFarmsApp/1.0'});\n        final response = json.decode(responseData.body);");

fs.writeFileSync(filePath, content);
