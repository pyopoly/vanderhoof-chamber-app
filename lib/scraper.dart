// scraper.dart: Scraper function was used to obtain information from the Chamber
// of Commerce business directory page. This page is no longer necessary as all
// the information has been finalized.

// import 'package:flutter/material.dart';
// import 'package:web_scraper/web_scraper.dart';
//
// import 'commonFunction.dart';
//
// Future<void> scrap(bool activate) async {
//   if (!activate) {
//     print("----------scraping deactivated");
//   } else {
//     print("----------------scrap------------");
//     //==================================
//     // Assistance Methods
//     //==================================
//
//     String _check(List element) {
//       if (element.isNotEmpty) {
//         return element[0];
//       } else {
//         return null;
//       }
//     }
//
//     String _checkElement(List element, String tag) {
//       if (element.isNotEmpty) {
//         return element[0]['attributes'][tag];
//       } else {
//         return null;
//       }
//     }
//
//     String _checkPhone(List element) {
//       if (element.isNotEmpty) {
//         String s = element[0].replaceAll(RegExp(r'[^0-9]'), '');
//         // int length = 10;
//         int firstIndex = 0;
//         if (s[0] == '1') {
//           // length = length + 1;
//           firstIndex = 1;
//         }
//         s = s.substring(firstIndex, 10);
//         return s;
//       } else {
//         return null;
//       }
//     }
//     //==================================
//     // End of Assistance Methods
//     //==================================
//
//     final webScraper = WebScraper('https://www.vanderhoofchamber.com/');
//     // List listOfBusinesses = [];
//     int count = 1;
//     if (await webScraper.loadWebPage('/membership/business-directory')) {
//       var elements =
//           webScraper.getElementAttribute('#businesslist > div >h3>a', 'href');
//       // Future<void> fun(var element) async {
//       elements.forEach((element) async {
//         String page = element.substring(33);
//         if (await webScraper.loadWebPage(page)) {
//           var name = webScraper.getElementTitle('h1.entry-title');
//           var phone = webScraper.getElementTitle('p.phone');
//           var desc = webScraper.getElementTitle('#business > p');
//           var address = webScraper.getElementTitle('p.address');
//           var email = webScraper.getElementTitle('p.email > a');
//           var web = webScraper.getElement('p.website>a', ['href']);
//           var img = webScraper.getElement('div.entry-content >img', ['src']);
//           var category = webScraper.getElementTitle('p.categories > a');
//           var facebook = webScraper
//               .getElement('div.cdash-social-media > ul > li > a', ['href']);
//
//           String n = _check(name);
//           String p = _checkPhone(phone);
//           String d = _check(desc);
//           String a = _check(address);
//           String e = _check(email);
//           String w = _checkElement(web, 'href');
//           String i = _checkElement(img, 'src');
//           String f = _checkElement(facebook, 'href');
//
//           // Format address
//           if (a != null) {
//             if (!a.startsWith("Vanderhoof"))
//               a = a.replaceFirst("Vanderhoof", ', Vanderhoof');
//             if (!a.startsWith("Prince George"))
//               a = a.replaceFirst("Prince George", ', Prince George');
//           }
//
//           // Below changes the imgSrc url of cropped imgs to the uncropped by,
//           // by finding the first "-" starting from the end, and cutting
//           // everything out after the "-".
//           if (i != null) {
//             for (int j = i.length - 1; j > 50; j--) {
//               if (i[j] == '-') {
//                 i = i.substring(0, j) + i.substring(i.length - 4, i.length);
//                 break;
//               }
//             }
//           }
//
//           toLatLng(a).then((geopoint) {
//             addBusiness({
//               'name': n,
//               'address': a,
//               'phone': p,
//               'email': e,
//               'website': w,
//               'description': d,
//               'imgURL': i,
//               'category': category,
//               'LatLng': geopoint,
//               'socialMedia': {
//                 'facebook': ".",
//                 'instagram': ".",
//                 'twitter': "."
//               },
//             });
//             print("$n: count: $count");
//             count++;
//           }).catchError(
//               (error) => print("Failed to get GeoPoint: $error for $a"));
//
//           // print("adding to temporary list: $n");
//         }
//         // }
//       });
//       // Future.wait(elements.map(fun)).then((x) async {
//       //   listOfBusinesses.sort((a, b) {
//       //     return a['name'].compareTo(b['name']);
//       //   });
//       //   listOfBusinesses.forEach((business) => {addBusiness(business)});
//       // });
//     }
//   }
// }
