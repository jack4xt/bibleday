import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/verse.dart';
import 'bible_database_service.dart';

class BibleService {
  static const String _baseUrl = 'https://bible-api.com';
  static const String _getbibleUrl = 'https://api.getbible.net/v2';


  /// 365 referencí — jeden verš na každý den v roce
  static const List<Map<String, dynamic>> _dailyVerseRefs = [
    {'book': 'John', 'chapter': 3, 'verse': 16},
    {'book': 'Psalms', 'chapter': 23, 'verse': 1},
    {'book': 'Romans', 'chapter': 8, 'verse': 28},
    {'book': 'Philippians', 'chapter': 4, 'verse': 13},
    {'book': 'Jeremiah', 'chapter': 29, 'verse': 11},
    {'book': 'Matthew', 'chapter': 11, 'verse': 28},
    {'book': 'Isaiah', 'chapter': 40, 'verse': 31},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 5},
    {'book': 'Psalms', 'chapter': 46, 'verse': 1},
    {'book': 'John', 'chapter': 14, 'verse': 6},
    {'book': 'Romans', 'chapter': 12, 'verse': 2},
    {'book': 'Ephesians', 'chapter': 2, 'verse': 8},
    {'book': 'Psalms', 'chapter': 119, 'verse': 105},
    {'book': 'Matthew', 'chapter': 6, 'verse': 33},
    {'book': 'Proverbs', 'chapter': 22, 'verse': 6},
    {'book': 'Isaiah', 'chapter': 41, 'verse': 10},
    {'book': 'John', 'chapter': 15, 'verse': 13},
    {'book': 'Romans', 'chapter': 5, 'verse': 8},
    {'book': 'Psalms', 'chapter': 37, 'verse': 4},
    {'book': 'Matthew', 'chapter': 5, 'verse': 16},
    {'book': 'Galatians', 'chapter': 5, 'verse': 22},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 1},
    {'book': 'James', 'chapter': 1, 'verse': 17},
    {'book': 'Psalms', 'chapter': 27, 'verse': 1},
    {'book': 'John', 'chapter': 1, 'verse': 1},
    {'book': 'Romans', 'chapter': 3, 'verse': 23},
    {'book': 'Philippians', 'chapter': 4, 'verse': 7},
    {'book': 'Isaiah', 'chapter': 53, 'verse': 5},
    {'book': 'Psalms', 'chapter': 1, 'verse': 1},
    {'book': 'Matthew', 'chapter': 22, 'verse': 37},
    {'book': 'Colossians', 'chapter': 3, 'verse': 23},
    {'book': 'Proverbs', 'chapter': 16, 'verse': 3},
    {'book': 'John', 'chapter': 10, 'verse': 10},
    {'book': 'Romans', 'chapter': 6, 'verse': 23},
    {'book': 'Psalms', 'chapter': 121, 'verse': 2},
    {'book': 'Matthew', 'chapter': 28, 'verse': 19},
    {'book': 'Ephesians', 'chapter': 4, 'verse': 32},
    {'book': 'Isaiah', 'chapter': 26, 'verse': 3},
    {'book': 'Proverbs', 'chapter': 4, 'verse': 23},
    {'book': 'John', 'chapter': 8, 'verse': 32},
    {'book': 'Romans', 'chapter': 15, 'verse': 13},
    {'book': 'Psalms', 'chapter': 34, 'verse': 8},
    {'book': 'Matthew', 'chapter': 7, 'verse': 7},
    {'book': 'Philippians', 'chapter': 2, 'verse': 3},
    {'book': 'Isaiah', 'chapter': 43, 'verse': 1},
    {'book': 'Hebrews', 'chapter': 13, 'verse': 8},
    {'book': 'James', 'chapter': 4, 'verse': 8},
    {'book': 'Psalms', 'chapter': 139, 'verse': 14},
    {'book': 'John', 'chapter': 11, 'verse': 25},
    {'book': 'Romans', 'chapter': 10, 'verse': 9},
    {'book': 'Matthew', 'chapter': 19, 'verse': 26},
    {'book': 'Proverbs', 'chapter': 31, 'verse': 25},
    {'book': 'Isaiah', 'chapter': 55, 'verse': 8},
    {'book': 'Psalms', 'chapter': 51, 'verse': 10},
    {'book': 'John', 'chapter': 16, 'verse': 33},
    {'book': 'Colossians', 'chapter': 1, 'verse': 17},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 10},
    {'book': 'Proverbs', 'chapter': 18, 'verse': 10},
    {'book': 'Matthew', 'chapter': 5, 'verse': 9},
    {'book': 'Romans', 'chapter': 8, 'verse': 1},
    {'book': 'Psalms', 'chapter': 91, 'verse': 1},
    {'book': 'John', 'chapter': 4, 'verse': 24},
    {'book': 'Isaiah', 'chapter': 9, 'verse': 6},
    {'book': 'Hebrews', 'chapter': 4, 'verse': 16},
    {'book': 'James', 'chapter': 1, 'verse': 2},
    {'book': 'Psalms', 'chapter': 100, 'verse': 1},
    {'book': 'Matthew', 'chapter': 6, 'verse': 9},
    {'book': 'Philippians', 'chapter': 3, 'verse': 14},
    {'book': 'Romans', 'chapter': 8, 'verse': 38},
    {'book': 'Proverbs', 'chapter': 17, 'verse': 17},
    {'book': 'John', 'chapter': 17, 'verse': 17},
    {'book': 'Isaiah', 'chapter': 40, 'verse': 28},
    {'book': 'Psalms', 'chapter': 16, 'verse': 11},
    {'book': 'Matthew', 'chapter': 5, 'verse': 44},
    {'book': 'Colossians', 'chapter': 3, 'verse': 2},
    {'book': 'Ephesians', 'chapter': 3, 'verse': 20},
    {'book': 'Proverbs', 'chapter': 12, 'verse': 1},
    {'book': 'John', 'chapter': 20, 'verse': 29},
    {'book': 'Romans', 'chapter': 12, 'verse': 12},
    {'book': 'Psalms', 'chapter': 19, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 58, 'verse': 11},
    {'book': 'Hebrews', 'chapter': 12, 'verse': 1},
    {'book': 'Matthew', 'chapter': 5, 'verse': 3},
    {'book': 'Philippians', 'chapter': 4, 'verse': 19},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 9},
    {'book': 'John', 'chapter': 13, 'verse': 34},
    {'book': 'Romans', 'chapter': 1, 'verse': 16},
    {'book': 'Psalms', 'chapter': 32, 'verse': 8},
    {'book': 'Isaiah', 'chapter': 60, 'verse': 1},
    {'book': 'James', 'chapter': 5, 'verse': 16},
    {'book': 'Matthew', 'chapter': 5, 'verse': 8},
    {'book': 'Colossians', 'chapter': 4, 'verse': 6},
    {'book': 'Ephesians', 'chapter': 5, 'verse': 20},
    {'book': 'Proverbs', 'chapter': 8, 'verse': 17},
    {'book': 'John', 'chapter': 6, 'verse': 35},
    {'book': 'Romans', 'chapter': 13, 'verse': 10},
    {'book': 'Psalms', 'chapter': 73, 'verse': 26},
    {'book': 'Isaiah', 'chapter': 66, 'verse': 13},
    {'book': 'Hebrews', 'chapter': 10, 'verse': 25},
    {'book': 'Matthew', 'chapter': 18, 'verse': 20},
    {'book': 'Philippians', 'chapter': 1, 'verse': 6},
    {'book': 'Proverbs', 'chapter': 11, 'verse': 2},
    {'book': 'John', 'chapter': 21, 'verse': 17},
    {'book': 'Romans', 'chapter': 8, 'verse': 14},
    {'book': 'Psalms', 'chapter': 42, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 61, 'verse': 1},
    {'book': 'James', 'chapter': 2, 'verse': 17},
    {'book': 'Matthew', 'chapter': 5, 'verse': 6},
    {'book': 'Colossians', 'chapter': 2, 'verse': 6},
    {'book': 'Ephesians', 'chapter': 1, 'verse': 3},
    {'book': 'Proverbs', 'chapter': 15, 'verse': 1},
    {'book': 'John', 'chapter': 9, 'verse': 25},
    {'book': 'Romans', 'chapter': 14, 'verse': 17},
    {'book': 'Psalms', 'chapter': 62, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 40, 'verse': 1},
    {'book': 'Hebrews', 'chapter': 6, 'verse': 19},
    {'book': 'Matthew', 'chapter': 6, 'verse': 34},
    {'book': 'Philippians', 'chapter': 4, 'verse': 4},
    {'book': 'Proverbs', 'chapter': 27, 'verse': 1},
    {'book': 'John', 'chapter': 12, 'verse': 46},
    {'book': 'Romans', 'chapter': 8, 'verse': 31},
    {'book': 'Psalms', 'chapter': 84, 'verse': 10},
    {'book': 'Isaiah', 'chapter': 43, 'verse': 19},
    {'book': 'James', 'chapter': 3, 'verse': 17},
    {'book': 'Matthew', 'chapter': 11, 'verse': 29},
    {'book': 'Colossians', 'chapter': 3, 'verse': 17},
    {'book': 'Ephesians', 'chapter': 2, 'verse': 10},
    {'book': 'Proverbs', 'chapter': 20, 'verse': 7},
    {'book': 'John', 'chapter': 5, 'verse': 24},
    {'book': 'Romans', 'chapter': 8, 'verse': 26},
    {'book': 'Psalms', 'chapter': 103, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 44, 'verse': 22},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 6},
    {'book': 'Matthew', 'chapter': 17, 'verse': 20},
    {'book': 'Philippians', 'chapter': 4, 'verse': 11},
    {'book': 'Proverbs', 'chapter': 9, 'verse': 10},
    {'book': 'John', 'chapter': 3, 'verse': 36},
    {'book': 'Romans', 'chapter': 8, 'verse': 39},
    {'book': 'Psalms', 'chapter': 111, 'verse': 10},
    {'book': 'Isaiah', 'chapter': 45, 'verse': 22},
    {'book': 'James', 'chapter': 1, 'verse': 5},
    {'book': 'Matthew', 'chapter': 6, 'verse': 24},
    {'book': 'Colossians', 'chapter': 3, 'verse': 13},
    {'book': 'Ephesians', 'chapter': 4, 'verse': 2},
    {'book': 'Proverbs', 'chapter': 14, 'verse': 12},
    {'book': 'John', 'chapter': 7, 'verse': 38},
    {'book': 'Romans', 'chapter': 8, 'verse': 6},
    {'book': 'Psalms', 'chapter': 118, 'verse': 24},
    {'book': 'Isaiah', 'chapter': 48, 'verse': 17},
    {'book': 'Hebrews', 'chapter': 13, 'verse': 5},
    {'book': 'Matthew', 'chapter': 5, 'verse': 14},
    {'book': 'Philippians', 'chapter': 4, 'verse': 8},
    {'book': 'Proverbs', 'chapter': 6, 'verse': 23},
    {'book': 'John', 'chapter': 14, 'verse': 27},
    {'book': 'Romans', 'chapter': 12, 'verse': 1},
    {'book': 'Psalms', 'chapter': 145, 'verse': 18},
    {'book': 'Isaiah', 'chapter': 49, 'verse': 15},
    {'book': 'James', 'chapter': 1, 'verse': 22},
    {'book': 'Matthew', 'chapter': 5, 'verse': 7},
    {'book': 'Colossians', 'chapter': 3, 'verse': 12},
    {'book': 'Ephesians', 'chapter': 4, 'verse': 26},
    {'book': 'Proverbs', 'chapter': 2, 'verse': 6},
    {'book': 'John', 'chapter': 15, 'verse': 5},
    {'book': 'Romans', 'chapter': 8, 'verse': 17},
    {'book': 'Psalms', 'chapter': 150, 'verse': 6},
    {'book': 'Isaiah', 'chapter': 50, 'verse': 7},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 40},
    {'book': 'Matthew', 'chapter': 9, 'verse': 36},
    {'book': 'Philippians', 'chapter': 4, 'verse': 6},
    {'book': 'Proverbs', 'chapter': 10, 'verse': 22},
    {'book': 'John', 'chapter': 15, 'verse': 7},
    {'book': 'Romans', 'chapter': 8, 'verse': 18},
    {'book': 'Psalms', 'chapter': 2, 'verse': 12},
    {'book': 'Isaiah', 'chapter': 51, 'verse': 11},
    {'book': 'James', 'chapter': 4, 'verse': 7},
    {'book': 'Matthew', 'chapter': 6, 'verse': 6},
    {'book': 'Colossians', 'chapter': 3, 'verse': 16},
    {'book': 'Ephesians', 'chapter': 5, 'verse': 1},
    {'book': 'Proverbs', 'chapter': 13, 'verse': 20},
    {'book': 'John', 'chapter': 15, 'verse': 9},
    {'book': 'Romans', 'chapter': 8, 'verse': 19},
    {'book': 'Psalms', 'chapter': 4, 'verse': 8},
    {'book': 'Isaiah', 'chapter': 52, 'verse': 7},
    {'book': 'Hebrews', 'chapter': 2, 'verse': 18},
    {'book': 'Matthew', 'chapter': 10, 'verse': 30},
    {'book': 'Philippians', 'chapter': 4, 'verse': 9},
    {'book': 'Proverbs', 'chapter': 19, 'verse': 21},
    {'book': 'John', 'chapter': 15, 'verse': 11},
    {'book': 'Romans', 'chapter': 8, 'verse': 20},
    {'book': 'Psalms', 'chapter': 5, 'verse': 3},
    {'book': 'Isaiah', 'chapter': 54, 'verse': 10},
    {'book': 'James', 'chapter': 1, 'verse': 27},
    {'book': 'Matthew', 'chapter': 6, 'verse': 14},
    {'book': 'Colossians', 'chapter': 3, 'verse': 15},
    {'book': 'Ephesians', 'chapter': 5, 'verse': 15},
    {'book': 'Proverbs', 'chapter': 24, 'verse': 16},
    {'book': 'John', 'chapter': 15, 'verse': 15},
    {'book': 'Romans', 'chapter': 8, 'verse': 21},
    {'book': 'Psalms', 'chapter': 6, 'verse': 9},
    {'book': 'Isaiah', 'chapter': 56, 'verse': 7},
    {'book': 'Hebrews', 'chapter': 3, 'verse': 13},
    {'book': 'Matthew', 'chapter': 12, 'verse': 34},
    {'book': 'Philippians', 'chapter': 4, 'verse': 12},
    {'book': 'Proverbs', 'chapter': 25, 'verse': 11},
    {'book': 'John', 'chapter': 15, 'verse': 16},
    {'book': 'Romans', 'chapter': 8, 'verse': 22},
    {'book': 'Psalms', 'chapter': 7, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 57, 'verse': 15},
    {'book': 'James', 'chapter': 2, 'verse': 26},
    {'book': 'Matthew', 'chapter': 13, 'verse': 23},
    {'book': 'Colossians', 'chapter': 3, 'verse': 14},
    {'book': 'Ephesians', 'chapter': 5, 'verse': 25},
    {'book': 'Proverbs', 'chapter': 26, 'verse': 12},
    {'book': 'John', 'chapter': 15, 'verse': 17},
    {'book': 'Romans', 'chapter': 8, 'verse': 24},
    {'book': 'Psalms', 'chapter': 8, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 59, 'verse': 1},
    {'book': 'Hebrews', 'chapter': 5, 'verse': 8},
    {'book': 'Matthew', 'chapter': 14, 'verse': 27},
    {'book': 'Philippians', 'chapter': 4, 'verse': 14},
    {'book': 'Proverbs', 'chapter': 28, 'verse': 13},
    {'book': 'John', 'chapter': 15, 'verse': 18},
    {'book': 'Romans', 'chapter': 8, 'verse': 25},
    {'book': 'Psalms', 'chapter': 9, 'verse': 9},
    {'book': 'Isaiah', 'chapter': 62, 'verse': 5},
    {'book': 'James', 'chapter': 3, 'verse': 13},
    {'book': 'Matthew', 'chapter': 15, 'verse': 28},
    {'book': 'Colossians', 'chapter': 3, 'verse': 11},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 18},
    {'book': 'Proverbs', 'chapter': 29, 'verse': 25},
    {'book': 'John', 'chapter': 15, 'verse': 19},
    {'book': 'Romans', 'chapter': 8, 'verse': 27},
    {'book': 'Psalms', 'chapter': 10, 'verse': 14},
    {'book': 'Isaiah', 'chapter': 63, 'verse': 9},
    {'book': 'Hebrews', 'chapter': 7, 'verse': 25},
    {'book': 'Matthew', 'chapter': 16, 'verse': 18},
    {'book': 'Philippians', 'chapter': 4, 'verse': 15},
    {'book': 'Proverbs', 'chapter': 30, 'verse': 5},
    {'book': 'John', 'chapter': 15, 'verse': 20},
    {'book': 'Romans', 'chapter': 8, 'verse': 29},
    {'book': 'Psalms', 'chapter': 11, 'verse': 7},
    {'book': 'Isaiah', 'chapter': 64, 'verse': 8},
    {'book': 'James', 'chapter': 4, 'verse': 14},
    {'book': 'Matthew', 'chapter': 5, 'verse': 11},
    {'book': 'Colossians', 'chapter': 3, 'verse': 10},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 17},
    {'book': 'Proverbs', 'chapter': 31, 'verse': 30},
    {'book': 'John', 'chapter': 16, 'verse': 7},
    {'book': 'Romans', 'chapter': 8, 'verse': 28},
    {'book': 'Psalms', 'chapter': 12, 'verse': 6},
    {'book': 'Isaiah', 'chapter': 65, 'verse': 24},
    {'book': 'Hebrews', 'chapter': 9, 'verse': 14},
    {'book': 'Matthew', 'chapter': 5, 'verse': 5},
    {'book': 'Philippians', 'chapter': 4, 'verse': 16},
    {'book': 'Proverbs', 'chapter': 1, 'verse': 7},
    {'book': 'John', 'chapter': 16, 'verse': 13},
    {'book': 'Romans', 'chapter': 8, 'verse': 32},
    {'book': 'Psalms', 'chapter': 13, 'verse': 6},
    {'book': 'Isaiah', 'chapter': 7, 'verse': 14},
    {'book': 'James', 'chapter': 5, 'verse': 7},
    {'book': 'Matthew', 'chapter': 5, 'verse': 4},
    {'book': 'Colossians', 'chapter': 3, 'verse': 9},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 16},
    {'book': 'Proverbs', 'chapter': 7, 'verse': 1},
    {'book': 'John', 'chapter': 16, 'verse': 22},
    {'book': 'Romans', 'chapter': 8, 'verse': 33},
    {'book': 'Psalms', 'chapter': 14, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 11, 'verse': 2},
    {'book': 'Hebrews', 'chapter': 8, 'verse': 10},
    {'book': 'Matthew', 'chapter': 5, 'verse': 2},
    {'book': 'Philippians', 'chapter': 4, 'verse': 17},
    {'book': 'Proverbs', 'chapter': 5, 'verse': 18},
    {'book': 'John', 'chapter': 16, 'verse': 24},
    {'book': 'Romans', 'chapter': 8, 'verse': 34},
    {'book': 'Psalms', 'chapter': 15, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 12, 'verse': 2},
    {'book': 'James', 'chapter': 5, 'verse': 11},
    {'book': 'Matthew', 'chapter': 5, 'verse': 1},
    {'book': 'Colossians', 'chapter': 3, 'verse': 8},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 15},
    {'book': 'Proverbs', 'chapter': 21, 'verse': 21},
    {'book': 'John', 'chapter': 16, 'verse': 27},
    {'book': 'Romans', 'chapter': 8, 'verse': 35},
    {'book': 'Psalms', 'chapter': 17, 'verse': 15},
    {'book': 'Isaiah', 'chapter': 13, 'verse': 12},
    {'book': 'Hebrews', 'chapter': 1, 'verse': 3},
    {'book': 'Matthew', 'chapter': 4, 'verse': 19},
    {'book': 'Philippians', 'chapter': 4, 'verse': 18},
    {'book': 'Proverbs', 'chapter': 23, 'verse': 7},
    {'book': 'John', 'chapter': 16, 'verse': 28},
    {'book': 'Romans', 'chapter': 8, 'verse': 36},
    {'book': 'Psalms', 'chapter': 18, 'verse': 2},
    {'book': 'Isaiah', 'chapter': 14, 'verse': 27},
    {'book': 'James', 'chapter': 5, 'verse': 13},
    {'book': 'Matthew', 'chapter': 4, 'verse': 17},
    {'book': 'Colossians', 'chapter': 3, 'verse': 7},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 14},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 6},
    {'book': 'John', 'chapter': 16, 'verse': 30},
    {'book': 'Romans', 'chapter': 8, 'verse': 37},
    {'book': 'Psalms', 'chapter': 20, 'verse': 7},
    {'book': 'Isaiah', 'chapter': 15, 'verse': 9},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 7},
    {'book': 'Matthew', 'chapter': 4, 'verse': 10},
    {'book': 'Philippians', 'chapter': 2, 'verse': 10},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 7},
    {'book': 'John', 'chapter': 17, 'verse': 3},
    {'book': 'Romans', 'chapter': 8, 'verse': 38},
    {'book': 'Psalms', 'chapter': 21, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 16, 'verse': 5},
    {'book': 'James', 'chapter': 5, 'verse': 14},
    {'book': 'Matthew', 'chapter': 4, 'verse': 4},
    {'book': 'Colossians', 'chapter': 3, 'verse': 6},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 13},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 8},
    {'book': 'John', 'chapter': 17, 'verse': 4},
    {'book': 'Romans', 'chapter': 12, 'verse': 3},
    {'book': 'Psalms', 'chapter': 22, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 17, 'verse': 7},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 8},
    {'book': 'Matthew', 'chapter': 3, 'verse': 17},
    {'book': 'Philippians', 'chapter': 2, 'verse': 11},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 10},
    {'book': 'John', 'chapter': 17, 'verse': 6},
    {'book': 'Romans', 'chapter': 12, 'verse': 4},
    {'book': 'Psalms', 'chapter': 24, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 18, 'verse': 7},
    {'book': 'James', 'chapter': 5, 'verse': 15},
    {'book': 'Matthew', 'chapter': 3, 'verse': 11},
    {'book': 'Colossians', 'chapter': 3, 'verse': 5},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 12},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 11},
    {'book': 'John', 'chapter': 17, 'verse': 9},
    {'book': 'Romans', 'chapter': 12, 'verse': 5},
    {'book': 'Psalms', 'chapter': 25, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 19, 'verse': 20},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 9},
    {'book': 'Matthew', 'chapter': 3, 'verse': 8},
    {'book': 'Philippians', 'chapter': 2, 'verse': 12},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 12},
    {'book': 'John', 'chapter': 17, 'verse': 11},
    {'book': 'Romans', 'chapter': 12, 'verse': 6},
    {'book': 'Psalms', 'chapter': 26, 'verse': 1},
    {'book': 'Isaiah', 'chapter': 20, 'verse': 6},
    {'book': 'James', 'chapter': 5, 'verse': 17},
    {'book': 'Matthew', 'chapter': 2, 'verse': 11},
    {'book': 'Colossians', 'chapter': 3, 'verse': 4},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 11},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 13},
    {'book': 'John', 'chapter': 17, 'verse': 13},
    {'book': 'Romans', 'chapter': 12, 'verse': 7},
    {'book': 'Psalms', 'chapter': 28, 'verse': 7},
    {'book': 'Isaiah', 'chapter': 21, 'verse': 11},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 10},
    {'book': 'Matthew', 'chapter': 1, 'verse': 23},
    {'book': 'Philippians', 'chapter': 2, 'verse': 13},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 14},
    {'book': 'John', 'chapter': 17, 'verse': 15},
    {'book': 'Romans', 'chapter': 12, 'verse': 8},
    {'book': 'Psalms', 'chapter': 29, 'verse': 11},
    {'book': 'Isaiah', 'chapter': 22, 'verse': 22},
    {'book': 'James', 'chapter': 5, 'verse': 19},
    {'book': 'Matthew', 'chapter': 1, 'verse': 21},
    {'book': 'Colossians', 'chapter': 3, 'verse': 3},
    {'book': 'Ephesians', 'chapter': 6, 'verse': 8},
    {'book': 'Proverbs', 'chapter': 3, 'verse': 15},
    {'book': 'John', 'chapter': 17, 'verse': 19},
    {'book': 'Romans', 'chapter': 12, 'verse': 9},
    {'book': 'Psalms', 'chapter': 30, 'verse': 5},
    {'book': 'Isaiah', 'chapter': 23, 'verse': 9},
    {'book': 'Hebrews', 'chapter': 11, 'verse': 11},
    {'book': 'Matthew', 'chapter': 1, 'verse': 19},
    {'book': 'Philippians', 'chapter': 2, 'verse': 14},
  ];

  /// Vrátí referenci pro dnešní den (deterministicky podle data)
  static Map<String, dynamic> getTodayVerseRef() {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final index = dayOfYear % _dailyVerseRefs.length;
    return _dailyVerseRefs[index];
  }

  /// Načte dnešní verš z aktivního překladu
  Future<Verse?> getDailyVerseFromTranslation(String translationId) async {
    final ref = getTodayVerseRef();
    final book = ref['book'] as String;
    final chapter = ref['chapter'] as int;
    final verseNum = ref['verse'] as int;

    final bookData = books.firstWhere(
      (b) => b['name'] == book,
      orElse: () => {'cs': book, 'name': book},
    );
    final bookCs = bookData['cs'] as String;

    try {
      // Pro ČSP — načti verš přímo podle čísla (verše mohou být nespojité)
      if (translationId == 'csp') {
        final text = await BibleDatabaseService.instance.getVerse(
            'csp', book, chapter, verseNum);
        if (text != null && text.isNotEmpty) {
          return Verse(
            reference: '$bookCs $chapter:$verseNum',
            text: text,
            book: book,
            chapter: chapter,
            verseNumber: verseNum,
          );
        }
        // Zkus sousední verše pokud přesný verš neexistuje
        for (final v in [verseNum - 1, verseNum + 1, verseNum - 2, verseNum + 2]) {
          if (v < 1) continue;
          final t = await BibleDatabaseService.instance.getVerse('csp', book, chapter, v);
          if (t != null && t.isNotEmpty) {
            return Verse(
              reference: '$bookCs $chapter:$v',
              text: t,
              book: book,
              chapter: chapter,
              verseNumber: v,
            );
          }
        }
        return null;
      }
      final chapterData = await fetchChapter(book, chapter, translationId);
      if (chapterData != null && chapterData.verses.length >= verseNum) {
        final text = chapterData.verses[verseNum - 1];
        return Verse(
          reference: '$bookCs $chapter:$verseNum',
          text: text,
          book: book,
          chapter: chapter,
          verseNumber: verseNum,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Záložní verš dne ze zabudovaných textů (fallback při offline)
  Verse getDailyVerseLocal({bool czech = false}) {
    final ref = BibleService.getTodayVerseRef();
    final book = ref['book'] as String;
    final chapter = ref['chapter'] as int;
    final verseNum = ref['verse'] as int;
    final bookData = books.firstWhere(
      (b) => b['name'] == book,
      orElse: () => {'cs': book, 'name': book},
    );
    final bookCs = bookData['cs'] as String;
    // Záložní text — zobrazí se jen pokud není dostupný překlad
    return Verse(
      reference: '$bookCs $chapter:$verseNum',
      text: czech
          ? 'Neboť tak Bůh miloval svět, že dal svého jednorozeného Syna, aby žádný, kdo v něho věří, nezahynul, ale měl život věčný.'
          : 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
      book: book,
      chapter: chapter,
      verseNumber: verseNum,
    );
  }

  Future<BibleChapter?> fetchChapter(String book, int chapter, String translation) async {
    // ČSP — čti z lokální SQLite databáze
    if (translation == 'csp') {
      try {
        final verses = await BibleDatabaseService.instance.getChapter('csp', book, chapter);
        print('CSP: ' + book + ' ch:' + chapter.toString() + ' verses:' + verses.length.toString());
        if (verses.isNotEmpty) {
          return BibleChapter(book: book, chapter: chapter, verses: verses, translation: 'csp');
        }
      } catch (e) {
        print('CSP error: \$e');
        return null;
      }
      return null;
    }

    try {
      String url;
      bool isCzech = translation == 'bkr' || translation == 'cep';

      if (isCzech) {
        final bookIndex = books.indexWhere((b) => b['name'] == book) + 1;
        url = '$_getbibleUrl/$translation/$bookIndex/$chapter.json';
      } else {
        final apiTranslation = _mapTranslation(translation);
        final bookEncoded = Uri.encodeComponent(book);
        url = '$_baseUrl/$bookEncoded+$chapter?translation=$apiTranslation';
      }

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> verses;

        if (isCzech) {
          final versesList = data['verses'] as List;
          verses = versesList.map((v) => v['text'].toString().trim()).toList();
        } else {
          verses = (data['verses'] as List)
              .map((v) => v['text'].toString().trim())
              .toList();
        }

        return BibleChapter(
          book: book,
          chapter: chapter,
          verses: verses,
          translation: translation,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _mapTranslation(String translation) {
    switch (translation) {
      case 'kjv': return 'kjv';
      case 'web': return 'web';
      case 'niv': return 'web';
      default: return 'kjv';
    }
  }

  static const List<Map<String, dynamic>> books = [
    {'name': 'Genesis', 'cs': 'Genesis', 'chapters': 50},
    {'name': 'Exodus', 'cs': 'Exodus', 'chapters': 40},
    {'name': 'Leviticus', 'cs': 'Leviticus', 'chapters': 27},
    {'name': 'Numbers', 'cs': 'Numeri', 'chapters': 36},
    {'name': 'Deuteronomy', 'cs': 'Deuteronomium', 'chapters': 34},
    {'name': 'Joshua', 'cs': 'Jozue', 'chapters': 24},
    {'name': 'Judges', 'cs': 'Soudců', 'chapters': 21},
    {'name': 'Ruth', 'cs': 'Rút', 'chapters': 4},
    {'name': '1 Samuel', 'cs': '1. Samuelova', 'chapters': 31},
    {'name': '2 Samuel', 'cs': '2. Samuelova', 'chapters': 24},
    {'name': '1 Kings', 'cs': '1. Královská', 'chapters': 22},
    {'name': '2 Kings', 'cs': '2. Královská', 'chapters': 25},
    {'name': '1 Chronicles', 'cs': '1. Paralipomenon', 'chapters': 29},
    {'name': '2 Chronicles', 'cs': '2. Paralipomenon', 'chapters': 36},
    {'name': 'Ezra', 'cs': 'Ezdráš', 'chapters': 10},
    {'name': 'Nehemiah', 'cs': 'Nehemiáš', 'chapters': 13},
    {'name': 'Esther', 'cs': 'Ester', 'chapters': 10},
    {'name': 'Job', 'cs': 'Job', 'chapters': 42},
    {'name': 'Psalms', 'cs': 'Žalmy', 'chapters': 150},
    {'name': 'Proverbs', 'cs': 'Přísloví', 'chapters': 31},
    {'name': 'Ecclesiastes', 'cs': 'Kazatel', 'chapters': 12},
    {'name': 'Song of Solomon', 'cs': 'Píseň písní', 'chapters': 8},
    {'name': 'Isaiah', 'cs': 'Izajáš', 'chapters': 66},
    {'name': 'Jeremiah', 'cs': 'Jeremjáš', 'chapters': 52},
    {'name': 'Lamentations', 'cs': 'Pláč Jeremjášův', 'chapters': 5},
    {'name': 'Ezekiel', 'cs': 'Ezechiel', 'chapters': 48},
    {'name': 'Daniel', 'cs': 'Daniel', 'chapters': 12},
    {'name': 'Hosea', 'cs': 'Ozeáš', 'chapters': 14},
    {'name': 'Joel', 'cs': 'Joel', 'chapters': 3},
    {'name': 'Amos', 'cs': 'Ámos', 'chapters': 9},
    {'name': 'Obadiah', 'cs': 'Abdiáš', 'chapters': 1},
    {'name': 'Jonah', 'cs': 'Jonáš', 'chapters': 4},
    {'name': 'Micah', 'cs': 'Micheáš', 'chapters': 7},
    {'name': 'Nahum', 'cs': 'Nahum', 'chapters': 3},
    {'name': 'Habakkuk', 'cs': 'Abakuk', 'chapters': 3},
    {'name': 'Zephaniah', 'cs': 'Sofoniáš', 'chapters': 3},
    {'name': 'Haggai', 'cs': 'Aggeus', 'chapters': 2},
    {'name': 'Zechariah', 'cs': 'Zachariáš', 'chapters': 14},
    {'name': 'Malachi', 'cs': 'Malachiáš', 'chapters': 4},
    {'name': 'Matthew', 'cs': 'Matouš', 'chapters': 28},
    {'name': 'Mark', 'cs': 'Marek', 'chapters': 16},
    {'name': 'Luke', 'cs': 'Lukáš', 'chapters': 24},
    {'name': 'John', 'cs': 'Jan', 'chapters': 21},
    {'name': 'Acts', 'cs': 'Skutky', 'chapters': 28},
    {'name': 'Romans', 'cs': 'Římanům', 'chapters': 16},
    {'name': '1 Corinthians', 'cs': '1. Korintským', 'chapters': 16},
    {'name': '2 Corinthians', 'cs': '2. Korintským', 'chapters': 13},
    {'name': 'Galatians', 'cs': 'Galatským', 'chapters': 6},
    {'name': 'Ephesians', 'cs': 'Efezským', 'chapters': 6},
    {'name': 'Philippians', 'cs': 'Filipským', 'chapters': 4},
    {'name': 'Colossians', 'cs': 'Koloským', 'chapters': 4},
    {'name': '1 Thessalonians', 'cs': '1. Tesalonickým', 'chapters': 5},
    {'name': '2 Thessalonians', 'cs': '2. Tesalonickým', 'chapters': 3},
    {'name': '1 Timothy', 'cs': '1. Timoteovi', 'chapters': 6},
    {'name': '2 Timothy', 'cs': '2. Timoteovi', 'chapters': 4},
    {'name': 'Titus', 'cs': 'Titovi', 'chapters': 3},
    {'name': 'Philemon', 'cs': 'Filemonovi', 'chapters': 1},
    {'name': 'Hebrews', 'cs': 'Hebrejům', 'chapters': 13},
    {'name': 'James', 'cs': 'Jakub', 'chapters': 5},
    {'name': '1 Peter', 'cs': '1. Petra', 'chapters': 5},
    {'name': '2 Peter', 'cs': '2. Petra', 'chapters': 3},
    {'name': '1 John', 'cs': '1. Jan', 'chapters': 5},
    {'name': '2 John', 'cs': '2. Jan', 'chapters': 1},
    {'name': '3 John', 'cs': '3. Jan', 'chapters': 1},
    {'name': 'Jude', 'cs': 'Juda', 'chapters': 1},
    {'name': 'Revelation', 'cs': 'Zjevení', 'chapters': 22},
  ];
}
