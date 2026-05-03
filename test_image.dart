import 'package:image/image.dart' as img;
import 'dart:io';

void main() {
  final image = img.Image(width: 10, height: 10);
  
  // Default values check
  print('Trying adjustColor...');
  try {
    img.adjustColor(image, brightness: 1.5, contrast: 1.5);
    print('adjustColor works with these args');
  } catch (e) {
    print(e);
  }

  print('Trying grayscale...');
  try {
    img.grayscale(image);
    print('grayscale works');
  } catch(e) {
    print(e);
  }
}
