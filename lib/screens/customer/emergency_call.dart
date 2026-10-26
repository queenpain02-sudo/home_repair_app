import 'package:url_launcher/url_launcher.dart';

// 📞 အရေးပေါ် ဖုန်းခေါ်ဆိုသည့် Function
Future<void> _makeEmergencyCall() async {
  // အရေးပေါ် Hotline နံပါတ် (သို့မဟုတ် Admin ရဲ့ ဖုန်းနံပါတ်)
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: '09974514299', // လိုချင်သော အရေးပေါ် ဖုန်းနံပါတ်ကို ထည့်ပါ
  );
  
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    throw 'ဖုန်းခေါ်ဆို၍ မရပါ။';
  }
}